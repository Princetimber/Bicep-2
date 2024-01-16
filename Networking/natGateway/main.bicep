@description('location of the resource')
param location string = resourceGroup().location
@description('name suffix for the nat gateway')
param nameSuffix string
@description('name suffix of the public ip address')
param publicIpNameSuffix string
@description('name of subnet to deploy the nat gateway in')
param subnetName string
@description('name suffix of the virtual network to deploy the nat gateway in')
param virtualNetworkNameSuffix string
@description('name suffix of the network security group to deploy the nat gateway in')
param networkSecurityGroupNameSuffix string

var resourceGroupName = toLower(replace(resourceGroup().name, 'uksouthrg', ''))
var natGatewayName = '${resourceGroupName}${nameSuffix}'
var publicIpName = '${resourceGroupName}${publicIpNameSuffix}'
var virtualNetworkName = '${resourceGroupName}${virtualNetworkNameSuffix}'
var networkSecurityGroupName = '${resourceGroupName}${networkSecurityGroupNameSuffix}'

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
