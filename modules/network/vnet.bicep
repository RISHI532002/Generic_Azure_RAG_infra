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

resource appIntegrationNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${vnetName}-app-integration-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsOutbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
    ]
  }
}

resource appPrivateEndpointNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${vnetName}-app-pe-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowVNetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource privateEndpointNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${vnetName}-pe-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAppSubnetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: appIntegrationSubnetPrefix // only from app subnet
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

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
          networkSecurityGroup: {
            id: appIntegrationNsg.id
          }
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
          networkSecurityGroup: {
            id: appPrivateEndpointNsg.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }

      // Shared Private Endpoint SUbnet
      // Storage, OpenAI, Cosmos
      {
        name: 'private-endpoint-subnet'
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
          networkSecurityGroup: {
            id: privateEndpointNsg.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

output vnetId string = vnet.id

output vnetName string = vnet.name

output appIntegrationSubnetId string = vnet.properties.subnets[0].id

output appPrivateEndpointSubnetId string = vnet.properties.subnets[1].id

output privateEndpointSubnetId string = vnet.properties.subnets[2].id
