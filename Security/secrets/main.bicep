@description('Required: key vault name')
@minLength(3)
@maxLength(24)
param keyVaultName string = 'kv${uniqueString(resourceGroup().id)}'

@description('Required: secret name')
param secretName string

@description('Required: secret value')
@secure()
param secretValue string

@description('Required: secret content type')
@secure()
@allowed([
  'text/plain'
])
param secretContentType string

@description('required: expiry date for the secret since epoch. since 1970-01-01T00:00:00Z')
param secretExp int

@description('optional: not before date for the secret since epoch. since 1970-01-01T00:00:00Z')
param secretNbf int

@description('optional: tags')
param tags object = {
  environment: 'dev'
  department: 'engineering'
}

@description('required: location')
param location string = resourceGroup().location

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: secretName
  properties: {
    value: secretValue
    contentType: secretContentType
    attributes: {
      enabled: true
      exp: secretExp
      nbf: secretNbf
    }
  }
  parent: kv
  tags: tags
}

output secretId string = secret.id
output secretName string = secret.name
output secretValue string = secret.properties.value

resource sshKey 'Microsoft.Compute/sshPublicKeys@2023-09-01' = {
  name: 'mySshKey'
  location: location
  properties: {
    publicKey: ''
  }
}
