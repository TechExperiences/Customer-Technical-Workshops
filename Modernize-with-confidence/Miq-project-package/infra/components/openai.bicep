targetScope = 'resourceGroup'

param location string
@description('Azure OpenAI account name. The deployment script supplies a globally unique name.')
param openAiAccountName string = 'openai-caldova-${uniqueString(subscription().id, resourceGroup().id)}'
param chatDeploymentName string = 'gpt-5-mini'
@description('Confirm this version is offered in each candidate region before deployment.')
param chatModelVersion string = '2025-08-07'
param embeddingDeploymentName string = 'text-embedding-ada-002'
param embeddingModelVersion string = '2'

var commonTags = {
  managedBy: 'miq-bicep-fallback'
  workload: 'caldova-order-management'
}

resource openAi 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: openAiAccountName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: openAiAccountName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
  tags: commonTags
}

resource chatDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: openAi
  name: chatDeploymentName
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: chatDeploymentName
      version: chatModelVersion
    }
  }
}

resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: openAi
  name: embeddingDeploymentName
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: embeddingDeploymentName
      version: embeddingModelVersion
    }
  }
}

output openAiEndpoint string = openAi.properties.endpoint
