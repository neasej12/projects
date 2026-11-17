# Install Microsoft Graph if it is not already installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read.All"

# ============================================================
# CONFIGURATION
# CHANGE GROUPNAMEHERE TO NAMES OF GROUPS 
# CHANGE USER@DDOMAIN.COM TO OWNERS OF THOSE GROUPS

# ============================================================

# Security groups to create
$GroupNames = @(
    "GROUPNAMEHERE",
    "GROUPNAMEHERE",
    "GROUPNAMEHERE",
    "GROUPNAMEHERE"
)

# Owners that should be assigned to EVERY group
$OwnerUPNs = @(
    "USER@DOMAIN.com",
    "USER@DOMAIN.com",
    "USER@DOMAIN.com"
)

# ============================================================
# RESOLVE OWNERS
# ============================================================

$Owners = @()

foreach ($OwnerUPN in $OwnerUPNs) {

    try {

        $Owner = Get-MgUser `
            -UserId $OwnerUPN `
            -ErrorAction Stop

        $Owners += $Owner

        Write-Host "Found owner: $($Owner.DisplayName) [$OwnerUPN]" `
            -ForegroundColor Green
    }
    catch {

        Write-Warning "Unable to find owner: $OwnerUPN"
    }
}

if ($Owners.Count -eq 0) {
    Write-Error "No valid owners were found. Stopping script."
    exit 1
}

# ============================================================
# CREATE GROUPS
# ============================================================

foreach ($GroupName in $GroupNames) {

    Write-Host ""
    Write-Host "Processing group: $GroupName" `
        -ForegroundColor Cyan

    # Escape apostrophes for Graph filter
    $EscapedGroupName = $GroupName.Replace("'", "''")

    # Check if the group already exists
    $Group = Get-MgGroup `
        -Filter "displayName eq '$EscapedGroupName'" `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($Group) {

        Write-Host "Group already exists: $GroupName" `
            -ForegroundColor Yellow

    }
    else {

        # MailNickname is required even though this is not a mail-enabled group
        $MailNickname = (
            $GroupName -replace '[^a-zA-Z0-9]', ''
        )

        # Add a unique suffix if necessary
        $MailNickname = "$MailNickname$((Get-Random -Minimum 1000 -Maximum 9999))"

        $Group = New-MgGroup `
            -DisplayName $GroupName `
            -Description "Security Group - $GroupName" `
            -MailEnabled:$false `
            -MailNickname $MailNickname `
            -SecurityEnabled:$true

        Write-Host "Created group: $GroupName" `
            -ForegroundColor Green
    }

    # ========================================================
    # ASSIGN OWNERS
    # ========================================================

    $ExistingOwners = Get-MgGroupOwner `
        -GroupId $Group.Id `
        -All

    foreach ($Owner in $Owners) {

        if ($ExistingOwners.Id -contains $Owner.Id) {

            Write-Host "Already an owner: $($Owner.UserPrincipalName)" `
                -ForegroundColor Yellow

        }
        else {

            $OwnerReference = @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($Owner.Id)"
            }

            New-MgGroupOwnerByRef `
                -GroupId $Group.Id `
                -BodyParameter $OwnerReference

            Write-Host "Added owner: $($Owner.UserPrincipalName)" `
                -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "Security group creation and owner assignment complete." `
    -ForegroundColor Cyan
