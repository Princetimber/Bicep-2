@description('name of the VM to be created.')
param vmName string

@description('VM Sku')
@allowed([
  '22_04-lts-gen2'
  '18_04-lts-gen2'
  '19_04-gen2'
])
param vmSku string

@description('storage account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param storageAccountType string

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

@description('ssh passphraseKey.')
@secure()
param sshPassphraseKey string

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
param publisherName string = 'Canonical'

@description('offer name for the image')
@allowed([
  'UbuntuServer'
  '0001-com-ubuntu-server-focal'
  '0001-com-ubuntu-server-bionic'
  '0001-com-ubuntu-server-jammy'
])
param offer string

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

resource nic 'Microsoft.Network/networkInterfaces@2023-06-01' = [for i in virtualMachineCountRange: {
  name: '${vmName}${networkInterfaceName}${i + 1}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig${i + 1}'
        properties: {
          primary: true
          subnet: {
            id: '${vnet.id}/subnets/${subnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: dnsServers
    }
    nicType: 'Standard'
    enableIPForwarding: true
  }
}]

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' = [for i in virtualMachineCountRange: {
  name: '${vmName}${i + 1}'
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySet.id
    }
    proximityPlacementGroup: {
      id: proximityPlacementGroup.id
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: '${storageAccountUri}${vmName}${i + 1}'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vmName}${networkInterfaceName}${i + 1}')
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    hardwareProfile: {
      vmSize: vmSize
      vmSizeProperties: {
        vCPUsAvailable: 2
        vCPUsPerCore: 1
      }
    }
    osProfile: {
      computerName: '${vmName}${i + 1}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: true
        provisionVMAgent: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPassphraseKey
            }
          ]
        }
        patchSettings: {
          assessmentMode: 'AutomaticByPlatform'
          patchMode: 'AutomaticByPlatform'
        }
      }
    }
    storageProfile: {
      osDisk: {
        name: '${vmName}${i + 1}_osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: vmDiskSize
        managedDisk: {
          storageAccountType: storageAccountType
        }
        deleteOption: 'Delete'
        osType: 'Linux'
      }
      imageReference: {
        publisher: publisherName
        offer: offer
        sku: vmSku
        version: 'latest'
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
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
    virtualMachine
  ]
}]

output vmNames array = [for i in virtualMachineCountRange: '${vmName}${i + 1}']
output vmIds array = [for i in virtualMachineCountRange: '${virtualMachine[i].id}']
output adminUsername string = adminUsername
output sshExecution array = [for i in virtualMachineCountRange: {
  name: '${vmName}${i + 1}'
  sshCommand: 'ssh ${adminUsername}@${nic[i].properties.ipConfigurations[i].properties.privateIPAddress} -i ~/.ssh/id_rsa'
}]
