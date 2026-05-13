@description('Location for the Document Intelligence resource.')
param location string = resourceGroup().location

@description('Name of the Document Intelligence account.')
param documentIntelligenceName string

@description('SKU for the Document Intelligence account.')
param sku string = 'S0'

@description('Tags to apply to the resources.')
param tags object = {}

// Azure Document Intelligence
resource documentIntelligence 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: documentIntelligenceName
  location: location
  tags: tags
  kind: 'FormRecognizer'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: sku
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
    }
    disableLocalAuth: true
  }
}

output id string = documentIntelligence.id

output name string = documentIntelligence.name

output endpoint string = documentIntelligence.properties.endpoint

output principalId string = documentIntelligence.identity.principalId
