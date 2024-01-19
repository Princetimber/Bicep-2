param location string = resourceGroup().location
module kv '../keyVaults/main.bicep' = {
  name: 'key-vault'
  params: {
    location: location
    objectId: ''
    publicIpAddress: ''
    secretName: 'adminPassphraseKey'
    secretValue: ''
    tenantId: ''
  }
}
