@description('Location for the Function App resources.')
param location string = resourceGroup().location

@description('Name of the App Service Plan for the Function App.')
param appServicePlanName string

@description('Name of the Function App.')
param functionAppName string

@description('SKU for the App Service Plan.')
param appServicePlanSku string = 'P1v3'

@description('Subnet ID for VNet integration (outbound traffic).')
param appIntegrationSubnetId string

@description('Storage account connection string for Function App runtime.')
param storageAccountConnectionString string

@description('Storage account name where blob triggers will listen for new documents.')
param blobStorageAccountName string

@description('Blob container name to monitor for new documents.')
param blobContainerName string = 'documents'

@description('Tags to apply to the resources.')
param tags object = {}

// App Service Plan (Linux, Elastic Premium for VNet-integrated Functions)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: true
  }
}

// Function App (Python code, blob-triggered)
// Code will be deployed via Azure DevOps pipeline
resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    publicNetworkAccess: 'Disabled'
    httpsOnly: true
    virtualNetworkSubnetId: appIntegrationSubnetId
    vnetRouteAllEnabled: true
    siteConfig: {
      linuxFxVersion: 'Python|3.11'
      alwaysOn: true
      ftpsState: 'Disabled'
      http20Enabled: true
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageAccountConnectionString
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'BLOB_STORAGE_ACCOUNT_NAME'
          value: blobStorageAccountName
        }
        {
          name: 'BLOB_CONTAINER_NAME'
          value: blobContainerName
        }
      ]
    }
  }
}

output id string = functionApp.id

output name string = functionApp.name

output defaultHostName string = functionApp.properties.defaultHostName

output principalId string = functionApp.identity.principalId
