param capacityName string
param location string
param capacityAdministratorObjectId string
param capacityAdministratorUpn string
param storageAccountName string
param storageBlobDataContributorPrincipalId string
param foundryAccountName string
param foundryProjectName string
param foundryAgentDeveloperPrincipalId string
param foundryLocation string

var storageBlobDataContributorRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
)
var azureAiDeveloperRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '64702f94-c441-49e6-a78b-ef80e0188fee'
)

resource fabricCapacity 'Microsoft.Fabric/capacities@2023-11-01' = {
  name: capacityName
  location: location
  sku: {
    name: 'F16'
    tier: 'Fabric'
  }
  properties: {
    administration: {
      members: [capacityAdministratorObjectId, capacityAdministratorUpn]
    }
  }
}

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
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
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

resource storageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, storageBlobDataContributorPrincipalId, storageBlobDataContributorRoleDefinitionId)
  scope: storageAccount
  properties: {
    principalId: storageBlobDataContributorPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: storageBlobDataContributorRoleDefinitionId
  }
}

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: foundryAccountName
  location: foundryLocation
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: foundryAccountName
    publicNetworkAccess: 'Enabled'
  }
}

resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: foundryAccount
  name: foundryProjectName
  properties: {
    displayName: foundryProjectName
    description: 'Ubiquitous Innovation Supply Chain project.'
  }
}

resource gptMiniDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: foundryAccount
  name: 'gpt5mini'
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-5-mini'
      version: '2025-08-07'
    }
  }
}

resource foundryAgentDeveloper 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(foundryProject.id, foundryAgentDeveloperPrincipalId, azureAiDeveloperRoleDefinitionId)
  scope: foundryProject
  properties: {
    principalId: foundryAgentDeveloperPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: azureAiDeveloperRoleDefinitionId
  }
}
