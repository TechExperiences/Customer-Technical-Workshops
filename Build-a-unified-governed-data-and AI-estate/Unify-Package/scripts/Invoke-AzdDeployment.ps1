[CmdletBinding()]
param(
    [string]$EnvFile = (Join-Path (Split-Path -Parent $PSScriptRoot) '.env')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Import-DotEnv {
    param([Parameter(Mandatory)] [string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Environment file not found: $Path. Copy .env.example to .env and populate it first." }
    $values = [ordered]@{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) { continue }
        if ($trimmed -notmatch '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') { throw "Invalid .env entry: $line" }
        $name, $value = $Matches[1], $Matches[2].Trim()
        if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        $values[$name] = $value
    }
    return $values
}

function Invoke-Checked {
    param([Parameter(Mandatory)] [scriptblock]$Command, [Parameter(Mandatory)] [string]$FailureMessage)
    & $Command
    if ($LASTEXITCODE -ne 0) { throw $FailureMessage }
}

$environment = Import-DotEnv -Path (Resolve-Path -LiteralPath $EnvFile)
foreach ($required in @('AZURE_ENV_NAME', 'AZURE_SUBSCRIPTION_ID', 'AZURE_LOCATION', 'AZURE_RESOURCE_GROUP', 'FABRIC_CAPACITY_ADMIN_UPN', 'SQL_ADMINISTRATOR_LOGIN', 'SQL_ADMINISTRATOR_PASSWORD')) {
    $value = [string]$environment[$required]
    if (-not $value -or $value -match '^<.*>$') { throw "Set a real value for $required in $EnvFile before deployment." }
}

if (-not (Get-Command az -ErrorAction Ignore) -or -not (Get-Command azd -ErrorAction Ignore)) {
    throw 'Both Azure CLI (az) and Azure Developer CLI (azd) are required.'
}

foreach ($entry in $environment.GetEnumerator()) { Set-Item -Path "Env:$($entry.Key)" -Value $entry.Value }

& az account show --only-show-errors 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    $tenantArgument = if ($environment.AZURE_TENANT_ID -and $environment.AZURE_TENANT_ID -notmatch '^<.*>$') { @('--tenant', $environment.AZURE_TENANT_ID) } else { @() }
    Invoke-Checked -Command { & az login @tenantArgument --only-show-errors } -FailureMessage 'Azure CLI sign-in did not complete.'
}
Invoke-Checked -Command { & az account set --subscription $environment.AZURE_SUBSCRIPTION_ID } -FailureMessage "Cannot select subscription $($environment.AZURE_SUBSCRIPTION_ID). Sign in to the lab tenant and verify access."

& azd auth login --check-status 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    $tenantArgument = if ($environment.AZURE_TENANT_ID -and $environment.AZURE_TENANT_ID -notmatch '^<.*>$') { @('--tenant-id', $environment.AZURE_TENANT_ID) } else { @() }
    Invoke-Checked -Command { & azd auth login @tenantArgument } -FailureMessage 'Azure Developer CLI sign-in did not complete.'
}

$azdEnvironmentPath = Join-Path (Split-Path -Parent $PSScriptRoot) ".azure/$($environment.AZURE_ENV_NAME)/.env"
if (-not (Test-Path -LiteralPath $azdEnvironmentPath)) {
    Invoke-Checked -Command { & azd env new $environment.AZURE_ENV_NAME --subscription $environment.AZURE_SUBSCRIPTION_ID --location $environment.AZURE_LOCATION --no-prompt } -FailureMessage 'Could not create the Azure Developer CLI environment.'
} else {
    Invoke-Checked -Command { & azd env select $environment.AZURE_ENV_NAME } -FailureMessage 'Could not select the Azure Developer CLI environment.'
}

foreach ($entry in $environment.GetEnumerator()) {
    Invoke-Checked -Command { & azd env set $entry.Key $entry.Value --environment $environment.AZURE_ENV_NAME } -FailureMessage "Could not save $($entry.Key) to the azd environment."
}

Invoke-Checked -Command { & azd up --environment $environment.AZURE_ENV_NAME --no-prompt } -FailureMessage 'azd up failed. Review the preceding deployment output for the failing resource or permission.'
