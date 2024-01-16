param location string = resourceGroup().location
module kv '../keyVaults/main.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    objectId: ''
    publicIpAddress: ''
    secretName: ''
    secretValue: ''
    keyVaultName: ''
    tenantId: ''
    vnetName: ''
  }
}
