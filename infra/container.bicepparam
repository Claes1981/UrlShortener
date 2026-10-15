using './container.bicep'

param registryName = 'acrclo25claes'
param environmentName = 'cae-clo25-claes'
param containerAppName = 'ca-clo25-claes'
param containerImage = 'acrclo25claes.azurecr.io/urlshortener:v1'
param minReplicas = 1
param maxReplicas = 5
