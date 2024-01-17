param location string = resourceGroup().location
param keyVaultName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}kv'
param keyVaultSecretName string = 'adminpassword'
param secretName string = 'sshpassphrase'
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
  }
}
output storageAccountName string = storage.name

module virtualMachine '../linux/main.bicep' = {
  name: 'linuxVM'
  params: {
    location: location
    adminPassword: keyvault.getSecret(keyVaultSecretName)
    adminUsername: ''
    sshPassphraseKey: keyvault.getSecret(secretName)
    vmName: ''
    vmSize: 'standard_DS1_v2'
    offer: '0001-com-ubuntu-server-jammy'
    dnsServers: [
      ''
    ]
    storageAccountType: 'Standard_LRS'
    subnetName: 'subnet1'
    vmSku: '22_04-lts-gen2'
    autoShutdownNotificationEmail: ''
    aadClientId: ''
    tenantId: ''
    virtualMachineCount: 1
  }
  dependsOn: [
    storage
  ]
}
output linuxVMName string = virtualMachine.name
output sshCommand array = virtualMachine.outputs.sshExecution

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
