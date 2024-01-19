@description('The suffix of the storage account name.')
@minLength(3)
@maxLength(24)
param storageAccountName string = '${uniqueString(resourceGroup().id)}stga'

@description('Storage SKU.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Standard_GZRS'
  'Standard_RAGRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param sku string = 'Standard_LRS'

@description('storage kind.')
@allowed([ 'Storage', 'StorageV2', 'BlobStorage', 'FileStorage', 'BlockBlobStorage' ])
param storageAccountKind string

@description('storage access tier.')
@allowed([ 'Hot', 'Cool' ])
param storageAccountAccessTier string

@description('resource location.')
param location string = resourceGroup().location

@description('resource tags.')
param tags object = {
  environment: 'dev'
  displayName: 'storage account'
}

@description('Required: The valuse of the publicIpAddress allowed to access the storage account.')
param publicIpAddress string

var vnetName = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}vnet'
resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: storageAccountKind
  sku: {
    name: sku
  }
  properties: {
    accessTier: storageAccountAccessTier
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowCrossTenantReplication: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: '${vnet.id}/subnets/gatewaySubnet'
          action: 'Allow'
          state: 'Succeeded'
        }
        {
          id: '${vnet.id}/subnets/subnet1'
          action: 'Allow'
          state: 'Succeeded'
        }
        {
          id: '${vnet.id}/subnets/subnet2'
          action: 'Allow'
          state: 'Succeeded'
        }
      ]
      ipRules: [
        {
          value: publicIpAddress
          action: 'Allow'
        }
      ]
    }
    isNfsV3Enabled: false
    largeFileSharesState: 'Enabled'
    allowSharedKeyAccess: true
    isLocalUserEnabled: true
    keyPolicy: {
      keyExpirationPeriodInDays: 365
    }
    immutableStorageWithVersioning: {
      enabled: true
      immutabilityPolicy: {
        immutabilityPeriodSinceCreationInDays: 90
        allowProtectedAppendWrites: true
        state: 'Unlocked'
      }
    }
  }
  tags: tags
}
