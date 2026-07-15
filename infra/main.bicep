targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = 'mexicocentral'

@description('App Service Plan name.')
param appServicePlanName string = 'plan-cursoaz-free-mx'

@description('Web App name. This must be globally unique in azurewebsites.net.')
param webAppName string = 'saasia-cursoaz'

@description('Application Insights resource name.')
param appInsightsName string = 'appi-saasia-cursoaz'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'app'
  sku: {
    name: 'F1'
    tier: 'Free'
    size: 'F1'
    family: 'F'
    capacity: 0
  }
  properties: {
    reserved: false
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    RetentionInDays: 90
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      netFrameworkVersion: 'v10.0'
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      use32BitWorkerProcess: true
      alwaysOn: false
    }
  }
}

resource webAppSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: webApp
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
    APPINSIGHTS_CONNECTIONSTRING: appInsights.properties.ConnectionString
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
    APPINSIGHTS_PROFILERFEATURE_VERSION: 'disabled'
    APPINSIGHTS_SNAPSHOTFEATURE_VERSION: 'disabled'
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'recommended'
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output appInsightsResourceName string = appInsights.name
