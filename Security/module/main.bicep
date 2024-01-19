param location string = resourceGroup().location
module kv '../keyVaults/main.bicep' = {
  name: 'key-vault'
  params: {
    location: location
    objectId: '327d7e46-06a8-49a2-8749-515bb47e6d20'
    publicIpAddress: '62.31.74.157'
    secretName: 'adminPassphraseKey'
    secretValue: 'EaVc&kK5uu4$V*6N9$D&5oM*Z2BV95nu4s'
    tenantId: '93fb203c-ab10-44a3-a9fe-05ac5b6e4cb9'
  }
}
