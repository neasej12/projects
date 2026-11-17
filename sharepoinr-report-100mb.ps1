
# ============================================================
# SharePoint Online - Large File Report
# Scans all folders and subfolders for files over 100 MB.
# Exports results to an Excel workbook.
# ============================================================

# -----------------------------
# CONFIGURATION
# -----------------------------

$SiteUrl = "https://leadscience.sharepoint.com/sites/SITE"
$LibraryName = "Documents"
$ClientId = "YOUR-ENTRA-APP-CLIENT-ID"

$MinimumSizeMB = 100
$OutputPath = "C:\Reports\SharePoint_Files_Over_100MB.xlsx"

$PageSize = 500

# -----------------------------
# IMPORT MODULES
# -----------------------------

$ErrorActionPreference = "Stop"

Import-Module PnP.PowerShell -ErrorAction Stop
Import-Module ImportExcel -ErrorAction Stop

# Create report directory if needed
$OutputFolder = Split-Path -Path $OutputPath -Parent

if (-not (Test-Path -LiteralPath $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force |
        Out-Null
}

# -----------------------------
# CONNECT TO SHAREPOINT
# -----------------------------

Write-Host "Connecting to SharePoint Online..." -ForegroundColor Cyan

Connect-PnPOnline `
    -Url $SiteUrl `
    -ClientId $ClientId `
    -Interactive `
    -ErrorAction Stop

$Library = Get-PnPList -Identity $LibraryName -ErrorAction Stop

if ($Library.BaseType.ToString() -ne "DocumentLibrary") {
    throw "'$LibraryName' is not a document library."
}

Write-Host "Connected successfully." -ForegroundColor Green
Write-Host "Scanning library: $LibraryName" -ForegroundColor Cyan

# -----------------------------
# HELPER: USER DISPLAY NAME
# -----------------------------

function Get-UserDisplayName {
    param($UserValue)

    if ($null -eq $UserValue) {
        return ""
    }

    if ($UserValue.PSObject.Properties["LookupValue"]) {
        return [string]$UserValue.LookupValue
    }

    return [string]$UserValue
}

# -----------------------------
# RECURSIVE LIBRARY QUERY
# -----------------------------

# RecursiveAll includes nested folders and their contents.
# Paging prevents requesting the entire library in one batch.

$CAML = @"
<View Scope='RecursiveAll'>
    <ViewFields>
        <FieldRef Name='ID' />
        <FieldRef Name='FSObjType' />
        <FieldRef Name='FileLeafRef' />
        <FieldRef Name='FileRef' />
        <FieldRef Name='FileDirRef' />
        <FieldRef Name='File_x0020_Size' />
        <FieldRef Name='Author' />
        <FieldRef Name='Editor' />
        <FieldRef Name='Created' />
        <FieldRef Name='Modified' />
    </ViewFields>
    <RowLimit Paged='TRUE'>$PageSize</RowLimit>
</View>
"@

$MinimumBytes = [long]($MinimumSizeMB * 1MB)
$SiteOrigin = ([uri]$SiteUrl).GetLeftPart(
    [System.UriPartial]::Authority
)

$Results = [System.Collections.Generic.List[object]]::new()

$ScannedFiles = 0
$MissingSizes = 0

Write-Host "Retrieving library items..." -ForegroundColor Yellow

# -----------------------------
# SCAN AND COLLECT FILES
# -----------------------------

$Items = Get-PnPListItem `
    -List $Library `
    -Query $CAML `
    -PageSize $PageSize `
    -ErrorAction Stop

foreach ($Item in $Items) {

    # Skip folders and document sets
    if ($Item.FileSystemObjectType.ToString() -ne "File") {
        continue
    }

    $ScannedFiles++

    $Fields = $Item.FieldValues
    $RawSize = $Fields["File_x0020_Size"]

    if ([string]::IsNullOrWhiteSpace([string]$RawSize)) {
        $MissingSizes++
        Write-Warning "Size unavailable: $($Fields['FileRef'])"
        continue
    }

    $SizeBytes = [long]$RawSize

    # Only report files STRICTLY larger than 100 MB
    if ($SizeBytes -le $MinimumBytes) {
        continue
    }

    $FileName = [string]$Fields["FileLeafRef"]
    $FolderPath = [string]$Fields["FileDirRef"]
    $FileRef = [string]$Fields["FileRef"]

    # Encode path segments to generate a usable file URL
    $EncodedPath = (
        ($FileRef -split "/") |
        ForEach-Object {
            [uri]::EscapeDataString($_)
        }
    ) -join "/"

    $FileUrl = "$SiteOrigin$EncodedPath"

    $Owner = Get-UserDisplayName $Fields["Author"]
    $ModifiedBy = Get-UserDisplayName $Fields["Editor"]

    $Results.Add(
        [PSCustomObject][ordered]@{
            "File name"        = $FileName
            "Full folder path" = $FolderPath
            "Item ID"          = $Item.Id
            "Direct link"      = $FileUrl
            "Owner"            = $Owner
            "Last modified by" = $ModifiedBy
            "Date modified"    = [datetime]$Fields["Modified"]
            "Date created"     = [datetime]$Fields["Created"]
            "File size (MB)"   = [math]::Round(
                ($SizeBytes / 1MB), 2
            )
        }
    )

    Write-Host "FOUND: $FileName - $([math]::Round($SizeBytes / 1MB, 2)) MB" `
        -ForegroundColor Green
}

# -----------------------------
# EXPORT TO EXCEL
# -----------------------------

Write-Host "Generating Excel report..." -ForegroundColor Cyan

# Replace existing report if it exists
if (Test-Path -LiteralPath $OutputPath) {
    Remove-Item -LiteralPath $OutputPath -Force
}

if ($Results.Count -gt 0) {

    $Results |
        Sort-Object -Property "File size (MB)" -Descending |
        Export-Excel `
            -Path $OutputPath `
            -WorksheetName "Large Files" `
            -TableName "SharePointLargeFiles" `
            -TableStyle Medium2 `
            -AutoSize `
            -AutoFilter `
            -FreezeTopRow `
            -BoldTopRow

}
else {

    # Create a header-only report when no files qualify.
    $Package = Open-ExcelPackage -Path $OutputPath -Create
    $Sheet = Add-Worksheet `
        -ExcelPackage $Package `
        -WorksheetName "Large Files"

    $Headers = @(
        "File name",
        "Full folder path",
        "Item ID",
        "Direct link",
        "Owner",
        "Last modified by",
        "Date modified",
        "Date created",
        "File size (MB)"
    )

    for ($i = 0; $i -lt $Headers.Count; $i++) {
        $Sheet.Cells[1, ($i + 1)].Value = $Headers[$i]
    }

    $Sheet.Cells["A1:I1"].Style.Font.Bold = $true

    Close-ExcelPackage -ExcelPackage $Package
}

# -----------------------------
# SUMMARY
# -----------------------------

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host " SHAREPOINT LARGE FILE REPORT COMPLETE" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Cyan

Write-Host "Site:             $SiteUrl"
Write-Host "Library:          $LibraryName"
Write-Host "Files scanned:    $ScannedFiles"
Write-Host "Files over 100MB: $($Results.Count)"
Write-Host "Missing sizes:    $MissingSizes"
Write-Host "Report saved:     $OutputPath"

Write-Host "=======================================" -ForegroundColor Cyan

if ($MissingSizes -gt 0) {
    Write-Warning "Some files could not be evaluated because size metadata was unavailable."
}

Disconnect-PnPOnline
