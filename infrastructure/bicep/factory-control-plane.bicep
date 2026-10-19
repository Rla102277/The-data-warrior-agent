// Foundation Factory control-plane skeleton (local/dev).
// Do not provision paid Azure resources without explicit approval.

@description('Environment name: local | dev | test')
param environmentName string = 'dev'

@description('Location for resources')
param location string = resourceGroup().location

@description('When false, template only validates structure (recommended default)')
param deployPaidResources bool = false

var namePrefix = 'foundation-factory-${environmentName}'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (deployPaidResources) {
  name: '${namePrefix}-logs'
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}

output message string = deployPaidResources
  ? 'Paid resources requested; ensure approval was granted.'
  : 'Template validated; deployPaidResources=false (no paid resources created).'

output environment string = environmentName
