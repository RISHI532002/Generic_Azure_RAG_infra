@description('Location for all resources')
param location string

@description('VNet name')
param vnetName string

@description('Address space for VNet')
param vnetAddressPrefix string

@description('Subnet for App Service outbound VNet integration')
param appIntegrationSubnetPrefix string

@description('Subnet for App service private endpoints')
param appPrivateEndpointSubnetPrefix string

@description('Subnet for private endpoints of PaaS resources')
param privateEndpointSubnetPrefix string


resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location

  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }

    subnets: [

      // App service VNet Integration Subnet
      // Used for outbound traffic
      {
        name: 'app-integration-subnet'
        properties: {
          addressPrefix: appIntegrationSubnetPrefix
          delegations: [
            {
              name: 'appServiceDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }

      // App service private endpoint subnet
      // Used for inbound private access
      {
        name: 'app-private-endpoint-subnet'
        properties: {
          addressPrefix: appPrivateEndpointSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }

      // Shared Prvate Endpoint SUbnet
      // Storage, OpenAI, Cosmos
      {
        name: 'private-endpoint-subnet'
        properties: {
          addressPrefix: privateEndpointSubnetPrefix

          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

output vnetId string = vnet.id

output vnetName string = vnet.name

output appIntegrationSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  'app-integration-subnet'
)

output appPrivateEndpointSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  'app-private-endpoint-subnet'
)

output privateEndpointSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  'private-endpoint-subnet'
)
