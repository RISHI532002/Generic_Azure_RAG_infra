param location string
param endpointName string
param serviceId string
param subnetId string
param dnsZoneId string
param groupId string


resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: endpointName
  location: location
  properties: {
    subnet: {id: subnetId}
    privateLinkServiceConnections: [
      {
        name: endpointName
        properties: {
          privateLinkServiceId: serviceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: dnsZoneId
        }
      }
    ]
  }
}
