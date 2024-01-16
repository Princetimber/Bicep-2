/*
  *  Created on: 2024-01-15
  *      Author: Olamide Olaleye
  *      Purpose: This is the header file for the class that will be used to create the private DNS Zone in Azure.
  *      Language: Azure Bicep, ARM Template
  *      Tools: VS Code, AZ CLI

*/
@description('The name of the private DNS zone to create.')
param privateDnsZoneName string
@description('Check if the VMs should be registered in the private DNS zone. Expected values are true or false.')
param autoVmRegistration bool = true
@description('The name suffix of the virtual network to create.')
param vnetNameSuffix string
param tags object = {
  Environment: 'Dev'
}
param location string = 'Global'

var vnetName = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}${vnetNameSuffix}'
resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetName
  scope: resourceGroup()
}
output vnetId string = vnet.id
resource privateDnszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: location
  tags: tags
}
output privateDnszoneId string = privateDnszone.id
output privateDnszoneName string = privateDnszone.name

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnszone
  name: '${privateDnszone.name}-link'
  properties: {
    registrationEnabled: autoVmRegistration
    virtualNetwork: {
      id: vnet.id
    }
  }
  tags: tags
}
