// Synapse Workspace Module

@description('Synapse workspace name')
param synapseWorkspaceName string

@description('Location for Synapse workspace')
param location string

@description('Storage account name for default data lake')
param storageAccountName string

@description('Storage account resource ID')
param storageAccountId string

@description('Filesystem name for default data lake')
param filesystemName string

@description('Spark Pool name')
param sparkPoolName string

@description('Spark Pool node size')
@allowed(['Small', 'Medium', 'Large'])
param sparkPoolSize string

@description('Enable Spark Pool auto-scale')
param sparkPoolAutoScale bool

@description('Optional SQL administrator login password (secure). If not provided, deployment will fail in strict environments; recommended to pass via parameters file.')
@secure()
param sqlAdministratorLoginPassword string = ''

// Synapse Workspace
resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseWorkspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: 'https://${storageAccountName}.dfs.${environment().suffixes.storage}'
      filesystem: filesystemName
      resourceId: storageAccountId
    }
    sqlAdministratorLogin: 'sqladmin'
    // Note: Provide password via parameter for security best-practice
    sqlAdministratorLoginPassword: length(sqlAdministratorLoginPassword) > 0 ? sqlAdministratorLoginPassword : '${uniqueString(synapseWorkspaceName, resourceGroup().id)}-TempP@ss1!'
    managedVirtualNetwork: 'default'
    publicNetworkAccess: 'Enabled'
  }
}

// Firewall rule: Allow all Azure services
resource firewallAllowAzure 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  parent: synapseWorkspace
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Firewall rule: Allow all (for dev/test - restrict in production)
resource firewallAllowAll 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  parent: synapseWorkspace
  name: 'AllowAll'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

// Spark Pool
resource sparkPool 'Microsoft.Synapse/workspaces/bigDataPools@2021-06-01' = {
  parent: synapseWorkspace
  name: sparkPoolName
  location: location
  properties: {
    sparkVersion: '3.4'
    nodeSize: sparkPoolSize
    nodeSizeFamily: 'MemoryOptimized'
    autoScale: sparkPoolAutoScale ? {
      enabled: true
      minNodeCount: 3
      maxNodeCount: 10
    } : null
    nodeCount: sparkPoolAutoScale ? null : 3
    autoPause: {
      enabled: true
      delayInMinutes: 15
    }
    dynamicExecutorAllocation: {
      enabled: true
      minExecutors: 1
      maxExecutors: 4
    }
    sessionLevelPackagesEnabled: true
    cacheSize: 0
  }
}

// Outputs
output synapseWorkspaceName string = synapseWorkspace.name
output synapseWorkspaceId string = synapseWorkspace.id
output synapsePrincipalId string = synapseWorkspace.identity.principalId
output sparkPoolName string = sparkPool.name
output synapseDevEndpoint string = synapseWorkspace.properties.connectivityEndpoints.dev
