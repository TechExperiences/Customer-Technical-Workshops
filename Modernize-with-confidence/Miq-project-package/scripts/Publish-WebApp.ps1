[CmdletBinding()]
param(
  [Parameter(Mandatory)][string] $ResourceGroup,
  [Parameter(Mandatory)][string] $WebAppName
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$webProject = Join-Path $projectRoot 'src\CaldovaOrderManagement.Web\CaldovaOrderManagement.Web.csproj'
$artifactRoot = Join-Path $projectRoot '.artifacts\webapp'
$zipPath = Join-Path $projectRoot '.artifacts\caldova-webapp.zip'
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { throw '.NET 10 SDK is required to publish the web application.' }
if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Force -Recurse }
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
try {
  & dotnet publish $webProject -c Release -o $artifactRoot
  if ($LASTEXITCODE -ne 0) { throw 'dotnet publish failed.' }
  Compress-Archive -Path (Join-Path $artifactRoot '*') -DestinationPath $zipPath -Force
  & az webapp deploy --resource-group $ResourceGroup --name $WebAppName --src-path $zipPath --type zip --output none
  if ($LASTEXITCODE -ne 0) { throw 'Azure App Service ZIP deployment failed.' }
  Write-Host "Web UI deployed: https://$WebAppName.azurewebsites.net"
}
finally {
  if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Force -Recurse }
  if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
}
