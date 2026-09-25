targetScope = 'resourceGroup'

param location string
@description('Logical SQL server name. The deployment script supplies a globally unique name.')
param sqlServerName string = 'sql-caldova-${uniqueString(subscription().id, resourceGroup().id)}'
param databaseName string = 'CaldovaOrderManagement'
param administratorLogin string
@secure()
param administratorLoginPassword string
@description('Hyperscale SKU to use. Change this if the selected region does not offer HS_Gen5_2.')
param databaseSkuName string = 'HS_Gen5_2'

var commonTags = {
  managedBy: 'miq-bicep-fallback'
  workload: 'caldova-order-management'
}

resource server 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
  tags: commonTags
}

resource database 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: server
  name: databaseName
  location: location
  sku: {
    name: databaseSkuName
    tier: 'Hyperscale'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
  tags: commonTags
}

output sqlServerFullyQualifiedDomainName string = server.properties.fullyQualifiedDomainName
