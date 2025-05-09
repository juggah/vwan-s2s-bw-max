//VPN Gateway Module
param vpnGwName string
param vpnGwLoc string
param vHubId string
resource vpngw 'Microsoft.Network/vpnGateways@2024-05-01' = {
  name: vpnGwName
  location: vpnGwLoc
  properties: {
     virtualHub: {
      id: vHubId
    }
        vpnGatewayScaleUnit: 5
 
  }
}
output vpnGwPublicIps array = [ 
  vpngw.properties.ipConfigurations[0].publicIpAddress
  vpngw.properties.ipConfigurations[1].publicIpAddress
]
