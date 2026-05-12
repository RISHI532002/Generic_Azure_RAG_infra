@description('Location for the Cosmos DB account.')
param location string = resourceGroup().location

@description('Name of the Cosmos DB account.')
param cosmosDbAccountName string

@description('Name of the Cosmos DB database.')
param databaseName string = 'chatdb'

@description('Name of the container for storing user chats.')
param containerName string = 'user_chat'

@description('Partition key path for the user chat container.')
param partitionKeyPath string = '/userId'

@description('Tags to apply to the Cosmos DB resources.')
param tags object = {}

// Cosmos DB Account (SQL API for JSON documents)
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: cosmosDbAccountName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    networkAclBypass: 'AzureServices'
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: true
      }
    ]
    disableLocalAuth: false
  }
}

// Database
resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmosDbAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

// Container for user chats
resource chatContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: database
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          partitionKeyPath
        ]
        kind: 'Hash'
      }
      defaultTtl: -1 // no expiry, chats persist indefinitely
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/_etag/?'
          }
        ]
      }
    }
  }
}

output id string = cosmosDbAccount.id

output name string = cosmosDbAccount.name

output endpoint string = cosmosDbAccount.properties.documentEndpoint

output databaseName string = database.name

output containerName string = chatContainer.name

output principalId string = cosmosDbAccount.identity.principalId
