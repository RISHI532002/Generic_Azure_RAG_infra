@description('Location for the Azure AI Search resource.')
param location string = resourceGroup().location

@description('Name of the Azure AI Search service.')
param searchServiceName string

@description('SKU for the Azure AI Search service. Standard or higher required for private endpoints.')
param searchSku string = 'standard'

@description('Number of replicas for high availability.')
param replicaCount int = 1

@description('Number of partitions for scaling storage and indexing.')
param partitionCount int = 1

@description('Tags to apply to the resources.')
param tags object = {}

// Azure AI Search Service
resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: searchServiceName
  location: location
  tags: tags
  sku: {
    name: searchSku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'disabled'
    hostingMode: 'default'
    replicaCount: replicaCount
    partitionCount: partitionCount
    semanticSearch: 'standard'
    networkRuleSet: {
      ipRules: []
    }
  }
}

output id string = searchService.id

output name string = searchService.name

output endpoint string = 'https://${searchServiceName}.search.windows.net'

output principalId string = searchService.identity.principalId
