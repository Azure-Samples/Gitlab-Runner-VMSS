import { NamingOutput } from './naming.module.bicep'

@description('Naming Convention')
param naming NamingOutput

@description('Primary location for all resources')
param location string

@description('The type of GitLab runner to create. Possible values windows, linux')
@allowed([
  'Windows'
  'Linux'
])
param runnerType string

@description('Tags that should be applied to all resources.')
param tags object

@description('Deterministic username based on resource group')
var scaleSetUserName = 'user-${uniqueString(resourceGroup().id)}'

@description('Deterministic password based on resource group')
var scaleSetUserPassword = base64('${uniqueString(resourceGroup().id, 'password')}')

@description('Vnet address space')
param vnetAddressSpace string

@description('Subnet address space')
param subnetAddressSpace string

@description('Gitlab token to register the runner')
@secure()
param gitlabToken string

var resourceNames = {
  vnetName: naming.virtualNetwork.name
  subnet1Name: '${naming.subnet.name}-01'
  vmssName: naming.linuxVirtualMachineScaleSet.name
  nicSuffix: '-nic01'
  managerNicSuffix: '-nic02'
  gitlabManagerName: naming.virtualMachine.name
}

var gitlabManagerPassword = base64('${uniqueString(resourceGroup().id, resourceNames.gitlabManagerName)}')

var imageReference = runnerType == 'Linux'
  ? {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
  : {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2022-datacenter-azure-edition'
      version: 'latest'
    }

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.6.1' = {
  name: resourceNames.vnetName
  params: {
    addressPrefixes: [
      vnetAddressSpace
    ]
    name: resourceNames.vnetName

    location: location

    subnets: [
      {
        name: resourceNames.subnet1Name
        addressPrefixes: [
          subnetAddressSpace
        ]
      }
    ]

    tags: tags
  }
}

module virtualMachineScaleSet 'br/public:avm/res/compute/virtual-machine-scale-set:0.8.1' = {
  name: resourceNames.vmssName
  params: {
    // Required parameters
    adminPassword: scaleSetUserPassword
    adminUsername: scaleSetUserName
    imageReference: imageReference
    name: resourceNames.vmssName
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig1'
            properties: {
              subnet: {
                id: virtualNetwork.outputs.subnetResourceIds[0]
              }
            }
          }
        ]
        nicSuffix: resourceNames.nicSuffix
      }
    ]
    osDisk: {
      createOption: 'fromImage'
      diskSizeGB: '128'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: runnerType
    skuName: 'Standard_B12ms'
    location: location
    orchestrationMode: 'Uniform'
    patchMode: 'AutomaticByOS'
  }
}

module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.12.3' = {
  name: resourceNames.gitlabManagerName
  params: {
    adminUsername: 'azureuser'
    adminPassword: gitlabManagerPassword
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: resourceNames.gitlabManagerName
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: virtualNetwork.outputs.subnetResourceIds[0]
          }
        ]
        nicSuffix: resourceNames.managerNicSuffix
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Linux'
    vmSize: 'Standard_D2s_v3'
    zone: 0
    // Non-required parameters
    disablePasswordAuthentication: false
    location: location
    managedIdentities: {
      systemAssigned: true
    }
    tags: tags
  }
}

resource managerMachine 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: resourceNames.gitlabManagerName
  dependsOn: [
    virtualMachine
  ]
}

// create a custom script extension to install gitlab runner
resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = {
  name: 'ManagerMachineCustomScript'
  parent: managerMachine
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/pankajagrawal16/Gitlab-Runner-VMSS/refs/heads/main/scripts/configure-manager-vm.sh'
      ]
      #disable-next-line protect-commandtoexecute-secrets
      commandToExecute: 'bash configure-manager-vm.sh --gitlab-token ${gitlabToken} --subscription-id ${subscription().subscriptionId} --resource-group-name ${resourceGroup().name} --username ${scaleSetUserName} --password ${scaleSetUserPassword} --vmss-name ${virtualMachineScaleSet.outputs.name}'
    }
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, resourceNames.vmssName, 'Contributor')
  scope: resourceGroup()
  properties: {
    principalId: virtualMachine.outputs.?systemAssignedMIPrincipalId!
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  }
}
