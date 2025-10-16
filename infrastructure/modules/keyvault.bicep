// Key Vault Module

@description('Key Vault name')
param keyVaultName string

@description('Location for Key Vault')
param location string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true  // Use RBAC instead of access policies
    softDeleteRetentionInDays: 7
    // Note: enablePurgeProtection is omitted - once enabled, it cannot be disabled
    // Azure will use default behavior based on subscription settings
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Outputs
output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
