#!/bin/bash
# Rippling MDM / macOS: install a shared Python environment for all local users.
set -euo pipefail
umask 022

PYTHON_VERSION="3.14.10"
PYTHON_MINOR="3.14"
PYTHON_BIN="/Library/Frameworks/Python.framework/Versions/${PYTHON_MINOR}/bin/python${PYTHON_MINOR}"
ENV_DIR="/Library/Application Support/ManagedPython/venv"
PYTHON_CMD="/usr/local/bin/python-data"
PIP_CMD="/usr/local/bin/pip-data"
BREW_INSTALL_USER="" # Optional: existing local account to own new Homebrew (Apple Silicon)

log() { echo "[ManagedPython] $*"; }
fail() { echo "[ManagedPython] ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || fail "Run as root (Rippling's system context)."
[[ "$(uname -s)" == "Darwin" ]] || fail "macOS only."

WORKDIR="$(/usr/bin/mktemp -d /private/tmp/managedpython.XXXXXX)"
cleanup() {
  /bin/rm -rf "$WORKDIR"
  if [[ "${CREATED_BREW_OVERRIDE:-0}" == "1" ]]; then
    /bin/rm -f /var/tmp/.homebrew_pkg_user.plist
  fi
}
trap cleanup EXIT

# 1. Official python.org universal2 installer (Apple Silicon + Intel).
INSTALLED=""
if [[ -x "$PYTHON_BIN" ]]; then
  INSTALLED="$("$PYTHON_BIN" -c 'import platform; print(platform.python_version())')"
fi
if [[ "$INSTALLED" != "$PYTHON_VERSION" ]]; then
  PYTHON_PKG="$WORKDIR/python.pkg"
  log "Downloading Python $PYTHON_VERSION ..."
  /usr/bin/curl -fLsS --retry 3 \
    "https://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}-macos11.pkg" \
    -o "$PYTHON_PKG"
  /usr/sbin/installer -pkg "$PYTHON_PKG" -target /
fi
[[ -x "$PYTHON_BIN" ]] || fail "Python installation did not produce $PYTHON_BIN"
log "Python: $("$PYTHON_BIN" --version)"

# 2. OpenSSL 3 is required for mssql-python's encrypted SQL connections.
#    On Apple Silicon, bootstrap Homebrew if missing using its official pkg.
#    On Intel, use an existing Homebrew installation.
ARCH="$(/usr/bin/uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  BREW="/opt/homebrew/bin/brew"
elif [[ "$ARCH" == "x86_64" ]]; then
  BREW="/usr/local/bin/brew"
else
  fail "Unsupported CPU architecture: $ARCH"
fi

if [[ ! -x "$BREW" ]]; then
  [[ "$ARCH" == "arm64" ]] || fail "On Intel, install Homebrew first, then rerun this script."

  OWNER="$BREW_INSTALL_USER"
  if [[ -z "$OWNER" ]]; then
    OWNER="$(/usr/bin/stat -f '%Su' /dev/console)"
  fi
  [[ -n "$OWNER" && "$OWNER" != "root" && "$OWNER" != "loginwindow" ]] || \
    fail "No usable console user. Set BREW_INSTALL_USER to an existing local account."
  /usr/bin/id "$OWNER" >/dev/null 2>&1 || fail "Homebrew owner '$OWNER' does not exist."

  log "Installing Homebrew for account: $OWNER"
  /usr/bin/curl -fLsS --retry 3 \
    https://api.github.com/repos/Homebrew/brew/releases/latest \
    -o "$WORKDIR/homebrew.json"
  BREW_URL="$("$PYTHON_BIN" - "$WORKDIR/homebrew.json" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    release = json.load(f)
for asset in release.get('assets', []):
    if asset.get('name', '').lower().endswith('.pkg'):
        print(asset['browser_download_url'])
        break
else:
    sys.exit('No Homebrew .pkg in latest official release')
PY
)"
  /usr/bin/curl -fLsS --retry 3 "$BREW_URL" -o "$WORKDIR/homebrew.pkg"

  # Homebrew package accepts an existing standard user, even at login window.
  /usr/bin/defaults write /var/tmp/.homebrew_pkg_user HOMEBREW_PKG_USER "$OWNER"
  CREATED_BREW_OVERRIDE=1
  /usr/sbin/chown root:wheel /var/tmp/.homebrew_pkg_user.plist
  /bin/chmod 600 /var/tmp/.homebrew_pkg_user.plist
  /bin/chmod -N /var/tmp/.homebrew_pkg_user.plist
  /usr/sbin/installer -pkg "$WORKDIR/homebrew.pkg" -target /
fi
[[ -x "$BREW" ]] || fail "Homebrew not found at $BREW"

BREW_PREFIX="${BREW%/bin/brew}"
BREW_OWNER="$(/usr/bin/stat -f '%Su' "$BREW_PREFIX")"
[[ "$BREW_OWNER" != "root" ]] || fail "Homebrew prefix is root-owned; repair Homebrew before continuing."
log "Installing openssl@3 as Homebrew owner: $BREW_OWNER"
(cd / && /usr/bin/sudo -H -u "$BREW_OWNER" "$BREW" install openssl@3)
OPENSSL_LIB="$BREW_PREFIX/opt/openssl@3/lib"
[[ -f "$OPENSSL_LIB/libssl.3.dylib" ]] || fail "OpenSSL 3 shared library not found at $OPENSSL_LIB"

# 3. Install all requested modules in one root-managed, read-only-to-users venv.
log "Installing Python modules for all users ..."
/bin/mkdir -p "${ENV_DIR%/venv}" /usr/local/bin
if [[ ! -x "$ENV_DIR/bin/python3" ]]; then
  "$PYTHON_BIN" -m venv "$ENV_DIR"
fi
"$ENV_DIR/bin/python3" -m pip install --upgrade pip setuptools wheel
"$ENV_DIR/bin/python3" -m pip install --upgrade --only-binary=:all: \
  mssql-python pandas openpyxl azure-identity

# 4. Public launchers: keep OpenSSL 3 available for SQL Server TLS.
cat > "$PYTHON_CMD" <<EOF
#!/bin/bash
export DYLD_LIBRARY_PATH="${OPENSSL_LIB}\${DYLD_LIBRARY_PATH:+:\$DYLD_LIBRARY_PATH}"
exec "${ENV_DIR}/bin/python3" "\$@"
EOF
cat > "$PIP_CMD" <<EOF
#!/bin/bash
export DYLD_LIBRARY_PATH="${OPENSSL_LIB}\${DYLD_LIBRARY_PATH:+:\$DYLD_LIBRARY_PATH}"
exec "${ENV_DIR}/bin/python3" -m pip "\$@"
EOF
/bin/chmod 755 "$PYTHON_CMD" "$PIP_CMD"

# 5. Verify interpreter and imports (does not test a real SQL connection).
"$ENV_DIR/bin/python3" - <<'PY'
import sys
import mssql_python, pandas, openpyxl, azure.identity
print('Python:', sys.version.split()[0])
print('mssql-python:', mssql_python.__version__)
print('pandas:', pandas.__version__)
print('openpyxl:', openpyxl.__version__)
print('azure-identity: OK')
PY
log "Complete. All users can run: $PYTHON_CMD"
