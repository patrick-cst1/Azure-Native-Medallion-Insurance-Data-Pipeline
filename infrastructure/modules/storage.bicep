// Storage Account (ADLS Gen2) Module

@description('Storage account name')
param storageAccountName string

@description('Location for the storage account')
param location string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true  // Enable Data Lake Gen2 (Hierarchical Namespace)
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

// Blob Service (required for containers)
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

// Container: files (for schemas, samples, config)
resource filesContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'files'
  properties: {
    publicAccess: 'None'
  }
}

// Container: tables (for Delta Lake tables)
resource tablesContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'tables'
  properties: {
    publicAccess: 'None'
  }
}

// Outputs
output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
output filesystemName string = filesContainer.name
output filesContainerName string = filesContainer.name
output tablesContainerName string = tablesContainer.name
output storageAccountPrimaryEndpoints object = storageAccount.properties.primaryEndpoints
