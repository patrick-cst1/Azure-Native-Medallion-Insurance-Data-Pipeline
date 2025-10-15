// ========================================
// Azure-Native Medallion Insurance Data Pipeline
// Batch-only Infrastructure (Synapse + ADLS + Key Vault)
// ========================================

@description('Base name for all resources')
param baseName string = 'insurance-ml'

@description('Environment name (dev, staging, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Spark Pool node size')
@allowed(['Small', 'Medium', 'Large'])
param sparkPoolSize string = 'Small'

@description('Enable Spark Pool auto-scale')
param sparkPoolAutoScale bool = true

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var storageAccountName = replace('${baseName}${environmentName}${uniqueSuffix}', '-', '')
var synapseWorkspaceName = 'syn-${baseName}-${environmentName}-${uniqueSuffix}'
// Key Vault name must be <= 24 chars, use abbreviated naming
var keyVaultName = 'kv-${replace(baseName, '-', '')}${environmentName}-${take(uniqueSuffix, 6)}'
var sparkPoolName = 'sparkpool${environmentName}'

// Storage Account (ADLS Gen2)
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    storageAccountName: take(storageAccountName, 24)
    location: location
  }
}

// Key Vault
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    keyVaultName: keyVaultName  // Already trimmed to max 24 chars in variable definition
    location: location
  }
}

// Synapse Workspace
module synapse 'modules/synapse.bicep' = {
  name: 'synapse-deployment'
  params: {
    synapseWorkspaceName: synapseWorkspaceName
    location: location
    storageAccountName: storage.outputs.storageAccountName
    storageAccountId: storage.outputs.storageAccountId
    filesystemName: storage.outputs.filesystemName
    sparkPoolName: sparkPoolName
    sparkPoolSize: sparkPoolSize
    sparkPoolAutoScale: sparkPoolAutoScale
  }
}

// RBAC Role Assignments
module roles 'modules/roles.bicep' = {
  name: 'roles-deployment'
  params: {
    synapsePrincipalId: synapse.outputs.synapsePrincipalId
    storageAccountId: storage.outputs.storageAccountId
    keyVaultName: keyVault.outputs.keyVaultName
  }
}

// Outputs
output storageAccountName string = storage.outputs.storageAccountName
output synapseWorkspaceName string = synapse.outputs.synapseWorkspaceName
output keyVaultName string = keyVault.outputs.keyVaultName
output sparkPoolName string = synapse.outputs.sparkPoolName
output filesContainerName string = storage.outputs.filesContainerName
output tablesContainerName string = storage.outputs.tablesContainerName
