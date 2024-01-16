/*
  * This is a Bicep file. For more information, see https://aka.ms/BicepReference
  * this is a module that creates a resource group
  * This is a subscription level deployment with a resource group as the target
  * @targetScope: subscription
  * @moduleName: resource-group
  * @param name: the name of the resource group
  * @param location: the location of the resource group
  * @output Name: the name of the resource group
  * @output Id: the id of the resource group
*/
targetScope = 'subscription'
@description('The location of the resource group.')
param location string = deployment().location
module rg '../resourceGroups/main.bicep' = {
  name: 'resource-group'
  params: {
    name: 'developmentuksouthrg'
    location: location
  }
}
