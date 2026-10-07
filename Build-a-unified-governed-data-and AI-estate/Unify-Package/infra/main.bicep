targetScope = 'subscription'

@description('Name of the Azure resource group that contains the estate.')
param resourceGroupName string = 'rg-Build-Unify'
@description('Region for the resource group, Azure SQL Server, and Fabric capacity.')
param resourceGroupLocation string = 'westus2'
@description('Globally unique, lowercase Storage Account name (3-24 alphanumeric characters).')
param storageAccountName string = toLower('stcaldova${take(uniqueString(subscription().id, resourceGroupName), 14)}')
@description('The location for Blob Storage.')
param storageLocation string = 'westus3'
@description('Globally unique Azure SQL logical-server name.')
param sqlServerName string
@secure()
@description('Temporary SQL administrator password. Store this in Key Vault for production use.')
param sqlAdministratorPassword string
param sqlAdministratorLogin string = 'squnify'
param sqlDatabaseName string = 'OperationalData'
param fabricCapacityName string = toLower('fabriccapacity${take(uniqueString(subscription().id, resourceGroupName), 12)}')
@description('UPNs of Fabric capacity administrators.')
param fabricCapacityAdministrators array

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
  tags: {
    solution: 'Caldova-Unified'
    managedBy: 'IaC'
  }
}

module estate './modules/estate.bicep' = {
  name: 'caldova-estate'
  scope: resourceGroup
  params: {
    storageAccountName: storageAccountName
    storageLocation: storageLocation
    sqlServerName: sqlServerName
    sqlLocation: resourceGroupLocation
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorPassword: sqlAdministratorPassword
    sqlDatabaseName: sqlDatabaseName
    fabricCapacityName: fabricCapacityName
    fabricCapacityLocation: 'westus2'
    fabricCapacityAdministrators: fabricCapacityAdministrators
  }
}

output resourceGroupId string = resourceGroup.id
output storageAccountName string = estate.outputs.storageAccountName
output sqlServerFqdn string = estate.outputs.sqlServerFqdn
output sqlDatabaseName string = estate.outputs.sqlDatabaseName
output fabricCapacityResourceId string = estate.outputs.fabricCapacityResourceId
output businessApplicationLogicAppName string = estate.outputs.businessApplicationLogicAppName
output businessApplicationLogicAppPrincipalId string = estate.outputs.businessApplicationLogicAppPrincipalId
