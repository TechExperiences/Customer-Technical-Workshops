[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ClientId,
    [Parameter(Mandatory)] [string]$SharePointSiteUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Graph {
    param([Parameter(Mandatory)] [ValidateSet('GET', 'POST')] [string]$Method, [Parameter(Mandatory)] [string]$Path, [string]$Body)
    $arguments = @('rest', '--method', $Method, '--url', "https://graph.microsoft.com/v1.0$Path", '--resource', 'https://graph.microsoft.com', '--headers', 'Content-Type=application/json')
    if ($Body) { $arguments += @('--body', $Body) }
    $response = & az @arguments
    if ($LASTEXITCODE -ne 0) { throw "Microsoft Graph request failed: $Method $Path. The signed-in Azure CLI user needs SharePoint/Graph administrator authority." }
    return $response | ConvertFrom-Json
}

$servicePrincipal = az ad sp show --id $ClientId --query '{appId:appId,displayName:displayName}' -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or -not $servicePrincipal.appId) { throw "Could not resolve service principal client ID $ClientId." }
$siteUri = [Uri]$SharePointSiteUrl
if ($siteUri.Scheme -ne 'https' -or -not $siteUri.Host -or -not $siteUri.AbsolutePath.Trim('/')) {
    throw 'SHAREPOINT_SITE_URL must be a full HTTPS SharePoint site URL.'
}
$site = Invoke-Graph -Method GET -Path "/sites/$($siteUri.Host):$($siteUri.AbsolutePath)"
$permissions = (Invoke-Graph -Method GET -Path "/sites/$($site.id)/permissions").value
$alreadyGranted = $false
foreach ($permission in $permissions) {
    foreach ($identity in @($permission.grantedToIdentitiesV2) + @($permission.grantedToIdentities)) {
        if ($identity.application.id -eq $servicePrincipal.appId -and $permission.roles -contains 'write') { $alreadyGranted = $true }
    }
}
if (-not $alreadyGranted) {
    $body = @{
        roles = @('write')
        grantedToIdentities = @(@{
            application = @{ id = $servicePrincipal.appId; displayName = $servicePrincipal.displayName }
        })
    } | ConvertTo-Json -Depth 5 -Compress
    [void](Invoke-Graph -Method POST -Path "/sites/$($site.id)/permissions" -Body $body)
    Write-Host "Granted service principal write access to $($site.webUrl)." -ForegroundColor Green
} else {
    Write-Host "Service principal already has SharePoint write access to $($site.webUrl)." -ForegroundColor Green
}
