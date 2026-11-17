# ============================================
# WSL Installer and Docker Installer 
# Downloads and silently installs WSL
# ============================================

$InstallFolder = "C:\wsl"
$InstallerPath = "$InstallFolder\wsl.msi"
$DownloadUrl   = "https://github.com/microsoft/WSL/releases/download/3.0.1/wsl.3.0.1.0.x64.msi"

# Create the WSL installation folder
New-Item -Path $InstallFolder -ItemType Directory -Force | Out-Null

# Download the WSL installer
Write-Host "Downloading WSL installer..."
Invoke-WebRequest `
    -Uri $DownloadUrl `
    -OutFile $InstallerPath

# Install WSL silently
Write-Host "Installing WSL..."
Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i `"$InstallerPath`" /qn /norestart" `
    -Wait `
    -NoNewWindow

Write-Host "WSL installation completed."

# Determine correct path to WSL.exe
$WslPath = "$env:WINDIR\System32\wsl.exe"

# If running under 32-bit PowerShell on 64-bit Windows,
# use Sysnative to bypass filesystem redirection.
if (Test-Path "$env:WINDIR\Sysnative\wsl.exe") {
    $WslPath = "$env:WINDIR\Sysnative\wsl.exe"
}

if (-not (Test-Path $WslPath)) {
    Write-Error "WSL.exe could not be found."
    exit 1
}

Write-Output "Using WSL executable: $WslPath"
Write-Output "Starting WSL update..."

$Process = Start-Process `
    -FilePath $WslPath `
    -ArgumentList "--update" `
    -Wait `
    -PassThru `
    -NoNewWindow

if ($Process.ExitCode -eq 0) {
    Write-Output "WSL update completed successfully."
    exit 0
}
else {
    Write-Error "WSL update failed with exit code $($Process.ExitCode)."
    exit $Process.ExitCode
}


# ============================================================
# Docker Desktop - Machine-Wide Installation
# ============================================================

# Must be run as Administrator / SYSTEM

$InstallFolder = "C:\dockerinstall"
$InstallerPath = "$InstallFolder\Docker Desktop Installer.exe"
$DownloadURL = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-win-amd64&_gl=1*tnotu7*_gcl_au*MTA1NTc4NzQ4MC4xNzkwNzA3MzUz*_ga*MTM1NjIyODcyNS4xNzkwNzA3MzUz*_ga_XJWPQMJYHQ*czE3OTA3MDczNTIkbzEkZzEkdDE3OTA3MDc0NTYkajU1JGwwJGgw"

Write-Host "Starting Docker Desktop installation..." -ForegroundColor Cyan

# ------------------------------------------------------------
# Check for Administrator privileges
# ------------------------------------------------------------

$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $CurrentPrincipal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Write-Host "ERROR: This script must be run as Administrator or SYSTEM." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# Create installation folder
# ------------------------------------------------------------

if (-not (Test-Path $InstallFolder)) {

    Write-Host "Creating folder: $InstallFolder"

    New-Item `
        -Path $InstallFolder `
        -ItemType Directory `
        -Force | Out-Null
}
else {
    Write-Host "$InstallFolder already exists."
}

# ------------------------------------------------------------
# Download Docker Desktop
# ------------------------------------------------------------

Write-Host "Downloading Docker Desktop..."

try {

    Invoke-WebRequest `
        -Uri $DownloadURL `
        -OutFile $InstallerPath `
        -UseBasicParsing `
        -ErrorAction Stop

}
catch {

    Write-Host "ERROR: Docker Desktop download failed." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

# Verify installer downloaded
if (-not (Test-Path $InstallerPath)) {

    Write-Host "ERROR: Docker Desktop installer was not downloaded." -ForegroundColor Red
    exit 1
}

Write-Host "Docker Desktop downloaded successfully." -ForegroundColor Green

# ------------------------------------------------------------
# Install Docker Desktop machine-wide
# ------------------------------------------------------------

Write-Host "Installing Docker Desktop machine-wide..."

$Process = Start-Process `
    -FilePath $InstallerPath `
    -ArgumentList "install", "--quiet", "--backend=wsl-2", "--always-run-service" `
    -Wait `
    -PassThru
	
	
	
	


<#
.SYNOPSIS
    Removes locally cached Outlook web add-ins for all Windows user profiles.

.DESCRIPTION
    Intended to be run AFTER the Outreach Outlook add-in has been removed
    centrally from Microsoft 365.

    This script:
      - Stops classic Outlook
      - Enumerates all real user profiles
      - Clears the Office WEF web add-in cache
      - Clears Outlook HubAppFileCache
      - Clears the legacy Win32WebViewHost Office cache if present
      - Writes a log to C:\ProgramData\OutreachCleanup

    Assigned Microsoft 365 add-ins will rebuild their cache the next time
    Outlook launches. Since Outreach has been removed server-side, it should
    not be downloaded again.
#>

$LogDirectory = "C:\ProgramData\OutreachCleanup"
$LogFile = Join-Path $LogDirectory "Outreach-Outlook-Cleanup.log"

# Create log directory
if (-not (Test-Path $LogDirectory)) {
    New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "[$TimeStamp] $Message"

    Write-Output $Entry
    Add-Content -Path $LogFile -Value $Entry
}

Write-Log "=============================================="
Write-Log "Starting Outreach Outlook add-in cache cleanup."
Write-Log "=============================================="

# ------------------------------------------------------------
# Stop Classic Outlook
# ------------------------------------------------------------

$OutlookProcesses = Get-Process -Name "OUTLOOK" -ErrorAction SilentlyContinue

if ($OutlookProcesses) {

    Write-Log "Outlook is currently running. Stopping Outlook..."

    $OutlookProcesses | Stop-Process -Force -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 3

    Write-Log "Outlook stopped."

}
else {
    Write-Log "Outlook is not currently running."
}


# ------------------------------------------------------------
# Get local user profiles
# ------------------------------------------------------------

$UserProfiles = Get-CimInstance Win32_UserProfile |
    Where-Object {
        $_.Special -eq $false -and
        $_.LocalPath -and
        (Test-Path $_.LocalPath)
    }


foreach ($Profile in $UserProfiles) {

    $ProfilePath = $Profile.LocalPath
    $UserName = Split-Path $ProfilePath -Leaf

    Write-Log "----------------------------------------------"
    Write-Log "Processing user: $UserName"
    Write-Log "Profile path: $ProfilePath"


    # --------------------------------------------------------
    # Outlook / Office Web Add-In Cache Locations
    # --------------------------------------------------------

    $CachePaths = @(

        # Main Office Web Extension Framework cache
        "$ProfilePath\AppData\Local\Microsoft\Office\16.0\Wef",

        # Outlook unified-manifest add-in cache
        "$ProfilePath\AppData\Local\Microsoft\Outlook\HubAppFileCache",

        # Older Office WebView cache
        "$ProfilePath\AppData\Local\Packages\Microsoft.Win32WebViewHost_cw5n1h2txyewy\AC\#!123\INetCache"
    )


    foreach ($CachePath in $CachePaths) {

        if (Test-Path $CachePath) {

            Write-Log "Clearing cache: $CachePath"

            try {

                Get-ChildItem `
                    -Path $CachePath `
                    -Force `
                    -ErrorAction SilentlyContinue |
                    Remove-Item `
                        -Recurse `
                        -Force `
                        -ErrorAction Stop

                Write-Log "Successfully cleared: $CachePath"

            }
            catch {

                Write-Log "WARNING: Unable to completely clear $CachePath"
                Write-Log "Error: $($_.Exception.Message)"

            }

        }
        else {

            Write-Log "Cache does not exist: $CachePath"

        }
    }
}

exit 0
