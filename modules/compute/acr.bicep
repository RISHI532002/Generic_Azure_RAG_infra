param location string = resourceGroup().location

param acrName string

param acrSku string = 'Premium'


resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Disabled'
  }
}

output id string = acr.id
output name string = acr.name
