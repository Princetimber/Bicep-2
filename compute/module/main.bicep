param location string = resourceGroup().location
param keyVaultName string = 'kv${uniqueString(resourceGroup().id)}'
param keyVaultSecretName string = 'adminPassphraseKey'
param secretName string = 'passphraseKey'
resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}
module storage '../storage/main.bicep' = {
  name: 'storageAccount'
  params: {
    location: location
    storageAccountAccessTier: 'Hot'
    storageAccountKind: 'StorageV2'
    sku: 'Standard_LRS'
    tags: {
      environment: 'dev'
      displayName: 'storageAccount'
    }
    publicIpAddress: '62.31.74.157'
  }
}
output storageAccountName string = storage.name

module virtualMachine '../linux/main.bicep' = {
  name: 'linuxVM'
  params: {
    location: location
    adminPassword: keyvault.getSecret(keyVaultSecretName)
    adminUsername: 'zadmin'
    sshPassphraseKey: keyvault.getSecret(secretName)
    vmName: ''
    vmSize: 'standard_DS1_v2'
    offer: '0001-com-ubuntu-server-jammy'
    dnsServers: [
      '10.0.3.2'
      '10.0.3.3'
      '1.1.1.1'
    ]
    storageAccountType: 'Standard_LRS'
    subnetName: 'subnet1'
    vmSku: '22_04-lts-gen2'
    autoShutdownNotificationEmail: 'olamide@fountview.co.uk'
    aadClientId: '327d7e46-06a8-49a2-8749-515bb47e6d20'
    tenantId: '93fb203c-ab10-44a3-a9fe-05ac5b6e4cb9'
    virtualMachineCount: 1
  }
  dependsOn: [
    storage
  ]
}
output linuxVMName string = virtualMachine.name
output sshCommand array = virtualMachine.outputs.sshExecution

/*
module vm '../windows/main.bicep' = {
  name: 'windowsVM'
  params: {
    location: location
    adminPassword: keyvault.getSecret(keyVaultSecretName)
    adminUsername: ''
    autoShutdownNotificationEmail: ''
    certificateName: ''
    customScriptExtensionUri: ''
    dnsServers: [
      ''
    ]
    subnetName: 'subnet1'
    vmName: ''
    vmSize: 'standard_DS1_v2'
    virtualMachineCount: 1
  }
  dependsOn: [
    storage
  ]
}
*/
