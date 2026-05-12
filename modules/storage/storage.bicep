@description('Location for the storage account.')
param location string = resourceGroup().location

@description('Name of the storage account.')
param storageAccountName string

@description('SKU for the storage account. Defaults to Standard_ZRS for zone redundancy.')
param storageSku string = 'Standard_ZRS'

@description('Tags to apply to the storage account.')
param tags object = {}

@description('Retention days for soft-deleted blobs.')
param blobSoftDeleteRetentionDays int = 7

@description('Retention days for soft-deleted containers.')
param containerSoftDeleteRetentionDays int = 7

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: blobSoftDeleteRetentionDays
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: containerSoftDeleteRetentionDays
    }
  }
}

output id string = storage.id

output name string = storage.name

output primaryBlobEndpoint string = storage.properties.primaryEndpoints.blob
