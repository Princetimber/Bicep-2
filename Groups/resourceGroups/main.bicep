/*
 *This is a Bicep file. More info at https://aka.ms/bicep
 *It creates a resource group with tags and a lock.
  *The lock is set to CanNotDelete.
  *The tags are:
    *displayName: 'Resource Group'
    *CostCenter: 'Engineering'
  *The resource group name and location are parameters.
*/

targetScope = 'subscription'
@description('Creates a resource group with tags')
param name string
@description('The location of the resource group')
param location string = deployment().location

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: name
  location: location
  tags: {
    displayName: 'Resource Group'
    CostCenter: 'Engineering'
  }
}
output Id string = rg.id
output Name string = rg.name

resource locks 'Microsoft.Authorization/locks@2020-05-01' = {
  name: '${name}-lock'
  properties: {
    level: 'CanNotDelete'
  }
  dependsOn: [
    rg
  ]
}
