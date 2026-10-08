[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$WorkspaceId,
    [Parameter(Mandatory)] [string]$LogicAppPrincipalId,
    [Parameter(Mandatory)] [string]$FabricAccessToken
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$headers = @{ Authorization = "Bearer $FabricAccessToken" }
$roleAssignmentsUri = "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/roleAssignments"

# The Fabric Core API takes the service principal's Entra object ID directly, unlike
# the legacy Power BI membership API, which required the application (client) ID and
# did its own internal Microsoft Graph lookup - the lookup that was flaky for a
# managed identity created moments earlier by this same deployment.
$roleAssignments = Invoke-RestMethod -Method Get -Uri $roleAssignmentsUri -Headers $headers
$existing = @($roleAssignments.value | Where-Object { $_.principal.id -eq $LogicAppPrincipalId })
if ($existing) {
    Write-Host "Logic App managed identity already has Fabric workspace access." -ForegroundColor Green
    return
}

$body = @{
    principal = @{
        id   = $LogicAppPrincipalId
        type = 'ServicePrincipal'
    }
    role = 'Contributor'
} | ConvertTo-Json -Compress

# Kept as defense-in-depth for any residual propagation delay, though the Fabric Core
# API's direct object-ID lookup removes the failure mode retries previously masked.
$maxAttempts = 4
$delaySeconds = 15
for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
    try {
        Invoke-RestMethod -Method Post -Uri $roleAssignmentsUri -Headers $headers -ContentType 'application/json' -Body $body | Out-Null
        Write-Host "Granted the Logic App managed identity Contributor access to Fabric workspace $WorkspaceId." -ForegroundColor Green
        return
    } catch {
        if ($attempt -eq $maxAttempts) { throw }
        Write-Host "Granting Fabric workspace access attempt $attempt of $maxAttempts failed ($($_.Exception.Message)); retrying in $delaySeconds seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds $delaySeconds
        $delaySeconds = [Math]::Min($delaySeconds * 2, 120)
    }
}
