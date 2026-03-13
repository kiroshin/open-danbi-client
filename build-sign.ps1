param (
    [string]$PFX_FILE = "codesign.pfx",
    [string]$PFX_PASS = ""
)

Set-Location $PSScriptRoot

$SIG_TOOL = Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits\10\bin" -Filter "signtool.exe" -Recurse | 
            Where-Object { $_.FullName -like "*\x64\*" } | 
            Sort-Object -Property LastWriteTime -Descending | 
            Select-Object -First 1 -ExpandProperty FullName

$MAKENSIS = "C:\Program Files (x86)\NSIS\makensis.exe"

$EXE   = "main.dist\danbi.exe"
$NSI   = "danbi-setup.nsi"
$SETUP = "danbi-setup.exe"

Write-Host "--- Step 1: Sign EXE ---"
if (Test-Path $EXE) {
    & $SIG_TOOL sign /f $PFX_FILE /p $PFX_PASS /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /v $EXE
} else {
    Write-Error "EXE_NOT_FOUND at $(Get-Location)"
    exit 1
}

Write-Host "--- Step 2: Build NSI ---"
if (Test-Path $NSI) {
    & $MAKENSIS $NSI
} else {
    Write-Error "NSI_NOT_FOUND at $(Get-Location)"
    exit 1
}

Write-Host "--- Step 3: Sign Setup ---"
if (Test-Path $SETUP) {
    & $SIG_TOOL sign /f $PFX_FILE /p $PFX_PASS /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /v $SETUP
} else {
    Write-Error "SETUP_NOT_CREATED"
    exit 1
}

Write-Host "--- Success ---"