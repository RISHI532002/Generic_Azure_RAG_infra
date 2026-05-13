targetScope = 'resourceGroup'

@description('Location for all resources.')
param location string = resourceGroup().location

// ---- VNet Parameters ----
@description('Name of the Virtual Network.')
param vnetName string

@description('Address space for the VNet.')
param vnetAddressPrefix string

@description('Subnet prefix for App Service VNet integration (outbound).')
param appIntegrationSubnetPrefix string

@description('Subnet prefix for App Service private endpoints (inbound).')
param appPrivateEndpointSubnetPrefix string

@description('Subnet prefix for PaaS private endpoints.')
param privateEndpointSubnetPrefix string

// ---- Phase 1: VNet ----
module vnet 'modules/network/vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    location: location
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    appIntegrationSubnetPrefix: appIntegrationSubnetPrefix
    appPrivateEndpointSubnetPrefix: appPrivateEndpointSubnetPrefix
    privateEndpointSubnetPrefix: privateEndpointSubnetPrefix
  }
}

// ---- Phase 2: Private DNS Zones ----
module privateDnsZones 'modules/network/privateDnsZones.bicep' = {
  name: 'dns-zones-deployment'
  params: {
    vnetId: vnet.outputs.vnetId
    vnetName: vnet.outputs.vnetName
  }
}

// ---- Phase 3: Backend Services ----

// Storage Account Parameters
@description('Name of the Storage Account.')
param storageAccountName string

// ACR Parameters
@description('Name of the Azure Container Registry.')
param acrName string

// Cosmos DB Parameters
@description('Name of the Cosmos DB account.')
param cosmosDbAccountName string

// OpenAI Parameters
@description('Name of the Azure OpenAI account.')
param openAiName string

// AI Search Parameters
@description('Name of the Azure AI Search service.')
param searchServiceName string

// Document Intelligence Parameters
@description('Name of the Document Intelligence account.')
param documentIntelligenceName string

module storage 'modules/storage/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    location: location
    storageAccountName: storageAccountName
  }
}

module acr 'modules/compute/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    location: location
    acrName: acrName
  }
}

module cosmosDb 'modules/database/cosmosdb.bicep' = {
  name: 'cosmosdb-deployment'
  params: {
    location: location
    cosmosDbAccountName: cosmosDbAccountName
  }
}

module openAi 'modules/ai/openai.bicep' = {
  name: 'openai-deployment'
  params: {
    location: location
    openAiName: openAiName
  }
}

module aiSearch 'modules/ai/aiSearch.bicep' = {
  name: 'ai-search-deployment'
  params: {
    location: location
    searchServiceName: searchServiceName
  }
}

module docIntelligence 'modules/ai/documentIntelligence.bicep' = {
  name: 'doc-intelligence-deployment'
  params: {
    location: location
    documentIntelligenceName: documentIntelligenceName
  }
}

// ---- Phase 4: Compute ----

// App Service Parameters
@description('Name of the App Service Plan for the frontend.')
param appServicePlanName string

@description('Name of the frontend App Service.')
param appName string

// Function App Parameters
@description('Name of the App Service Plan for the Function App.')
param functionAppServicePlanName string

@description('Name of the Function App.')
param functionAppName string

// Reference deployed storage account to get connection string
resource storageRef 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

module frontendApp 'modules/compute/appService.bicep' = {
  name: 'app-service-deployment'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    appName: appName
    appIntegrationSubnetId: vnet.outputs.appIntegrationSubnetId
    acrLoginServer: acr.outputs.loginServer
  }
}

module embeddingFunc 'modules/compute/functionApp.bicep' = {
  name: 'function-app-deployment'
  params: {
    location: location
    appServicePlanName: functionAppServicePlanName
    functionAppName: functionAppName
    appIntegrationSubnetId: vnet.outputs.appIntegrationSubnetId
    storageAccountConnectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageRef.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    blobStorageAccountName: storage.outputs.name
  }
}

// ---- Phase 5: Private Endpoints ----

// Storage - Blob
module storagePe 'modules/network/private-endpoint.bicep' = {
  name: 'storage-pe-deployment'
  params: {
    location: location
    endpointName: '${storageAccountName}-pe'
    serviceId: storage.outputs.id
    subnetId: vnet.outputs.privateEndpointSubnetId
    dnsZoneId: privateDnsZones.outputs.dnsZoneIds[4].id
    groupId: 'blob'
  }
}

// ACR
module acrPe 'modules/network/private-endpoint.bicep' = {
  name: 'acr-pe-deployment'
  params: {
    location: location
    endpointName: '${acrName}-pe'
    serviceId: acr.outputs.id
    subnetId: vnet.outputs.privateEndpointSubnetId
    dnsZoneId: privateDnsZones.outputs.dnsZoneIds[1].id
    groupId: 'registry'
  }
}

// Cosmos DB
module cosmosDbPe 'modules/network/private-endpoint.bicep' = {
  name: 'cosmosdb-pe-deployment'
  params: {
    location: location
    endpointName: '${cosmosDbAccountName}-pe'
    serviceId: cosmosDb.outputs.id
    subnetId: vnet.outputs.privateEndpointSubnetId
    dnsZoneId: privateDnsZones.outputs.dnsZoneIds[5].id
    groupId: 'Sql'
  }
}

// Azure OpenAI
module openAiPe 'modules/network/private-endpoint.bicep' = {
  name: 'openai-pe-deployment'
  params: {
    location: location
    endpointName: '${openAiName}-pe'
    serviceId: openAi.outputs.id
    subnetId: vnet.outputs.privateEndpointSubnetId
    dnsZoneId: privateDnsZones.outputs.dnsZoneIds[2].id
    groupId: 'account'
  }
}

// AI Search
module aiSearchPe 'modules/network/private-endpoint.bicep' = {
  name: 'ai-search-pe-deployment'
  params: {
    location: location
    endpointName: '${searchServiceName}-pe'
    serviceId: aiSearch.outputs.id
    subnetId: vnet.outputs.privateEndpointSubnetId
    dnsZoneId: privateDnsZones.outputs.dnsZoneIds[3].id
    groupId: 'searchService'
  }
}

// Document Intelligence
module docIntelligencePe 'modules/network/private-endpoint.bicep' = {
  name: 'doc-intelligence-pe-deployment'
  params: {
    location: location
    endpointName: '${documentIntelligenceName}-pe'
    serviceId: docIntelligence.outputs.id
    subnetId: vnet.outputs.privateEndpointSubnetId
    dnsZoneId: privateDnsZones.outputs.dnsZoneIds[7].id
    groupId: 'account'
  }
}

// App Service (frontend)
module frontendAppPe 'modules/network/private-endpoint.bicep' = {
  name: 'app-service-pe-deployment'
  params: {
    location: location
    endpointName: '${appName}-pe'
    serviceId: frontendApp.outputs.id
    subnetId: vnet.outputs.appPrivateEndpointSubnetId
    dnsZoneId: privateDnsZones.outputs.dnsZoneIds[0].id
    groupId: 'sites'
  }
}

// Function App (embeddings)
module embeddingFuncPe 'modules/network/private-endpoint.bicep' = {
  name: 'function-app-pe-deployment'
  params: {
    location: location
    endpointName: '${functionAppName}-pe'
    serviceId: embeddingFunc.outputs.id
    subnetId: vnet.outputs.appPrivateEndpointSubnetId
    dnsZoneId: privateDnsZones.outputs.dnsZoneIds[0].id
    groupId: 'sites'
  }
}

// ---- Phase 6: Role Assignments ----

// Role definition IDs
var acrPullRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)
var storageBlobDataReaderRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
)
var cognitiveServicesOpenAiUserRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
)
var cognitiveServicesUserRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'a97b65f3-24c7-4388-baec-2e87135dc908'
)
var searchIndexDataContributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
)
var searchIndexDataReaderRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '1407120a-92aa-4202-b7e9-c0e197c71c8f'
)

// Existing resource references for scoping role assignments
resource acrRef 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource openAiRef 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: openAiName
}

resource searchRef 'Microsoft.Search/searchServices@2024-06-01-preview' existing = {
  name: searchServiceName
}

resource docIntelligenceRef 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: documentIntelligenceName
}

// 1. App Service → ACR (AcrPull) - pull Docker images
resource appServiceAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrName, appName, 'acrpull')
  scope: acrRef
  properties: {
    roleDefinitionId: acrPullRoleId
    principalId: frontendApp.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// 2. Function App → Storage (Storage Blob Data Reader) - read blobs for trigger
resource funcStorageBlobReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccountName, functionAppName, 'blobreader')
  scope: storageRef
  properties: {
    roleDefinitionId: storageBlobDataReaderRoleId
    principalId: embeddingFunc.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// 3. App Service → OpenAI (Cognitive Services OpenAI User) - call GPT API
resource appServiceOpenAiUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openAiName, appName, 'openaiuser')
  scope: openAiRef
  properties: {
    roleDefinitionId: cognitiveServicesOpenAiUserRoleId
    principalId: frontendApp.outputs.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [openAi]
}

// 4. Function App → OpenAI (Cognitive Services OpenAI User) - create embeddings
resource funcOpenAiUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openAiName, functionAppName, 'openaiuser')
  scope: openAiRef
  properties: {
    roleDefinitionId: cognitiveServicesOpenAiUserRoleId
    principalId: embeddingFunc.outputs.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [openAi]
}

// 5. Function App → Document Intelligence (Cognitive Services User) - extract text from documents
resource funcDocIntelligenceUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(documentIntelligenceName, functionAppName, 'coguser')
  scope: docIntelligenceRef
  properties: {
    roleDefinitionId: cognitiveServicesUserRoleId
    principalId: embeddingFunc.outputs.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [docIntelligence]
}

// 6. Function App → AI Search (Search Index Data Contributor) - write embeddings to index
resource funcSearchContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchServiceName, functionAppName, 'searchcontributor')
  scope: searchRef
  properties: {
    roleDefinitionId: searchIndexDataContributorRoleId
    principalId: embeddingFunc.outputs.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [aiSearch]
}

// 7. App Service → AI Search (Search Index Data Reader) - query search index
resource appServiceSearchReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchServiceName, appName, 'searchreader')
  scope: searchRef
  properties: {
    roleDefinitionId: searchIndexDataReaderRoleId
    principalId: frontendApp.outputs.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [aiSearch]
}
