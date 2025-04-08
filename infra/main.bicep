targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param appName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Address space for the virtual network where the GitLab runner will be deployed')
param vnetAddressSpace string

@description('Address space for the subnet where the GitLab runner will be deployed')
param subnetAddressSpace string

@description('Gitlab token to register the runner')
@secure()
param gitlabToken string

@description('Existing VNet ID to use. If provided, a new VNet will not be created.')
param existingVnetId string = ''

@description('Existing Subnet ID to use. If provided, a new Subnet will not be created.')
param existingSubnetId string = ''

var tags = {
  'azd-env-name': appName
}

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${appName}'
  location: location
  tags: tags
}

module naming 'core/naming.module.bicep' = {
  scope: rg
  name: 'NamingDeployment'
  params: {
    location: location
    suffix: [
      appName
      '**location**' // azure-naming location/region placeholder, it will be replaced with its abbreviation
    ]
    uniqueLength: 6
  }
}


module gitlabrunner 'core/gitlab-runner.bicep' = {
  name: 'gitlab-runner'
  scope: rg
  params: {
    runnerType: 'Linux'
    location: location
    tags: tags
    naming: naming.outputs.names
    vnetAddressSpace: vnetAddressSpace
    subnetAddressSpace: subnetAddressSpace
    gitlabToken: gitlabToken
    existingVnetId: existingVnetId
    existingSubnetId: existingSubnetId
  }
}
