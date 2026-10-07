param storageAccountName string
param storageLocation string
param sqlServerName string
param sqlLocation string
param sqlAdministratorLogin string
@secure()
param sqlAdministratorPassword string
param sqlDatabaseName string
param fabricCapacityName string
param fabricCapacityLocation string
param fabricCapacityAdministrators array

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

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: sqlLocation
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorPassword
    publicNetworkAccess: 'Enabled'
    minimalTlsVersion: '1.2'
  }
}

resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource operationalDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
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

// Foundation for the BusinessApplication-to-Fabric SQL integration. The workflow
// stays disabled until its managed identity has confirmed Fabric workspace access.
resource integrationAccount 'Microsoft.Logic/integrationAccounts@2019-05-01' = {
  name: 'caldova-integration-account'
  location: sqlLocation
  sku: {
    name: 'Free'
  }
  // Required by the Microsoft.Logic resource contract even when no B2B artifacts
  // are configured yet.
  properties: {}
}

resource businessApplicationIngestLogicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'caldova-businessapp-ingest'
  location: sqlLocation
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Disabled'
    integrationAccount: {
      id: integrationAccount.id
    }
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {}
          }
        }
      }
      actions: {}
      outputs: {}
    }
    parameters: {}
  }
}

output storageAccountName string = storageAccount.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = operationalDatabase.name
output fabricCapacityResourceId string = fabricCapacity.id
output businessApplicationLogicAppName string = businessApplicationIngestLogicApp.name
output businessApplicationLogicAppPrincipalId string = businessApplicationIngestLogicApp.identity.principalId
