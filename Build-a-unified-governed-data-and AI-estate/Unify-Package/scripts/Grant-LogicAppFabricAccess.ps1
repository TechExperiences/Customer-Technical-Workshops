[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$WorkspaceId,
    [Parameter(Mandatory)] [string]$LogicAppApplicationId,
    [Parameter(Mandatory)] [string]$PowerBiAccessToken
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$headers = @{ Authorization = "Bearer $PowerBiAccessToken" }
$membersUri = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/users"

# A system-assigned managed identity is represented as an Entra service principal
# (principalType App) by the Power BI/Fabric workspace membership API.
$members = Invoke-RestMethod -Method Get -Uri $membersUri -Headers $headers
$existing = @($members.value | Where-Object { $_.identifier -eq $LogicAppApplicationId })
if ($existing) {
    Write-Host "Logic App managed identity already has Fabric workspace access." -ForegroundColor Green
    return
}

$body = @{
    # The Power BI/Fabric workspace API expects the service principal application
    # (client) ID for principalType App, not the Entra object/principal ID.
    identifier = $LogicAppApplicationId
    groupUserAccessRight = 'Contributor'
    principalType = 'App'
} | ConvertTo-Json -Compress

Invoke-RestMethod -Method Post -Uri $membersUri -Headers $headers -ContentType 'application/json' -Body $body | Out-Null
Write-Host "Granted the Logic App managed identity Contributor access to Fabric workspace $WorkspaceId." -ForegroundColor Green
