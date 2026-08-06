param functionPlanName string

resource flexPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: functionPlanName
  location: resourceGroup().location
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  kind: 'functionapp'
  properties: {
    reserved: true
  }
}
