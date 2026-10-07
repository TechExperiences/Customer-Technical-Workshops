param storageAccountName string
param storageLocation string
param sqlServerName string
param sqlServerAlreadyExists string
param sqlLocation string
param sqlAdministratorLogin string
@secure()
param sqlAdministratorPassword string
param sqlDatabaseName string
param fabricCapacityName string
param fabricCapacityLocation string
param fabricCapacityAdministrators array

var createSqlServer = toLower(sqlServerAlreadyExists) != 'true'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: storageLocation
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource dataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'data'
  properties: { publicAccess: 'None' }
}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = if (createSqlServer) {
  name: sqlServerName
  location: sqlLocation
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorPassword
    publicNetworkAccess: 'Enabled'
    minimalTlsVersion: '1.2'
  }
}

resource existingSqlServer 'Microsoft.Sql/servers@2023-08-01-preview' existing = if (!createSqlServer) {
  name: sqlServerName
}

resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = if (createSqlServer) {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource operationalDatabaseOnNewServer 'Microsoft.Sql/servers/databases@2023-08-01-preview' = if (createSqlServer) {
  parent: sqlServer
  name: sqlDatabaseName
  location: sqlLocation
  sku: { name: 'Basic', tier: 'Basic' }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

resource operationalDatabaseOnExistingServer 'Microsoft.Sql/servers/databases@2023-08-01-preview' = if (!createSqlServer) {
  parent: existingSqlServer
  name: sqlDatabaseName
  location: sqlLocation
  sku: { name: 'Basic', tier: 'Basic' }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

resource fabricCapacity 'Microsoft.Fabric/capacities@2023-11-01' = {
  name: fabricCapacityName
  location: fabricCapacityLocation
  sku: { name: 'F16', tier: 'Fabric' }
  properties: {
    administration: { members: fabricCapacityAdministrators }
  }
}

output storageAccountName string = storageAccount.name
output sqlServerFqdn string = createSqlServer ? sqlServer!.properties.fullyQualifiedDomainName : existingSqlServer!.properties.fullyQualifiedDomainName
output sqlDatabaseName string = createSqlServer ? operationalDatabaseOnNewServer.name : operationalDatabaseOnExistingServer.name
output fabricCapacityResourceId string = fabricCapacity.id
