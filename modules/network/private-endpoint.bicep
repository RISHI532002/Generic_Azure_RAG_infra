@description('The location where the private endpoint will be created.')
param location string = resourceGroup().location

@description('The name of the private endpoint to be created.')
param endpointName string

@description('The ID of the resource to which the private endpoint will connect.')
param serviceId string

@description('The name of the group ID for the private link service connection.')
param subnetId string

@description('The ID of the private DNS zone to link to the private endpoint.')
param dnsZoneId string

@description('The name of the group ID for the private link service connection.')
param groupId string

@description('Tags to be applied to the private endpoint.')
param tags object = {}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: endpointName
  location: location
  tags: tags
  properties: {
    subnet: { id: subnetId }
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
        name: replace(dnsZoneId, '/', '-')
        properties: {
          privateDnsZoneId: dnsZoneId
        }
      }
    ]
  }
}

output privateEndpointId string = privateEndpoint.id

output networkInterfaceId string = privateEndpoint.properties.networkInterfaces[0].id
