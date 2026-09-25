[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$projectPath = Join-Path $repoRoot "backend/CongregationManager.Server"
$secretKey = "SyncServer:Registration:Secret"

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw "dotnet was not found. Install the .NET 10 SDK and make sure dotnet is on PATH."
}

Push-Location $repoRoot
try {
    # Capture the output so existing secrets are not printed to the console.
    $secrets = @(& dotnet user-secrets list --project $projectPath)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not read user secrets (exit code $LASTEXITCODE)."
    }

    $secretEntries = @($secrets -match "^$([regex]::Escape($secretKey)) =")
    # CMD does not expand the Bash command substitution from the README.
    $hasLiteralPlaceholder = $secretEntries -contains ($secretKey + ' = $(openssl rand -base64 33)')
    if ($secretEntries.Count -eq 0 -or $hasLiteralPlaceholder) {
        if ($hasLiteralPlaceholder) {
            Write-Host "Replacing the literal OpenSSL command with a random registration secret."
        }
        $bytes = New-Object byte[] 33
        $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        try {
            $random.GetBytes($bytes)
        } finally {
            $random.Dispose()
        }

        $secret = [Convert]::ToBase64String($bytes)
        & dotnet user-secrets set $secretKey $secret --project $projectPath
        if ($LASTEXITCODE -ne 0) {
            throw "Could not save the registration secret (exit code $LASTEXITCODE)."
        }
        Write-Host "Created a registration secret in .NET user secrets."
    } else {
        Write-Host "Using the existing registration secret in .NET user secrets."
    }

    Write-Host "Starting the sync server at http://127.0.0.1:5080. Press Ctrl+C to stop."
    & dotnet run --project $projectPath --launch-profile CongregationManager.Server
    $serverExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

exit $serverExitCode
