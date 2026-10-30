@description('Azure region for the resource group, ADLS Gen2, Search, and Cosmos DB resources.')
param location string

@description('The new ADLS Gen2 storage account name.')
param storageAccountName string

@description('The new Azure AI Search service name.')
param searchServiceName string

@description('The new Azure Cosmos DB for NoSQL account name.')
param cosmosAccountName string

@description('The new Foundry hub name.')
param foundryAccountName string

@description('The Foundry project name.')
param foundryProjectName string

@description('Foundry hub/project region. This is intentionally independent of the resource group location.')
param foundryLocation string

@description('The service principal object ID used by up.ps1.')
param automationPrincipalId string

@description('The Entra user object ID that receives portal access to the Foundry project.')
param portalUserPrincipalId string

var storageBlobDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var storageBlobDataOwnerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
var storageAccountContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '17d1049b-9a84-46fb-8f53-869881c3d3ab')
var cosmosDbOperatorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '230815da-be43-4aae-9cb4-875f7bd000aa')
var searchIndexDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8ebe5a00-799e-43f5-93ac-243d3dce84a7')
var searchServiceContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7ca78c08-252a-4471-8644-bb5ff32d4ba0')
var foundryUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '53ca6127-db72-4b80-b1b0-d745d6d5456d')
var foundryProjectManagerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'eadc314b-1a2d-4efa-be10-5d325db5065e')

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    isHnsEnabled: true
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
  properties: {
    publicAccess: 'None'
  }
}

// Serverless is the lowest-cost Cosmos configuration. Foundry Standard Agent Setup
// manages the required databases and containers after the capability host is ready.
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    disableLocalAuth: true
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
}

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: searchServiceName
  location: location
  sku: {
    name: 'standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    disableLocalAuth: false
    hostingMode: 'default'
    partitionCount: 1
    publicNetworkAccess: 'enabled'
    replicaCount: 1
    // Enables Azure AI Search Semantic Ranker in addition to Foundry File
    // Search's normal keyword and vector retrieval.
    semanticSearch: 'standard'
  }
}

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: foundryAccountName
  location: foundryLocation
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: foundryAccountName
    disableLocalAuth: false
    publicNetworkAccess: 'Enabled'
  }
}

resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  parent: foundryAccount
  name: foundryProjectName
  location: foundryLocation
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: foundryProjectName
    description: 'Fallback Supply Chain project with Fabric analytics and ADLS knowledge.'
  }

  resource cosmosConnection 'connections@2025-04-01-preview' = {
    name: cosmosAccountName
    properties: {
      category: 'CosmosDB'
      target: cosmosAccount.properties.documentEndpoint
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: cosmosAccount.id
        location: cosmosAccount.location
      }
    }
  }

  resource storageConnection 'connections@2025-04-01-preview' = {
    name: storageAccountName
    properties: {
      category: 'AzureStorageAccount'
      target: storageAccount.properties.primaryEndpoints.blob
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: storageAccount.id
        location: storageAccount.location
      }
    }
  }

  resource searchConnection 'connections@2025-04-01-preview' = {
    name: searchServiceName
    properties: {
      category: 'CognitiveSearch'
      target: 'https://${searchService.name}.search.windows.net'
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: searchService.id
        location: searchService.location
      }
    }
  }
}

resource gpt51Deployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: foundryAccount
  name: 'gpt51'
  dependsOn: [
    foundryProject
  ]
  sku: {
    name: 'GlobalStandard'
    // Global Standard capacity is allocated in 1K TPM units. This reserves
    // 50K TPM for the Foundry Supply Chain agent's gpt-5.1 deployment.
    capacity: 50
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-5.1'
      version: '2025-11-13'
    }
  }
}

// These role assignments are deterministic, so ARM treats an already-created
// assignment as the same resource rather than creating a duplicate.
resource automationStorageContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, automationPrincipalId, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    principalId: automationPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: storageBlobDataContributorRoleId
  }
}

resource projectStorageAccountContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, foundryProject.id, storageAccountContributorRoleId)
  scope: storageAccount
  properties: {
    principalId: foundryProject.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: storageAccountContributorRoleId
  }
}

resource projectStorageBlobContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, foundryProject.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    principalId: foundryProject.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: storageBlobDataContributorRoleId
  }
}

resource projectStorageBlobOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, foundryProject.id, storageBlobDataOwnerRoleId)
  scope: storageAccount
  properties: {
    principalId: foundryProject.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: storageBlobDataOwnerRoleId
  }
}

resource projectCosmosOperator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosAccount.id, foundryProject.id, cosmosDbOperatorRoleId)
  scope: cosmosAccount
  properties: {
    principalId: foundryProject.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: cosmosDbOperatorRoleId
  }
}

resource projectSearchIndexContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, foundryProject.id, searchIndexDataContributorRoleId)
  scope: searchService
  properties: {
    principalId: foundryProject.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: searchIndexDataContributorRoleId
  }
}

resource projectSearchServiceContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, foundryProject.id, searchServiceContributorRoleId)
  scope: searchService
  properties: {
    principalId: foundryProject.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: searchServiceContributorRoleId
  }
}

resource cosmosDataContributorRole 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2022-05-15' existing = {
  parent: cosmosAccount
  name: '00000000-0000-0000-0000-000000000002'
}

resource cosmosDataReaderRole 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2022-05-15' existing = {
  parent: cosmosAccount
  name: '00000000-0000-0000-0000-000000000001'
}

resource projectCosmosDataContributor 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmosAccount
  name: guid(cosmosAccount.id, foundryProject.id, cosmosDataContributorRole.id)
  properties: {
    principalId: foundryProject.identity.principalId
    roleDefinitionId: cosmosDataContributorRole.id
    // Cosmos ARM RBAC expects the fully qualified account resource ID for
    // account-wide data access; '/' is only a data-plane SDK-style scope.
    scope: cosmosAccount.id
  }
}

// The designated portal user may inspect Foundry-managed thread and memory
// records in Data Explorer, but cannot change or delete them.
resource portalUserCosmosDataReader 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmosAccount
  name: guid(cosmosAccount.id, portalUserPrincipalId, cosmosDataReaderRole.id)
  properties: {
    principalId: portalUserPrincipalId
    roleDefinitionId: cosmosDataReaderRole.id
    scope: cosmosAccount.id
  }
}

resource foundryAutomationProjectManager 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(foundryProject.id, automationPrincipalId, foundryProjectManagerRoleId)
  scope: foundryProject
  properties: {
    principalId: automationPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: foundryProjectManagerRoleId
  }
}

resource foundryAutomationUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(foundryProject.id, automationPrincipalId, foundryUserRoleId)
  scope: foundryProject
  properties: {
    principalId: automationPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: foundryUserRoleId
  }
}

resource foundryPortalUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(foundryProject.id, portalUserPrincipalId, foundryUserRoleId)
  scope: foundryProject
  properties: {
    principalId: portalUserPrincipalId
    principalType: 'User'
    roleDefinitionId: foundryUserRoleId
  }
}

resource accountCapabilityHost 'Microsoft.CognitiveServices/accounts/capabilityHosts@2025-04-01-preview' = {
  parent: foundryAccount
  name: 'fallback-account-agents'
  properties: {
    capabilityHostKind: 'Agents'
  }
  dependsOn: [
    projectStorageAccountContributor
    projectStorageBlobContributor
    projectStorageBlobOwner
    projectCosmosOperator
    projectCosmosDataContributor
    projectSearchIndexContributor
    projectSearchServiceContributor
  ]
}

resource projectCapabilityHost 'Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview' = {
  parent: foundryProject
  name: 'fallback-project-agents'
  properties: {
    #disable-next-line BCP037
    capabilityHostKind: 'Agents'
    vectorStoreConnections: [
      searchServiceName
    ]
    storageConnections: [
      storageAccountName
    ]
    threadStorageConnections: [
      cosmosAccountName
    ]
  }
  dependsOn: [
    accountCapabilityHost
  ]
}

output storageAccountName string = storageAccount.name
output searchServiceName string = searchService.name
output cosmosAccountName string = cosmosAccount.name
output foundryAccountName string = foundryAccount.name
output foundryProjectName string = foundryProject.name
