/*
  * Creates a virtual network
  * @param {string} location - resource group location
  * @param {string} vnetSuffix - virtual network name suffix
  * @param {string} nsgSuffix - nsg name suffix
  * @param {array} vnetAddressPrefixes - virtual network address prefixes
  * @param {array} subnets - virtual network subnets
  * @param {object} tags - virtual network tags
  * @param {string} vnetNewOrExisting - specify whether to create new or existing virtual network
  * @var {string} vnetName - virtual network name
  * @var {string} nsgName - nsg name
  * @var {string} nsgId - nsg id
  * @output {string} vnetId - virtual network id
  * @output {string} vnetName - virtual network name
*/
@description('resource group location')
param location string = resourceGroup().location
@description('virtual network name suffix')
param vnetSuffix string
@description('nsg name suffix')
param nsgSuffix string
@description('virtual network address prefixes')
param vnetAddressPrefixes array
@description('virtual network subnets')
param subnets array
@description('virtual network tags')
param tags object = {
  environment: 'dev'
}
@description('specifiy DNS servers')
param dnsServers array
@description('specify whether to create new or existing virtual network')
@allowed([
  'new'
  'existing'
])
param vnetNewOrExisting string

var vnetName = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}${vnetSuffix}'
var nsgName = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}${nsgSuffix}'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' existing = {
  name: nsgName
}
var nsgId = nsg.id

resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' = if (vnetNewOrExisting == 'new') {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    subnets: [
    for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        serviceEndpoints: [
          {
            service: 'Microsoft.Storage'
          }
          {
            service: 'Microsoft.keyvault'
          }
          {
            service: 'Microsoft.Sql'
          }
          {
            service: 'Microsoft.AzureActiveDirectory'
          }
          {
            service: 'Microsoft.web'
          }
          {
            service: 'Microsoft.ContainerRegistry'
          }
        ]
        networkSecurityGroup: subnet.name != 'gatewaySubnet' ? {
          id: nsgId
        } : null
      }
    }
    ]
    enableDdosProtection: false
    enableVmProtection: true
    dhcpOptions: {
      dnsServers: dnsServers
    }
  }
}
output vnetId string = vnet.id
output vnetName string = vnet.name
