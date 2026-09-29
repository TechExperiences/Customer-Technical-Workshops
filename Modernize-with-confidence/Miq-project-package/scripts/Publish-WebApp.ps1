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
  Write-Host '[MIQ 6/6] Restoring packages and publishing .NET application...'
  & dotnet publish $webProject -c Release -o $artifactRoot
  if ($LASTEXITCODE -ne 0) { throw 'dotnet publish failed.' }
  Write-Host '[MIQ 6/6] Creating deployment ZIP...'
  Compress-Archive -Path (Join-Path $artifactRoot '*') -DestinationPath $zipPath -Force
  Write-Host '[MIQ 6/6] Uploading ZIP to Azure App Service...'
  & az webapp deploy --resource-group $ResourceGroup --name $WebAppName --src-path $zipPath --type zip --output none
  if ($LASTEXITCODE -ne 0) { throw 'Azure App Service ZIP deployment failed.' }
  $url = "https://$WebAppName.azurewebsites.net"
  $healthy = $false
  for ($attempt = 1; $attempt -le 18; $attempt++) {
    try {
      $response = Invoke-WebRequest -Uri $url -TimeoutSec 30 -UseBasicParsing
      if ($response.StatusCode -eq 200) { $healthy = $true; break }
    }
    catch { }
    Write-Host "[MIQ 6/6] Waiting for App Service Dashboard to become healthy ($attempt/18)..."
    Start-Sleep -Seconds 10
  }
  if (-not $healthy) { throw "Web UI health check failed. Dashboard did not return HTTP 200: $url" }
  Write-Host "Web UI deployed: https://$WebAppName.azurewebsites.net"
}
finally {
  if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Force -Recurse }
  if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
}
