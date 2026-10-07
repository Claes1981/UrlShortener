resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'asp-clo25-claes-export'
  location: 'westeurope'
  kind: 'linux'
  sku: {
    name: 'B1'
  }
  properties: {
    reserved: true
  }
}
