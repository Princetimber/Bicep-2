targetScope = 'subscription'
@description('Creates a resource group with tags')
param name string
@description('The location of the resource group')
param location string = deployment().location

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: name
  location: location
  tags:{
    displayName: 'Resource Group'
    CostCenter: 'Engineering'
  }
}
output Id string = rg.id
output Name string = rg.name
