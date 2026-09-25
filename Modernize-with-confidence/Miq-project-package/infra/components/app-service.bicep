targetScope = 'resourceGroup'

param location string
param appServicePlanName string = 'plan-caldova-ordermgmt'
param webAppName string = 'app-caldova-ordermgmt'
@allowed([
  'Basic'
  'Standard'
  'PremiumV3'
])
param appServicePlanSkuTier string = 'Basic'
param appServicePlanSkuName string = 'B1'
param chatDeploymentName string = 'gpt-5-mini'
param embeddingDeploymentName string = 'text-embedding-ada-002'
param chatApiVersion string = '2024-08-01-preview'
param embeddingApiVersion string = '2023-05-15'

var commonTags = {
  managedBy: 'miq-bicep-fallback'
  workload: 'caldova-order-management'
}

resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
    tier: appServicePlanSkuTier
  }
  kind: 'app'
  properties: {
    reserved: false
  }
  tags: commonTags
}

resource app 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
    }
  }
  tags: commonTags
}

resource appSettings 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: app
  name: 'appsettings'
  properties: {
    AZURE_OPENAI_CHAT_DEPLOYMENT: chatDeploymentName
    AZURE_OPENAI_EMBEDDING_DEPLOYMENT: embeddingDeploymentName
    AZURE_OPENAI_CHAT_API_VERSION: chatApiVersion
    AZURE_OPENAI_EMBEDDING_API_VERSION: embeddingApiVersion
  }
}

output webAppDefaultHostName string = app.properties.defaultHostName
