@description('The public IP address of the local gateway.')
param localGatewayPublicIpAddress string

@description('The name of the local gateway.')
param localGatewayName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}lgw'

@description('The name for the virtual network.')
param vnetName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}vnet'

@description('The name for the virtual network gateway to be created.')
param vnetGatewayName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}vnetgw'

@description('The name the public IP address to be created.')
param PublicIpName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}pubIpGW'

@description('The name of the resource group to create the local gateway in.')
param location string = resourceGroup().location

@description('The address prefixes of the local gateway.')
param addressPrefixes array

@description('The name of the subnet where the virtual network gateway will be created.')
@allowed([
  'gatewaySubnet'
])
param subnetName string

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2023-06-01' = {
  name: localGatewayName
  location: location
  properties: {
    gatewayIpAddress: localGatewayPublicIpAddress
    localNetworkAddressSpace: {
      addressPrefixes: addressPrefixes
    }
  }
}
output localGatewayId string = localNetworkGateway.id
output localGatewayName string = localNetworkGateway.name
output AddressSpace array = localNetworkGateway.properties.localNetworkAddressSpace.addressPrefixes
output localGatewayIp string = localNetworkGateway.properties.gatewayIpAddress

resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetName
}
var subnetid = '${vnet.id}/subnets/${subnetName}'
resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: PublicIpName
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
  }
}
resource vnetGateway 'Microsoft.Network/virtualNetworkGateways@2023-06-01' = {
  name: vnetGatewayName
  location: location
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation2'
    sku: {
      name: 'VpnGw2'
      tier: 'VpnGw2'
    }
    ipConfigurations: [
      {
        name: PublicIpName
        id: publicIpAddress.id
        properties: {
          publicIPAddress: {
            id: publicIpAddress.id
          }
          subnet: {
            id: subnetid
          }
        }
      }

    ]
  }
}
