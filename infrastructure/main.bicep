// ========================================
// Azure-Native Medallion Insurance Data Pipeline
// Batch-only Infrastructure (Synapse + ADLS + Key Vault)
// ========================================

@description('Base name for all resources')
param baseName string = 'insml'

@description('Environment name (dev, staging, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Spark Pool node size')
@allowed(['Small', 'Medium', 'Large'])
param sparkPoolSize string = 'Small'

@description('Enable Spark Pool auto-scale')
param sparkPoolAutoScale bool = true

@description('Optional list of AAD Object IDs (users/groups/apps) to grant RBAC on Storage and Key Vault for portal access and authoring')
param additionalPrincipalIds array = []

// Variables - Standardized Naming Convention
// Pattern: {baseName}-{resourceType}-{environment}-{uniqueSuffix}
// All names compliant with Azure naming restrictions (alphanumeric, lengths, etc.)
var uniqueSuffix = take(uniqueString(resourceGroup().id), 6)
var baseNameClean = replace(baseName, '-', '')  // Remove hyphens for storage/keyvault (alphanumeric only)
var storageAccountName = take('${baseNameClean}st${environmentName}${uniqueSuffix}', 24)  // Max 24 chars, alphanumeric only
var synapseWorkspaceName = '${baseName}-syn-${environmentName}-${uniqueSuffix}'     // Synapse allows hyphens
var keyVaultName = take('${baseNameClean}kv${environmentName}${uniqueSuffix}', 24)       // Max 24 chars, alphanumeric only
var environmentClean = replace(environmentName, '-', '')                            // Ensure alphanumeric for spark pool
var sparkPoolName = take('${baseNameClean}spark${environmentClean}', 15)             // Spark pool requires <=15 alphanumeric characters

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
    keyVaultName: keyVaultName  // Trimmed to max 24 chars
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
    additionalPrincipalIds: additionalPrincipalIds
  }
}

// Outputs
output storageAccountName string = storage.outputs.storageAccountName
output storageAccountId string = storage.outputs.storageAccountId
output synapseWorkspaceName string = synapse.outputs.synapseWorkspaceName
output keyVaultName string = keyVault.outputs.keyVaultName
output sparkPoolName string = synapse.outputs.sparkPoolName
output filesContainerName string = storage.outputs.filesContainerName
output tablesContainerName string = storage.outputs.tablesContainerName
