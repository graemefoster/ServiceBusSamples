var random = uniqueString(resourceGroup().name)
var location = 'AustraliaEast'

resource asp 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${random}-asp'
  location: location
  sku: {
    name: 'S1'
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: '${random}stg'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: true
  }
}

resource appinsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${random}-appi'
  location: location
  kind: ''
  properties: {
    Application_Type: 'other'
  }
}

resource servicebus 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: '${random}-sbn'
  location: location
  sku: {
    name: 'Standard'
  }

  resource q 'queues@2021-06-01-preview' = {
    name: 'process-queue'
    properties: {}
  }

  resource q2 'queues@2021-06-01-preview' = {
    name: 'intermediate-queue'
    properties: {}
  }
}

resource site 'Microsoft.Web/sites@2021-03-01' = {
  name: '${random}-func'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'functionapp'
  properties: {
    serverFarmId: asp.id
    siteConfig: {
      alwaysOn: true
      use32BitWorkerProcess: true
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storage.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appinsights.properties.InstrumentationKey
        }
        {
          name: 'sample_SERVICEBUS__fullyQualifiedNamespace'
          value: '${servicebus.name}.servicebus.windows.net'
        }
      ]
    }
  }
}

resource website 'Microsoft.Web/sites@2021-03-01' = {
  name: '${random}-web'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: asp.id
    siteConfig: {
      alwaysOn: true
      use32BitWorkerProcess: true
      appSettings: [
        {
          name: 'sample_SERVICEBUS__fullyQualifiedNamespace'
          value: '${servicebus.name}.servicebus.windows.net'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appinsights.properties.InstrumentationKey
        }
      ]
      connectionStrings: [
        {
          name: 'AzureWebJobsStorage'
          type: 'Custom'
          connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value}'
        }
        {
          name: 'AzureWebJobsDashboard'
          type: 'Custom'
          connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value}'
        }
      ]
    }
  }
}

resource sbFuncRbac 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(site.name, 'read', servicebus.name)
  scope: servicebus
  properties: {
    roleDefinitionId: '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
    principalId: site.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource sbRbac 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(website.name, 'read', servicebus.name)
  scope: servicebus
  properties: {
    roleDefinitionId: '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
    principalId: website.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
