// The complete fallback-aware infrastructure deployment is intentionally run by
// the preprovision azd hook. azd validates that its Bicep module contains at
// least one resource, so this nested deployment is a harmless provision marker.
// It creates no resource group or workload resource.
targetScope = 'subscription'

resource azdProvisionMarker 'Microsoft.Resources/deployments@2024-03-01' = {
  name: 'azd-provision-marker-${uniqueString(subscription().id, deployment().name)}'
  location: 'westus2'
  properties: {
    mode: 'Incremental'
    parameters: {}
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

output managedBy string = 'deploy.ps1 via azd preprovision hook'
