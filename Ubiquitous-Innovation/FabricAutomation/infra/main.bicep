param capacityName string
param location string
param capacityAdministratorUpn string
param capacityOperatorObjectId string = ''

resource fabricCapacity 'Microsoft.Fabric/capacities@2023-11-01' = {
  name: capacityName
  location: location
  sku: {
    name: 'F16'
    tier: 'Fabric'
  }
  properties: {
    administration: {
      members: empty(capacityOperatorObjectId) ? [capacityAdministratorUpn] : [capacityAdministratorUpn, capacityOperatorObjectId]
    }
  }
}
