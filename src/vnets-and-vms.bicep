param region1 string
param region2 string
param prefix2Region1 string
param prefix2Region2 string
param vmSize string 
param adminUserName string = 'azureuser'
@secure()
param adminPassword string = 'Password1234!'


var imageReference = {
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}
//Import vHubs
resource vHubRegion1 'Microsoft.Network/virtualHubs@2024-05-01' existing = {
  name: 'vhub-${region1}'
}
resource vHubRegion2 'Microsoft.Network/virtualHubs@2024-05-01' existing = {
  name: 'vhub-${region2}'
}
// Deploy VNETs and vHub Connections

resource vNetRegion1 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${region1}'
  location: region1
  properties: {
    addressSpace: {
      addressPrefixes: [
        prefix2Region1
      ]
    }
     subnets: [
      {
        name: 'snet-${region1}'
        properties: {
          addressPrefix: prefix2Region1
        }
      }
    ]
  }
}

resource vNetRegion2 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${region2}'
  location: region2
  properties: {
    addressSpace: {
      addressPrefixes: [
        prefix2Region2
      ]
    }
     subnets: [
      {
        name: 'snet-${region2}'
        properties: {
          addressPrefix: prefix2Region2
        }
      }
    ]
  }
}

resource nicRegion1 'Microsoft.Network/networkInterfaces@2020-08-01' = {
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
            id: vNetRegion1.id
          }
          privateIPAddress: '192.168.1.4'         
        }
      }
    ]
  }
}

resource vmRegion1 'Microsoft.Compute/virtualMachines@2020-12-01' = {
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
        computerName: 'vm-${region1}'
        adminUsername: adminUserName
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
        }
     }
      networkProfile: {
        networkInterfaces: [
        {
          id: nicRegion1.id
        }
      ]
    }
  }
  }

resource nicRegion2 'Microsoft.Network/networkInterfaces@2020-08-01' = {
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
            id: vNetRegion2.id
          }
          
          privateIPAddress: '192.168.2.4'         
        }
      }
    ]
  }
}
resource vmRegion2 'Microsoft.Compute/virtualMachines@2020-12-01' = {
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
        adminUsername: adminUserName
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
          id: nicRegion2.id
        }
      ]
    }
  }
}

resource vWanHubToVnet 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-05-01' = {
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
      id: vNetRegion1.id
  }
}
}

resource vWanHubToVnet2 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-05-01' = {
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
      id: vNetRegion2.id
  }
}
}
