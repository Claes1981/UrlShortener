param serverfarms_asp_clo25_claes_export_name string

resource serverfarms_asp_clo25_claes_export_name_resource 'Microsoft.Web/serverfarms@2024-11-01' = {
  kind: 'linux'
  location: 'West Europe'
  name: serverfarms_asp_clo25_claes_export_name
  properties: {
    asyncScalingEnabled: false
    elasticScaleEnabled: false
    freeOfferExpirationTime: '2026-10-08T12:20:30.7466667'
    hyperV: false
    isSpot: false
    isXenon: false
    maximumElasticWorkerCount: 1
    perSiteScaling: false
    reserved: true
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
  sku: {
    capacity: 1
    family: 'B'
    name: 'B1'
    size: 'B1'
    tier: 'Basic'
  }
}
