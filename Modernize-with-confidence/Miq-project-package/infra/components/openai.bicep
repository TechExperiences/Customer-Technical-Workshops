targetScope = 'resourceGroup'

param location string
@description('Azure OpenAI account name. The deployment script supplies a globally unique name.')
param openAiAccountName string = 'openai-caldova-${uniqueString(subscription().id, resourceGroup().id)}'
param chatDeploymentName string = 'gpt-5-mini'
@description('Confirm this version is offered in each candidate region before deployment.')
param chatModelVersion string = '2025-08-07'
param embeddingDeploymentName string = 'text-embedding-ada-002'
param embeddingModelVersion string = '2'
@description('Standard capacity units for text-embedding-ada-002. One unit is normally 1K TPM.')
param embeddingModelCapacity int = 10

var commonTags = {
  managedBy: 'mwc-bicep-fallback'
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
    // gpt-5-mini version 2025-08-07 is offered as GlobalStandard in West US.
    name: 'GlobalStandard'
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
  // Azure OpenAI serializes account-level deployment operations. Do not submit
  // this child deployment until the gpt-5-mini deployment has completed.
  dependsOn: [
    chatDeployment
  ]
  sku: {
    name: 'Standard'
    capacity: embeddingModelCapacity
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
