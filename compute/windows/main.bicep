@description('name of the VM to be created.')
param vmName string

@description('VM Sku')
@allowed([
  '2022-Datacenter-core'
  '2022-Datacenter'
  '2022-Datacenter-g2'
  '2022-Datacenter-core-g2'
])
param vmSku string = '2022-Datacenter-core-g2'

@description('storage account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param storageAccountType string = 'Standard_LRS'

@description('size of the VM')
@allowed([
  'standard_DS1_v2'
  'standard_DS2_v2'
  'standard_D2s_v3'
])
param vmSize string

@description('vm disk size in GB')
@minValue(60)
@maxValue(1024)
param vmDiskSize int = 128

@description('admin account username')
param adminUsername string

@description('admin account password')
@secure()
param adminPassword string

@description('minimum number of VMs to be created')
@minValue(1)
@maxValue(10)
param virtualMachineCount int = 1

@description('resource location')
param location string = resourceGroup().location

@description('availability set name')
param availabilitySetName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}avset'

@description('proximity placement group name')
param proximityPlacementGroupName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}ppg'

@description('virtual network name')
param vnetName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}vnet'

@description('storage account name')
param storageAccountName string = '${uniqueString(resourceGroup().id)}stga'

@description('key vault name')
param keyVaultName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}kv'

@description('network interface name.')
param networkInterfaceName string = '${toLower(replace(resourceGroup().name, 'uksouthrg', ''))}nic'

@description('dns servers for vm.')
param dnsServers array

@description('name of subnet where VMs will be created.')
@allowed([
  'subnet1'
  'subnet2'
])
param subnetName string

@description('publisher name for the image')
param publisherName string = 'MicrosoftWindowsServer'

@description('license type for the image')
@allowed([
  'Windows_Server'
  'Windows_Client'
])
param licenseType string = 'Windows_Server'

@description('offer name for the image')
param offer string = 'WindowsServer'

@description('autoshutdown status')
@allowed([
  'Enabled'
  'Disabled'
])
param autoShutdownStatus string = 'Enabled'

@description('autoshutdown time')
param autoShutdownTime string = '18:00'

@description('autoshutdown timezone')
param autoShutdownTimeZone string = 'GMT Standard Time'

@description('autoshutdown notification status')
@allowed([
  'Enabled'
  'Disabled'
])
param autoShutdownNotificationStatus string = 'Enabled'

@description('autoshutdown notification email')
param autoShutdownNotificationEmail string

@description('autoshutdown notification time in minutes')
param autoShutdownNotificationTimeInMinutes int = 30

@description('autoshutdown notification locale')
param autoShutdownNotificationLocale string = 'en'

@description('certificate name')
param certificateName string

@description('custom script extension uri')
param customScriptExtensionUri string

var virtualMachineCountRange = range(0, virtualMachineCount)
resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

var storageAccountUri = storageAccount.properties.primaryEndpoints.blob

resource proximityPlacementGroup 'Microsoft.Compute/proximityPlacementGroups@2023-09-01' = {
  name: proximityPlacementGroupName
  location: location
  properties: {
    proximityPlacementGroupType: 'Standard'
    colocationStatus: {
      code: 'Aligned'
      displayStatus: 'Aligned'
      level: 'Error'
      message: 'Aligned'
    }
  }
}

resource availabilitySet 'Microsoft.Compute/availabilitySets@2023-09-01' = {
  name: availabilitySetName
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
    proximityPlacementGroup: {
      id: proximityPlacementGroup.id
    }
  }
}
resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}
var vaultUri = keyvault.properties.vaultUri
var certificateUri = '${vaultUri}/secrets/${certificateName}/version/1'
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-06-01' = [for i in virtualMachineCountRange: {
  name: '${vmName}${networkInterfaceName}${i + 1}'
  location: location
  properties: {
    dnsSettings: {
      dnsServers: dnsServers
    }
    nicType: 'Standard'
    ipConfigurations: [
      {
        name: 'IpConfig${i + 1}'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${subnetName}'
          }
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}]
resource virtualmachine 'Microsoft.Compute/virtualMachines@2023-09-01' = [for i in virtualMachineCountRange: {
  name: '${vmName}${i + 1}'
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySet.id
    }
    proximityPlacementGroup: {
      id: proximityPlacementGroup.id
    }
    hardwareProfile: {
      vmSize: vmSize
      vmSizeProperties: {
        vCPUsAvailable: 2
        vCPUsPerCore: 1
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vmName}${networkInterfaceName}${i + 1}')
          properties: {
            primary: true
            deleteOption: 'Delete'
          }
        }
      ]
    }
    osProfile: {
      adminPassword: adminPassword
      adminUsername: adminUsername
      computerName: '${vmName}${i + 1}'
      allowExtensionOperations: true
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        timeZone: autoShutdownTimeZone
        winRM: {
          listeners: [
            {
              protocol: 'Http'
              certificateUrl: certificateUri
            }
          ]
        }
      }
      secrets: [
        {
          sourceVault: {
            id: vaultUri
          }
          vaultCertificates: [
            {
              certificateStore: 'My'
              certificateUrl: certificateUri
            }
          ]
        }
      ]
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        diskSizeGB: vmDiskSize
        managedDisk: {
          storageAccountType: storageAccountType
        }
        osType: 'Windows'
        deleteOption: 'Delete'
        name: '${vmName}${i + 1}'
      }
      imageReference: {
        publisher: publisherName
        offer: offer
        sku: vmSku
        version: 'latest'
      }
      dataDisks: [
        {
          createOption: 'Empty'
          caching: 'None'
          diskSizeGB: 128
          managedDisk: {
            storageAccountType: storageAccountType
          }
          lun: 0
          name: '${vmName}${i + 1}_datadisk'
          deleteOption: 'Delete'
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountUri
      }
    }
    licenseType: licenseType
  }
  identity: {
    type: 'SystemAssigned'
  }
}]
resource extension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [for i in virtualMachineCountRange: {
  name: '${vmName}${i + 1}CustomScriptExtension'
  location: location
  parent: virtualmachine[i]
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        customScriptExtensionUri
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy bypass -File ./${last(split(customScriptExtensionUri, '/'))}'
    }
  }
}]
resource autoshutdown_computeVM 'Microsoft.DevTestLab/schedules@2018-09-15' = [for i in virtualMachineCountRange: {
  name: 'shutdown-computeVM-${vmName}${i + 1}'
  location: location
  properties: {
    status: autoShutdownStatus
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: autoShutdownTime
    }
    timeZoneId: autoShutdownTimeZone
    notificationSettings: {
      status: autoShutdownNotificationStatus
      notificationLocale: autoShutdownNotificationLocale
      emailRecipient: autoShutdownNotificationEmail
      timeInMinutes: autoShutdownNotificationTimeInMinutes
    }
    targetResourceId: resourceId('Microsoft.Compute/virtualMachines', '${vmName}${i + 1}')
  }
  dependsOn: [
    virtualmachine
  ]
}]

output virtualMachineNames array = [for i in virtualMachineCountRange: '${vmName}${i + 1}']
output virtualMachineIds array = [for i in virtualMachineCountRange: resourceId('Microsoft.Compute/virtualMachines', '${vmName}${i + 1}')]
output adminUsername string = adminUsername
