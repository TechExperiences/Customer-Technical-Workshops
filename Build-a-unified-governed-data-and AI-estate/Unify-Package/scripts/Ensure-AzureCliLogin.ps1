[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction Ignore)) { throw 'Azure CLI is required for this deployment.' }
& az account show --only-show-errors 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'No Azure CLI session found. Starting interactive Azure CLI sign-in...' -ForegroundColor Yellow
    & az login --only-show-errors | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Azure CLI sign-in did not complete.' }
}

$account = & az account show --query '{name:name,id:id,tenantId:tenantId}' -o json | ConvertFrom-Json
if (-not $account.id) { throw 'Azure CLI sign-in succeeded but no subscription is selected.' }
Write-Host "Azure CLI authenticated to subscription: $($account.name)" -ForegroundColor Green
