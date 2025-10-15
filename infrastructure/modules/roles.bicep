// RBAC Role Assignments Module

@description('Synapse Workspace Managed Identity Principal ID')
param synapsePrincipalId string

@description('Storage Account Resource ID')
param storageAccountId string

@description('Key Vault Name')
param keyVaultName string

// Role Definition IDs (built-in Azure roles)
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

// Reference existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: split(storageAccountId, '/')[8]
}

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Grant Synapse MI: Storage Blob Data Contributor on Storage Account
resource synapseStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(synapsePrincipalId, storageAccountId, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: synapsePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Grant Synapse MI: Key Vault Secrets User on Key Vault
resource synapseKeyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(synapsePrincipalId, keyVault.id, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: synapsePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output storageBlobDataContributorAssigned bool = true
output keyVaultSecretsUserAssigned bool = true
