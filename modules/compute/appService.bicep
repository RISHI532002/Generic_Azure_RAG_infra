@description('Location for the App Service resources.')
param location string = resourceGroup().location

@description('Name of the App Service Plan.')
param appServicePlanName string

@description('Name of the App Service (Web App).')
param appName string

@description('SKU for the App Service Plan.')
param appServicePlanSku string = 'P1v3'

@description('Subnet ID for VNet integration (outbound traffic).')
param appIntegrationSubnetId string

@description('ACR login server URL (e.g., myacr.azurecr.io).')
param acrLoginServer string

@description('Tags to apply to the resources.')
param tags object = {}

// App Service Plan (Linux for Docker containers)
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

// App Service (Web App for Containers)
// Docker image will be deployed via Azure DevOps pipeline
resource app 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  tags: tags
  kind: 'app,linux,container'
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
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest' // placeholder, pipeline will update
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      ftpsState: 'Disabled'
      http20Enabled: true
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
    }
  }
}

output id string = app.id

output name string = app.name

output defaultHostName string = app.properties.defaultHostName

output principalId string = app.identity.principalId
