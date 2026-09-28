[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\Import-DotEnv.ps1')
Import-DotEnv -Path (Join-Path $PSScriptRoot '.env')

foreach ($name in @('AZURE_SUBSCRIPTION_ID', 'SQL_ADMINISTRATOR_PASSWORD', 'SQL_ENTRA_ADMIN_LOGIN', 'SQL_ENTRA_ADMIN_OBJECT_ID')) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name, 'Process'))) {
    throw "$name must be set in .env."
  }
}

$environmentName = if ([string]::IsNullOrWhiteSpace($env:AZURE_ENV_NAME)) { 'Miq-project-package' } else { $env:AZURE_ENV_NAME }

& azd auth login --check-status --no-prompt 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
  $servicePrincipalVariables = @('AZURE_CLIENT_ID', 'AZURE_TENANT_ID', 'AZURE_CLIENT_SECRET')
  $hasServicePrincipal = ($servicePrincipalVariables | Where-Object {
    [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_, 'Process'))
  }).Count -eq 0

  if ($hasServicePrincipal) {
    & azd auth login --client-id $env:AZURE_CLIENT_ID --tenant-id $env:AZURE_TENANT_ID --client-secret $env:AZURE_CLIENT_SECRET --no-prompt
  }
  else {
    Write-Host 'Opening Azure sign-in for azd...'
    & azd auth login
  }
  if ($LASTEXITCODE -ne 0) { throw 'azd authentication failed or was cancelled.' }
}

# Try selecting first. An azd environment can exist even when its local .env
# file was interrupted or has not been written yet, so testing that file before
# selecting would incorrectly try to create an environment that already exists.
& azd env select $environmentName --no-prompt 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Creating azd environment '$environmentName'..."
  & azd env new $environmentName --subscription $env:AZURE_SUBSCRIPTION_ID --no-prompt
  if ($LASTEXITCODE -ne 0) {
    # It may have been created by an earlier interrupted run. Select it once
    # more before reporting a failure.
    & azd env select $environmentName --no-prompt
  }
}
if ($LASTEXITCODE -ne 0) { throw "Unable to create or select azd environment '$environmentName'." }

& azd env set AZURE_SUBSCRIPTION_ID $env:AZURE_SUBSCRIPTION_ID --no-prompt
if ($LASTEXITCODE -ne 0) { throw 'Unable to save AZURE_SUBSCRIPTION_ID in the azd environment.' }

& azd up --no-prompt
exit $LASTEXITCODE
