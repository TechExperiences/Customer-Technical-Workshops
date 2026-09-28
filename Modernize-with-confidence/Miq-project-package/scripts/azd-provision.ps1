[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Import-DotEnv.ps1')
Import-DotEnv -Path (Join-Path $PSScriptRoot '..\.env')

foreach ($name in @('AZURE_SUBSCRIPTION_ID', 'SQL_ADMINISTRATOR_PASSWORD', 'SQL_ENTRA_ADMIN_LOGIN', 'SQL_ENTRA_ADMIN_OBJECT_ID')) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name, 'Process'))) {
    throw "$name is not set in .env."
  }
}

$sqlPassword = ConvertTo-SecureString $env:SQL_ADMINISTRATOR_PASSWORD -AsPlainText -Force
$sqlLogin = if ([string]::IsNullOrWhiteSpace($env:SQL_ADMINISTRATOR_LOGIN)) { 'sqladmincaldova' } else { $env:SQL_ADMINISTRATOR_LOGIN }

& (Join-Path $PSScriptRoot '..\deploy.ps1') -SubscriptionId $env:AZURE_SUBSCRIPTION_ID -SqlAdministratorLogin $sqlLogin -SqlAdministratorPassword $sqlPassword -SqlEntraAdministratorLogin $env:SQL_ENTRA_ADMIN_LOGIN -SqlEntraAdministratorObjectId $env:SQL_ENTRA_ADMIN_OBJECT_ID
if ($LASTEXITCODE -ne 0) {
  throw "The fallback infrastructure deployment failed with exit code $LASTEXITCODE."
}
