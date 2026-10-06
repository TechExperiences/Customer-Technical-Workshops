[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ParametersFile,
    [Parameter(Mandatory)] [string]$SqlAdministratorPassword,
    [string]$DeploymentLocation = 'westus2'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
$template = Join-Path $packageRoot 'infra/main.bicep'

if (-not (Get-Command az -ErrorAction Ignore)) { throw 'Azure CLI is required.' }
$account = az account show --query '{id:id,name:name}' -o json | ConvertFrom-Json
if (-not $account.id) { throw 'No active Azure subscription. Run az login first.' }

az deployment sub create `
  --name "caldova-foundation-$(Get-Date -Format yyyyMMddHHmmss)" `
  --location $DeploymentLocation `
  --template-file $template `
  --parameters "@$ParametersFile" sqlAdministratorPassword=$SqlAdministratorPassword `
  --query 'properties.outputs' -o json
