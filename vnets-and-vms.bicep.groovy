var imageReference = {
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}


resource nicregion1 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: 'nic-vm-${region1}'
  location: region1
  properties:{
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipv4config'
        properties:{
          primary: true
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: vnetregion1.outputs.subnets[0].id
          }
          
          privateIPAddress: '192.168.1.4'         
        }
      }
    ]
  }
}
resource vmregion1 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'vm-${region1}'
  location: region1
  zones: [ '1' ]
  properties: {
    hardwareProfile:{
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: imageReference['Ubuntu-2204']
    }
      osProfile:{
        computerName: 'vm-${primvHubName}'
        adminUsername: 'azureuser'
        adminPassword: adminPassword
        linuxConfiguration: {
          patchSettings: {
            patchMode: 'ImageDefault'
          }
        }
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
   //       storageUri: bootstUri
        }
     }
      networkProfile: {
        networkInterfaces: [
        {
          id: nicregion1.id
        }
      ]
    }
  }
}
//gwc
module vnetregion2'br:crdvagiacprd.azurecr.io/platform/bicep/virtualnetwork:0.8.2' = {
  name: 'vnet-vms-gwc-${uniqueString(resourceGroup().id)}'
  params: {
    applicationName: 'vm-'
    counter: 1
    location : secondaryRegion
    addressPrefixes: [ scndvmPrefix ]
    subnetsDefinitions: [
      {
        name: 'subnet1'
        subnetPrefix: scndvmPrefix
        delegations: []
        routeTable: []
        serviceEndpoints: []
        networkSecurityGroupName: []
        networkSecurityGroupResourceGroup: []
      }
    ]
  }
}
resource nicregion2 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: 'vm-${region2}'
  location: region2
  properties:{
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipv4config'
        properties:{
          primary: true
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: vnetregion2.outputs.subnets[0].id
          }
          
          privateIPAddress: '192.168.2.4'         
        }
      }
    ]
  }
}
resource vmregion2 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'vm-${region2}'
  location: region2
  zones: [ '1' ]
  properties: {
    hardwareProfile:{
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: imageReference['Ubuntu-2204']
    }
      osProfile:{
        computerName: 'vm-${region2}'
        adminUsername: 'azureuser'
        adminPassword: adminPassword
        linuxConfiguration: {
          patchSettings: {
            patchMode: 'ImageDefault'
          }
        }
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
   //       storageUri: bootstUri
        }
     }
      networkProfile: {
        networkInterfaces: [
        {
          id: nicregion2.id
        }
      ]
    }
  }
}

resource VwanHubtovnet 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-05-01' = {
  parent: vHubRegion1
  name: 'VMvnet-region1-to-hub-comm'
  properties: {
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vHubRegion1.name, 'defaultRouteTable')
      }
      propagatedRouteTables: {
        labels: [
          'default'
        ]
        ids: [
          {
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vHubRegion1.name, 'defaultRouteTable')
          }
        ]
      }
    }
    remoteVirtualNetwork: {
      id: vnetregion1.outputs.id

    enableInternetSecurity: false
  }
}
}

resource VwanHubtovnet2 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-05-01' = {
  parent: vHubRegion2
  name: 'VMvnet-region2-to-hub-comm'
  properties: {
    routingConfiguration: {
      associatedRouteTable: {
        id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vHubRegion2.name, 'defaultRouteTable')
      }
      propagatedRouteTables: {
        labels: [
          'default'
        ]
        ids: [
          {
            id: resourceId('Microsoft.Network/virtualHubs/hubRouteTables', vHubRegion2.name, 'defaultRouteTable')
          }
        ]
      }
    }
    remoteVirtualNetwork: {
      id: vnetregion2.outputs.id

    enableInternetSecurity: false
  }
}
}
