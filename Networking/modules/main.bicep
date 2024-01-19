/*
  * @title: Bicep - Virtual Network with Network Security Group
  * @description: Create a virtual network with an associated network security group
  * @tags: [network, virtual network, network security group]
  * @date: 2024-01-12
  * @version: v0.1.0
  * The virtual network and network security group are created in the same resource group
  * The virtual network is created with three subnets and a gateway subnet
  * The network security group is created with 5 inbound security rules for https, http, ssh, rdp, and winrm
  * @param location string = The location for the virtual network and network security group
  * @param nsgSuffix string = The suffix for the network security group
  * @param vnetSuffix string = The suffix for the virtual network
  * @param vnetNewOrExisting string = Whether to create a new virtual network or use an existing virtual network
  * @param vnetAddressPrefixes array = The address prefixes for the virtual network
  * @param subnets array = The subnets for the virtual network
  * @param dnsServers array = The DNS servers for the virtual network
  * @param destinationAddressPrefix string = The destination address prefix for the network security group
  * @param sourceAddressPrefixes array = The source address prefixes for the network security group
  * @param suffix string = The suffix for the network security group
  * @output nsgId string = The id of the network security group
  * @output nsgName string = The name of the network security group
  * @output vnetId string = The id of the virtual network
  * @output vnetName string = The name of the virtual network
*/
targetScope = 'resourceGroup'
param location string = resourceGroup().location
module nsg '../networkSecurityGroup/main.bicep' = {
  name: 'network-security-group'
  params: {
    location: location
    destinationAddressPrefix: 'virtualNetwork'
    sourceAddressPrefixes: [
      '65.31.74.157/32'
      '10.0.1.0/28'
      '10.0.4.0/24'
    ]
  }
}
output nsgId string = nsg.outputs.nsgId
output nsgName string = nsg.outputs.Name

module vnet '../virtualNetworks/main.bicep' = {
  name: 'virtual-network'
  params: {
    location: location
    vnetNewOrExisting: 'new'
    vnetAddressPrefixes: [
      '100.16.0.0/16'
    ]
    subnets: [
      {
        name: 'gatewaySubnet'
        addressPrefix: '100.16.0.0/27'
      }
      {
        name: 'subnet1'
        addressPrefix: '100.16.1.0/24'
      }
      {
        name: 'subnet2'
        addressPrefix: '100.16.2.0/24'
      }
    ]
    dnsServers: [
      '10.0.3.2'
      '10.0.3.3'
    ]
  }
  dependsOn: [
    nsg
  ]
}
output vnetId string = vnet.outputs.vnetId
output vnetName string = vnet.outputs.vnetName

module natgateway '../natGateway/main.bicep' = {
  name: 'nat-gateway'
  params: {
    location: location
  }
  dependsOn: [
    vnet
  ]
}
output natGatewayId string = natgateway.outputs.natGatewayId

module privateDNS '../privateDNS/main.bicep' = {
  name: 'privatednszone'
  params: {
    privateDnsZoneName: 'intheclouds365.com'
    location: 'Global'
    autoVmRegistration: true
  }
  dependsOn: [
    vnet
  ]
}
output pDNSName string = privateDNS.outputs.privateDnszoneName
output pDNSId string = privateDNS.outputs.privateDnszoneId

module gateways '../gateway/main.bicep' = {
  name: 'lg-vg-gateways'
  params: {
    location: location
    addressPrefixes: [
      '10.0.1.0/29'
      '10.0.4.0/24'
    ]
    localGatewayPublicIpAddress: '62.31.74.157'
    subnetName: 'gatewaySubnet'
  }
  dependsOn: [
    vnet
  ]
}
module vpnConnection '../vpn/main.bicep' = {
  name: 'vpn-Connection'
  dependsOn: [
    gateways
    vnet
  ]
  params: {
    connectionName: 'azure-pfsense-vpn'
    sharedKey: 'KZ@f$iYR8bbxa@w$tct5jDCe%Y@@g89&c#'
    location: location
  }
}
