param region1 string = 'northeurope'
param region2 string = 'germanywestcentral'
param prefixRegion1 string = '10.10.0.0/16'
param prefixRegion2 string = '10.20.0.0/16'
param prefix2Region1 string = '192.168.1.0/24'
param prefix2Region2 string = '192.168.2.0/24'

resource vWanRegion1 'Microsoft.Network/virtualWans@2024-05-01' = {
  name: 'vwan-${region1}'
  location: region1

  properties: {
   
    allowBranchToBranchTraffic: true
    type: 'Standard'
  } 
}

  resource vhubRegion1 'Microsoft.Network/virtualHubs@2024-05-01' = {
    name: 'vhub-${region1}'
    location: region1
    properties: {
      addressPrefix: prefixRegion1
       
      routeTable: {
        routes: []
      }
      virtualRouterAutoScaleConfiguration: {
        minCapacity: 2
      }
      virtualWan: {
        id: vWanRegion1.id
      }
     
    
      
      hubRoutingPreference: 'ASPath'
    }
    
  }
  

resource vWanRegion2 'Microsoft.Network/virtualWans@2024-05-01' = {
  name: 'vwan-${region2}'
  location: region2
  properties: {
    
    allowBranchToBranchTraffic: true
    type: 'Standard'
  }
}


resource vhubRegion2 'Microsoft.Network/virtualHubs@2024-05-01' = {
  name: 'vhub-${region2}'
  location: region2
  properties: {
    addressPrefix: prefixRegion2
     
    routeTable: {
      routes: []
    }
    virtualRouterAutoScaleConfiguration: {
      minCapacity: 2
    }
    virtualWan: {
      id: vWanRegion2.id
    }
   
  
    
    hubRoutingPreference: 'ASPath'
  }
  
}


module vpnRegion1 'vpngw.bicep' = {
  name: 'vpngw-${region1}-${uniqueString(resourceGroup().id)}'
  params : {
  vpnGwName: 'vpngw-${region1}'
  vpnGwLoc: region1
   vHubId: vhubRegion1.id
   }
 }


module vpnRegion2 'vpngw.bicep' = {
 name: 'vpngw-${region2}-${uniqueString(resourceGroup().id)}'
 params : {
  vpnGwName: 'vpngw-${region2}'
  vpnGwLoc: region2
  vHubId: vhubRegion2.id
  }
}



resource vpnSiteRegion1 'Microsoft.Network/vpnSites@2023-05-01' = {
  name: 'vpnsite-${region1}'
  location: region1
  
  properties: {
    deviceProperties: {
      deviceVendor: 'Generic'
    }
    
    virtualWan: {
      id: vWanRegion2.id
    }
    addressSpace: {
      addressPrefixes: [
     prefixRegion1
     prefix2Region1
      ]
    }
    vpnSiteLinks: [
      {
        name: 'link-1'
        properties: {
          ipAddress: vpnRegion1.outputs.vpnGwPublicIps[0] == null ? '1.1.1.1' : vpnRegion1.outputs.vpnGwPublicIps[0]
        }
      }
      {
        name: 'link-2'
        properties: {
          ipAddress: vpnRegion1.outputs.vpnGwPublicIps[1] == null ? '2.2.2.2' : vpnRegion1.outputs.vpnGwPublicIps[1]
        }
      }
    ]
  }
}





resource vpnSiteRegion2 'Microsoft.Network/vpnSites@2023-05-01' = {
  name: 'vpnsite-${region2}'
  location: region2
  properties: {
    deviceProperties: {
      deviceVendor: 'Generic'
    }
    
    virtualWan: {
      id: vWanRegion1.id
    }
    addressSpace: {
      addressPrefixes: [
     prefixRegion2
     prefix2Region2
      ]
    }
    vpnSiteLinks: [
      {
        name: 'link-1'
        properties: {
          ipAddress: vpnRegion2.outputs.vpnGwPublicIps[0] == null ? '3.3.3.3' : vpnRegion2.outputs.vpnGwPublicIps[0]
        }
      }
      {
        name: 'link-2'
        properties: {
          ipAddress: vpnRegion2.outputs.vpnGwPublicIps[1] == null ? '4.4.4.4' :  vpnRegion2.outputs.vpnGwPublicIps[1]
        }
      }
    ]
  }
}


resource hubVpnConnectionRegion1 'Microsoft.Network/vpnGateways/vpnConnections@2020-05-01' = {
  name: 'vpngw-${region1}/HubToOnPremConnection'
  properties: {
    //enableBgp: false
    remoteVpnSite: {
      id: vpnSiteRegion2.id
    }
    vpnLinkConnections: [
      {
        name: 'link-1'
        properties: {
          vpnSiteLink: {
            id: resourceId('Microsoft.Network/vpnSites/vpnSiteLinks', 'vpnsite-${region2}', 'link-1')
          }
          //enableBgp: false
          sharedKey: 'test'
         
        }
      }
      {
        name: 'link-2'
        properties: {
          vpnSiteLink: {
            id: resourceId('Microsoft.Network/vpnSites/vpnSiteLinks', 'vpnsite-${region2}', 'link-2')
          }
          //enableBgp: false
          sharedKey: 'test'
        
        }
      }
     
    ]
  }
}


resource hubVpnConnectionRegion2 'Microsoft.Network/vpnGateways/vpnConnections@2020-05-01' = {
  name: 'vpngw-${region2}/HubToOnPremConnection'
  properties: {
    //enableBgp: false
    remoteVpnSite: {
      id: vpnSiteRegion1.id
    }
    vpnLinkConnections: [
      {
        name: 'link-1'
        properties: {
          vpnSiteLink: {
            id: resourceId('Microsoft.Network/vpnSites/vpnSiteLinks', 'vpnsite-${region1}', 'link-1')
          }
          //enableBgp: false
          sharedKey: 'test'
        
        }
      }
      {
        name: 'link-2'
        properties: {
          vpnSiteLink: {
            id: resourceId('Microsoft.Network/vpnSites/vpnSiteLinks', 'vpnsite-${region1}', 'link-2')
          }
          //enableBgp: false
          sharedKey: 'test'
      
        }
      }
     
    ]
  }
}

