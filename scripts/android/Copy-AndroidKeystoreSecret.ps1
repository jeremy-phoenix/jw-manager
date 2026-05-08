[CmdletBinding()]
param(
    [string]$KeystorePath,
    [string]$OutFile,
    [switch]$NoClipboard
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if ([string]::IsNullOrWhiteSpace($KeystorePath)) {
    $KeystorePath = Join-Path $repoRoot "congregation_manager\android\app\upload-keystore.p12"
}

if (-not (Test-Path $KeystorePath)) {
    throw "Keystore was not found at '$KeystorePath'."
}

$keystoreBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($KeystorePath))

if (-not [string]::IsNullOrWhiteSpace($OutFile)) {
    Set-Content -Path $OutFile -Value $keystoreBase64 -Encoding ASCII -NoNewline
    Write-Host "Wrote ANDROID_KEYSTORE_BASE64 to: $OutFile"
}

if (-not $NoClipboard) {
    Set-Clipboard -Value $keystoreBase64
    Write-Host "Copied ANDROID_KEYSTORE_BASE64 to the clipboard."
}

Write-Host "Paste this value into the GitHub repository secret named ANDROID_KEYSTORE_BASE64."