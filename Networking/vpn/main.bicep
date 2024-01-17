@description('The name of the VPN connection.')
param connectionName string

@description('The name of the virtual network gateway.')
param vnetGatewayName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}vnetgw'

@description('The name of the local network gateway.')
param localNetworkGatewayName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}localgw'

@description('The shared key for the VPN connection.')
param sharedKey string

@description('The location of the VPN connection.')
param location string = resourceGroup().location

@description('The tags of the VPN connection.')
param tags object = {
  displayName: 'vpnConnection'
  environment: 'dev'
}

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
      properties: {
        localNetworkAddressSpace: {
          addressPrefixes: [ resourceId('Microsoft.Network/LocalNetworkGateways', localNetworkGatewayName, 'addressPrefixes') ]
        }
      }
    }
    sharedKey: sharedKey
    enableBgp: false
    routingWeight: 0
  }
}
