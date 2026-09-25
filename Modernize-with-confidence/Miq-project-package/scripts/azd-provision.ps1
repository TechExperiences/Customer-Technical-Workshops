[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($env:AZURE_SUBSCRIPTION_ID)) {
  throw 'AZURE_SUBSCRIPTION_ID is not set. Let azd up complete its subscription selection, then try again.'
}

& (Join-Path $PSScriptRoot '..\deploy.ps1') -SubscriptionId $env:AZURE_SUBSCRIPTION_ID
if ($LASTEXITCODE -ne 0) {
  throw "The fallback infrastructure deployment failed with exit code $LASTEXITCODE."
}
