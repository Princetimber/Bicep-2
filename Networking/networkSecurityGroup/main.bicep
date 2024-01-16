/*
 * Creates a network security group with the following rules:
 * - allow HTTPS inbound traffic
 * - allow HTTP inbound traffic
 * - allow RDP inbound traffic
 * - allow SSH inbound traffic
 * - allow WinRM inbound traffic
 * - allow DNS inbound traffic
 * - allow NTP inbound traffic
  * @param {string} suffix - suffix to append to the network security group name
  * @param {array} sourceAddressPrefixes - source address prefixes
  * @param {string} destinationAddressPrefix - destination address prefix
  * @param {string} location - location of the network security group
  * @param {string} name - name of the network security group
  *@output {string} nsgId - id of the network security group
  *@output {string} Name - name of the network security group
 */
@description('network security group location')
param location string = resourceGroup().location
@description('network security group name suffix')
param suffix string
@description('source address prefixes')
param sourceAddressPrefixes array
@description('destination address prefixe')
param destinationAddressPrefix string

var name = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}${suffix}'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: name
  location: location
  tags: {
    displayName: 'Network Security Group'
  }
  properties: {
    flushConnection: false
    securityRules: [
      {
        name: 'allow_https_inbound'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          priority: 200
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: destinationAddressPrefix
          destinationPortRange: '443'
          description: 'Allow HTTPS inbound traffic'
        }
      }
      {
        name: 'allow_http_inbound'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          priority: 201
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: destinationAddressPrefix
          destinationPortRange: '80'
          description: 'Allow HTTP inbound traffic'
        }
      }
      {
        name: 'allow_rdp_inbound'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          priority: 202
          sourceAddressPrefixes: sourceAddressPrefixes
          sourcePortRange: '*'
          destinationAddressPrefix: destinationAddressPrefix
          destinationPortRange: '3380-3400'
          description: 'Allow RDP inbound traffic'
        }
      }
      {
        name: 'allow_ssh_inbound'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          priority: 203
          sourceAddressPrefixes: sourceAddressPrefixes
          sourcePortRange: '*'
          destinationAddressPrefix: destinationAddressPrefix
          destinationPortRange: '22'
          description: 'Allow SSH inbound traffic'
        }
      }
      {
        name: 'allow_winrm_inbound'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          priority: 204
          sourceAddressPrefixes: sourceAddressPrefixes
          sourcePortRange: '*'
          destinationAddressPrefix: destinationAddressPrefix
          destinationPortRange: '5985'
          description: 'Allow WinRM inbound traffic'
        }
      }
      {
        name: 'allow_dns_inbound'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          priority: 205
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: destinationAddressPrefix
          destinationPortRange: '53'
          description: 'Allow DNS inbound traffic'
        }
      }
      {
        name: 'allow_ntp_inbound'
        properties: {
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Udp'
          priority: 206
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: destinationAddressPrefix
          destinationPortRange: '123'
          description: 'Allow NTP inbound traffic'
        }
      }
    ]
  }
}

output nsgId string = nsg.id
output Name string = nsg.name
