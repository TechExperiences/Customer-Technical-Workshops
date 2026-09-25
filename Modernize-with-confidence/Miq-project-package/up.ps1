[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts\Import-DotEnv.ps1')
Import-DotEnv -Path (Join-Path $PSScriptRoot '.env')

foreach ($name in @('AZURE_SUBSCRIPTION_ID', 'SQL_ADMINISTRATOR_PASSWORD')) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name, 'Process'))) {
    throw "$name must be set in .env."
  }
}

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

& azd up --no-prompt
exit $LASTEXITCODE
