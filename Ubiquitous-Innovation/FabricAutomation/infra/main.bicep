param capacityName string
param location string
param capacityAdministratorObjectId string
param capacityAdministratorUpn string

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
