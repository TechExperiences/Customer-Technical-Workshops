targetScope = 'subscription'

@description('The name of the resource group to create.')
param resourceGroupName string = 'rg-caldova'

@description('The already-selected location for the resource group. The deployment script chooses this from its ordered fallback list.')
param resourceGroupLocation string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
  tags: {
    managedBy: 'miq-bicep-fallback'
    deploymentPurpose: 'caldova-order-management'
  }
}

output deployedResourceGroupName string = resourceGroup.name
output deployedResourceGroupLocation string = resourceGroup.location
