[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $env:FABRIC_CAPACITY_ADMIN_UPN) {
    $upn = az account show --query user.name -o tsv
    if (-not $upn) { throw 'Could not determine the signed-in Azure user. Run az login first.' }
    azd env set FABRIC_CAPACITY_ADMIN_UPN $upn | Out-Null
    $env:FABRIC_CAPACITY_ADMIN_UPN = $upn
}

if (-not $env:SQL_ADMINISTRATOR_PASSWORD) {
    $securePassword = Read-Host 'Create a SQL administrator password for this deployment' -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    try { $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    azd env set SQL_ADMINISTRATOR_PASSWORD $plainPassword | Out-Null
    $env:SQL_ADMINISTRATOR_PASSWORD = $plainPassword
}

# UNIFY-SP-SUPPORT
$operator = $env:FABRIC_CAPACITY_ADMIN_UPN
$signedIn = az account show --query user -o json | ConvertFrom-Json
if ($signedIn.type -eq 'servicePrincipal') {
    $token = (az account get-access-token --resource https://database.windows.net --query accessToken -o tsv).Trim()
    $payload = $token.Split('.')[1].Replace('-', '+').Replace('_', '/')
    switch ($payload.Length % 4) { 2 { $payload += '==' } 3 { $payload += '=' } }
    $operator = ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json).oid
}
azd env set FABRIC_CAPACITY_ADMIN_OPERATOR $operator | Out-Null
$env:FABRIC_CAPACITY_ADMIN_OPERATOR = $operator
