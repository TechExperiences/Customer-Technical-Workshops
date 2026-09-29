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

function Save-CaldovaAppServiceDiagnostics {
  param([Parameter(Mandatory)][string] $Group, [Parameter(Mandatory)][string] $App)
  $diagnosticDirectory = Join-Path $projectRoot '.artifacts'
  $diagnosticZip = Join-Path $diagnosticDirectory 'appservice-diagnostics.zip'
  New-Item -ItemType Directory -Path $diagnosticDirectory -Force | Out-Null
  if (Test-Path -LiteralPath $diagnosticZip) { Remove-Item -LiteralPath $diagnosticZip -Force }
  try {
    Write-Host '[MIQ 6/6] Downloading App Service diagnostics automatically...'
    & az webapp log download --resource-group $Group --name $App --log-file $diagnosticZip --output none
    if ($LASTEXITCODE -eq 0) { Write-Host "App Service diagnostics saved to: $diagnosticZip" }
  }
  catch { Write-Warning "Could not download App Service diagnostics: $($_.Exception.Message)" }
}
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
  $readinessUrl = "$url/health/ready"
  $healthy = $false
  for ($attempt = 1; $attempt -le 18; $attempt++) {
    try {
      $response = Invoke-WebRequest -Uri $readinessUrl -TimeoutSec 30 -UseBasicParsing
      if ($response.StatusCode -eq 200) { $healthy = $true; break }
    }
    catch { }
    Write-Host "[MIQ 6/6] Waiting for App Service and managed-identity SQL readiness ($attempt/18)..."
    Start-Sleep -Seconds 10
  }
  if (-not $healthy) {
    Save-CaldovaAppServiceDiagnostics -Group $ResourceGroup -App $WebAppName
    throw "Managed-identity SQL readiness failed. The App Service /health/ready endpoint did not return HTTP 200: $readinessUrl"
  }
  try {
    $dashboardResponse = Invoke-WebRequest -Uri $url -TimeoutSec 30 -UseBasicParsing
    if ($dashboardResponse.StatusCode -ne 200) { throw "Dashboard returned HTTP $($dashboardResponse.StatusCode)." }
  }
  catch {
    Save-CaldovaAppServiceDiagnostics -Group $ResourceGroup -App $WebAppName
    throw "Web UI health check failed after SQL readiness passed. Dashboard did not return HTTP 200: $url. $($_.Exception.Message)"
  }
  $semanticUrl = "$url/SemanticSearch?query=medicine%20used%20to%20reduce%20fever"
  $semanticHealthy = $false
  for ($attempt = 1; $attempt -le 12; $attempt++) {
    try {
      $response = Invoke-WebRequest -Uri $semanticUrl -TimeoutSec 60 -UseBasicParsing
      if ($response.StatusCode -eq 200 -and $response.Content -match 'Meaning-based matches') { $semanticHealthy = $true; break }
    }
    catch { }
    Write-Host "[MIQ 6/6] Waiting for live semantic search validation ($attempt/12)..."
    Start-Sleep -Seconds 15
  }
  if (-not $semanticHealthy) {
    Save-CaldovaAppServiceDiagnostics -Group $ResourceGroup -App $WebAppName
    throw "Semantic-search validation failed. The app could not complete the Azure OpenAI and Azure SQL vector-search path: $semanticUrl"
  }
  Write-Host 'Semantic-search validation passed: Azure OpenAI embedding, Azure SQL vector ranking, and dashboard logging are working.'
  Write-Host "Web UI deployed: https://$WebAppName.azurewebsites.net"
}
finally {
  if (Test-Path -LiteralPath $artifactRoot) { Remove-Item -LiteralPath $artifactRoot -Force -Recurse }
  if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
}
