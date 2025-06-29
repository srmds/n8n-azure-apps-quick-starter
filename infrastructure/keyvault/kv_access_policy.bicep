@description('The keyvault to use for reading needed secrets')
param keyVaultName string

@description('The container app principal ID to grant access to keyvault')
param principalId string

// Create keyvault access policy based on container app identity so that the container app can read the needed secrets from the concerning keyvault
resource accessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2021-11-01-preview' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: principalId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}
