[CmdletBinding()]
param(
    [string]$KeystorePath,
    [string]$KeyPropertiesPath,
    [string]$Alias = "upload",
    [string]$DistinguishedName = "CN=Congregation Manager, OU=Mobile, O=Congregation Manager, L=Unknown, S=Unknown, C=US",
    [int]$ValidityDays = 10000,
    [switch]$Force,
    [switch]$SkipClipboard,
    [switch]$SkipKeyProperties
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

if ([string]::IsNullOrWhiteSpace($KeystorePath)) {
    $KeystorePath = Join-Path $repoRoot "congregation_manager\android\app\upload-keystore.p12"
}

if ([string]::IsNullOrWhiteSpace($KeyPropertiesPath)) {
    $KeyPropertiesPath = Join-Path $repoRoot "congregation_manager\android\key.properties"
}

function ConvertTo-PlainText {
    param([securestring]$SecureString)

    return [System.Net.NetworkCredential]::new("", $SecureString).Password
}

function ConvertTo-JavaPropertyValue {
    param([string]$Value)

    if ($Value.Contains("`r") -or $Value.Contains("`n")) {
        throw "Java properties values cannot contain newlines."
    }

    return $Value.Replace("\", "\\").Replace(":", "\:").Replace("=", "\=")
}

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    throw "keytool was not found. Install a JDK and make sure keytool is on PATH."
}

if ((Test-Path $KeystorePath) -and -not $Force) {
    throw "Keystore already exists at '$KeystorePath'. Re-run with -Force to replace it."
}

New-Item -ItemType Directory -Force -Path (Split-Path $KeystorePath -Parent) | Out-Null
if (-not $SkipKeyProperties) {
    New-Item -ItemType Directory -Force -Path (Split-Path $KeyPropertiesPath -Parent) | Out-Null
}

$storePasswordSecure = Read-Host "ANDROID_KEYSTORE_PASSWORD" -AsSecureString
$storePassword = ConvertTo-PlainText $storePasswordSecure
if ($storePassword.Length -lt 6) {
    throw "The keystore password must be at least 6 characters."
}

$useSamePassword = Read-Host "Use the same value for ANDROID_KEY_PASSWORD? [Y/n]"
if ($useSamePassword -match "^(n|no)$") {
    $keyPasswordSecure = Read-Host "ANDROID_KEY_PASSWORD" -AsSecureString
    $keyPassword = ConvertTo-PlainText $keyPasswordSecure
} else {
    $keyPassword = $storePassword
}

if ($keyPassword.Length -lt 6) {
    throw "The key password must be at least 6 characters."
}

if (Test-Path $KeystorePath) {
    Remove-Item $KeystorePath -Force
}

$keytoolArgs = @(
    "-genkeypair",
    "-v",
    "-keystore", $KeystorePath,
    "-storetype", "PKCS12",
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", $ValidityDays.ToString(),
    "-alias", $Alias,
    "-storepass", $storePassword,
    "-keypass", $keyPassword,
    "-dname", $DistinguishedName
)

& $keytool.Source @keytoolArgs
if ($LASTEXITCODE -ne 0) {
    throw "keytool failed with exit code $LASTEXITCODE."
}

if (-not $SkipKeyProperties) {
    $keyProperties = @(
        "storePassword=$(ConvertTo-JavaPropertyValue $storePassword)",
        "keyPassword=$(ConvertTo-JavaPropertyValue $keyPassword)",
        "keyAlias=$(ConvertTo-JavaPropertyValue $Alias)",
        "storeFile=app/upload-keystore.p12",
        "storeType=PKCS12"
    ) -join [Environment]::NewLine

    [System.IO.File]::WriteAllText(
        $KeyPropertiesPath,
        $keyProperties + [Environment]::NewLine,
        [System.Text.UTF8Encoding]::new($false)
    )
}

$keystoreBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($KeystorePath))
if (-not $SkipClipboard) {
    try {
        Set-Clipboard -Value $keystoreBase64
        Write-Host "Copied ANDROID_KEYSTORE_BASE64 to the clipboard."
    } catch {
        Write-Warning "Could not copy to the clipboard. Run Copy-AndroidKeystoreSecret.ps1 after this script."
    }
}

Write-Host "Created keystore: $KeystorePath"
if (-not $SkipKeyProperties) {
    Write-Host "Created local signing file: $KeyPropertiesPath"
}
Write-Host "GitHub secret values:"
Write-Host "  ANDROID_KEYSTORE_BASE64 = clipboard value from this script"
Write-Host "  ANDROID_KEYSTORE_PASSWORD = the keystore password you entered"
Write-Host "  ANDROID_KEY_ALIAS = $Alias"
Write-Host "  ANDROID_KEY_PASSWORD = the key password you entered"