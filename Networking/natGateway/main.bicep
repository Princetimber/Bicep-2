@description('location of the resource')
param location string = resourceGroup().location

@description('name for the nat gateway')
param natGatewayName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}natgw'

@description('name of the public ip address')
param publicIpName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}pip'

@description('name of subnet to deploy the nat gateway in')
@allowed([
  'subnet1'
  'subnet2'
])
param subnetName string

@description('name of the virtual network to deploy the nat gateway in')
param virtualNetworkName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}vnet'

@description('name of the network security group to deploy the nat gateway in')
param networkSecurityGroupName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}nsg'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' existing = {
  name: networkSecurityGroupName
}
output nsgId string = nsg.id
resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: virtualNetworkName
}
output vnetId string = vnet.id
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: publicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: 'Standard'
  }
}
resource natGateway 'Microsoft.Network/natGateways@2023-06-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: publicIp.id
      }
    ]
    idleTimeoutInMinutes: 4
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}
resource natGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: '100.15.2.0/24'
    natGateway: {
      id: natGateway.id
    }
    networkSecurityGroup: {
      id: nsg.id
    }
    defaultOutboundAccess: true
  }
}

output natGatewayId string = natGateway.id
