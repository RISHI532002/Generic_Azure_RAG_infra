@description('The location where the Azure Container Registry will be created. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('The name of the Azure Container Registry to be created.')
param acrName string

@description('The SKU of the Azure Container Registry. Defaults to Premium.')
param acrSku string = 'Premium'

@description('Tags to apply to the Azure Container Registry.')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
    networkRuleSet: {
      defaultAction: 'Deny'
    }
  }
}

output id string = acr.id

output name string = acr.name

output loginServer string = acr.properties.loginServer
