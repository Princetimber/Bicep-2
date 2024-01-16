@description('The name of the VPN connection.')
param connectionName string
param vnetgatewayNameSuffix string
param localNetworkGatewayNameSuffix string
@description('The shared key for the VPN connection.')
param sharedKey string
param location string = resourceGroup().location
param tags object = {
  displayName: 'vpnConnection'
  environment: 'dev'
}

var vnetGatewayName = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}${vnetgatewayNameSuffix}'
var localNetworkGatewayName = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}${localNetworkGatewayNameSuffix}'

resource vnetGateway 'Microsoft.Network/virtualNetworkGateways@2023-06-01' existing = {
  name: vnetGatewayName
}

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2023-06-01' existing = {
  name: localNetworkGatewayName
}

resource vpnConnection 'Microsoft.Network/connections@2023-06-01' = {
  name: connectionName
  location: location
  tags: tags
  properties: {
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    virtualNetworkGateway1: {
      id: vnetGateway.id
      location: location
      properties: {
        gatewayType: 'Vpn'
        vpnType: 'RouteBased'
        vpnGatewayGeneration: 'Generation2'
        sku: {
          name: 'VpnGw2'
          tier: 'VpnGw2'
        }
      }
    }
    localNetworkGateway2: {
      id: localNetworkGateway.id
      location: location
      tags: tags
      properties:{
        localNetworkAddressSpace:{
            addressPrefixes: [resourceId('Microsoft.Network/LocalNetworkGateways', localNetworkGatewayName, 'addressPrefixes')]
        }
      }
    }
    sharedKey: sharedKey
    enableBgp: false
    routingWeight: 0
  }
}
