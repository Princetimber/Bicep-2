@description('key vault name')
param keyVaultName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}kv'

@description('virtual network name')
param vnetName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}vnet'

@description('subnet name')
param secretName string

@description('secret value')
@secure()
param secretValue string

@description('resource location')
param location string = resourceGroup().location

@description('resource tenantId')
param tenantId string = subscription().tenantId

@description('public ip address for the local network.')
param publicIpAddress string

@description('azure AD object id for user or group.')
param objectId string

param tags object = {
  environment: 'dev'
  displayName: 'keyvault'
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetName
}
var rules = [
  {
    id: '${vnet.id}/subnets/gatewaySubnet'
  }
  {
    id: '${vnet.id}/subnets/subnet1'
  }
  {
    id: '${vnet.id}/subnets/subnet2'
  }
]

resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: objectId
        permissions: {
          secrets: [
            'all'
          ]
          certificates: [
            'all'
          ]
          keys: [
            'all'
          ]
          storage: [
            'all'
          ]
        }
      }
    ]
    createMode: 'default'
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enableRbacAuthorization: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        {
          value: publicIpAddress
        }
      ]
      virtualNetworkRules: [
      for rule in rules: {
        id: rule.id
        ignoreMissingVnetServiceEndpoint: false
      }
      ]
    }
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyvault
  name: secretName
  properties: {
    value: secretValue
    attributes: {
      enabled: true
      exp: 31536000 // 1 year in seconds
      nbf: 86400 // 1 day in seconds
    }
    contentType: 'text/plain'
  }
}
