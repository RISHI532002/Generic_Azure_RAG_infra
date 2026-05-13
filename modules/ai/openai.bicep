@description('Location for the Azure OpenAI resource.')
param location string = resourceGroup().location

@description('Name of the Azure OpenAI account.')
param openAiName string

@description('SKU for the Azure OpenAI account.')
param openAiSku string = 'S0'

@description('Name of the GPT model deployment.')
param modelDeploymentName string = 'gpt-51'

@description('GPT model name to deploy.')
param modelName string = 'gpt-5.1'

@description('Model version.')
param modelVersion string = '2025-04-01'

@description('Model deployment capacity (TPM in thousands).')
param modelCapacity int = 20

@description('Tags to apply to the resources.')
param tags object = {}

// Azure OpenAI Account
resource openAi 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: location
  tags: tags
  kind: 'OpenAI'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: openAiSku
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
    }
    disableLocalAuth: true
  }
}

// GPT Model Deployment
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAi
  name: modelDeploymentName
  sku: {
    name: 'Standard'
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
  }
}

output id string = openAi.id

output name string = openAi.name

output endpoint string = openAi.properties.endpoint

output principalId string = openAi.identity.principalId

output modelDeploymentName string = modelDeployment.name
