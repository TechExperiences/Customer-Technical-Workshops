[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Import-DotEnv.ps1')
Import-DotEnv -Path (Join-Path $PSScriptRoot '..\.env')

if ([string]::IsNullOrWhiteSpace($env:AZURE_SUBSCRIPTION_ID)) {
  throw 'AZURE_SUBSCRIPTION_ID is not set in .env.'
}
if ([string]::IsNullOrWhiteSpace($env:SQL_ADMINISTRATOR_PASSWORD)) {
  throw 'SQL_ADMINISTRATOR_PASSWORD is not set in .env.'
}

$sqlPassword = ConvertTo-SecureString $env:SQL_ADMINISTRATOR_PASSWORD -AsPlainText -Force
$sqlLogin = if ([string]::IsNullOrWhiteSpace($env:SQL_ADMINISTRATOR_LOGIN)) { 'sqladmincaldova' } else { $env:SQL_ADMINISTRATOR_LOGIN }

& (Join-Path $PSScriptRoot '..\deploy.ps1') -SubscriptionId $env:AZURE_SUBSCRIPTION_ID -SqlAdministratorLogin $sqlLogin -SqlAdministratorPassword $sqlPassword
if ($LASTEXITCODE -ne 0) {
  throw "The fallback infrastructure deployment failed with exit code $LASTEXITCODE."
}
