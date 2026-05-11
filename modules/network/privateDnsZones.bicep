param vnetId string

param vnetName string

var dnsZones = [
  'privatelink.azurewebsites.net'        // App Service & Function App
  'privatelink.azurecr.io'               // Container Registry
  'privatelink.openai.azure.com'          // Azure OpenAI
  'privatelink.search.windows.net'       // AI Search
  'privatelink.blob.${environment().suffixes.storage}' // Blob Storage
  'privatelink.documents.azure.com'      // Cosmos DB (SQL API)
  'privatelink.vaultcore.azure.net'      // Key Vault
]


resource privateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [
  for zone in dnsZones: {
    name: zone
    location: 'global'
  }
]

resource vnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [
  for (zone, i) in dnsZones: {
    parent: privateDnsZones[i]
    name: '${vnetName}-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {id: vnetId}
    }
  }
]

output dnsZoneIds array = [ for (zone, i) in dnsZones: {
  name: zone
  id: privateDnsZones[i].id
}]
