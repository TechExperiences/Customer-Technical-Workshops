[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$UserPrincipalName,
    [string]$SkuPartNumber = 'FABRIC_FREE'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-GraphRest {
    param([Parameter(Mandatory)] [ValidateSet('GET', 'POST')] [string]$Method, [Parameter(Mandatory)] [string]$Url, [string]$Body)
    $arguments = @('rest', '--method', $Method, '--url', $Url, '--resource', 'https://graph.microsoft.com', '--headers', 'Content-Type=application/json')
    if ($Body) { $arguments += @('--body', $Body) }
    $response = & az @arguments
    if ($LASTEXITCODE -ne 0) { throw "Microsoft Graph request failed: $Method $Url" }
    return $response | ConvertFrom-Json
}

$encodedUpn = [System.Uri]::EscapeDataString($UserPrincipalName)
$licenseDetails = Invoke-GraphRest -Method GET -Url "https://graph.microsoft.com/v1.0/users/$encodedUpn/licenseDetails?`$select=skuId,skuPartNumber"
if (@($licenseDetails.value | Where-Object { $_.skuPartNumber -eq $SkuPartNumber }).Count) {
    Write-Host "Fabric license $SkuPartNumber is already assigned to $UserPrincipalName." -ForegroundColor Green
    return
}

$subscribedSkus = Invoke-GraphRest -Method GET -Url 'https://graph.microsoft.com/v1.0/subscribedSkus?$select=skuId,skuPartNumber,prepaidUnits,consumedUnits'
$sku = @($subscribedSkus.value | Where-Object { $_.skuPartNumber -eq $SkuPartNumber } | Select-Object -First 1)
if (-not $sku) {
    $relatedSkus = @($subscribedSkus.value | Where-Object { $_.skuPartNumber -match 'FABRIC|POWER_BI' } | ForEach-Object { $_.skuPartNumber })
    $availableText = if ($relatedSkus.Count) { $relatedSkus -join ', ' } else { 'none returned by Microsoft Graph' }
    throw "The tenant has no available SKU named '$SkuPartNumber'. Fabric/Power BI SKU candidates returned by Microsoft Graph: $availableText. Set FABRIC_LICENSE_SKU_PART_NUMBER to the exact required SKU."
}

$available = [int]$sku.prepaidUnits.enabled - [int]$sku.consumedUnits
if ($available -lt 1) {
    throw "No unassigned units remain for license $SkuPartNumber. Acquire or free a license unit before deployment."
}

$body = @{ addLicenses = @(@{ skuId = $sku.skuId }); removeLicenses = @() } | ConvertTo-Json -Compress
[void](Invoke-GraphRest -Method POST -Url "https://graph.microsoft.com/v1.0/users/$encodedUpn/assignLicense" -Body $body)
Write-Host "Assigned Fabric license $SkuPartNumber to $UserPrincipalName." -ForegroundColor Green
