@description('The keyvault to use for storing needed secrets')
param keyVaultName string

@description('The secret name')
param secretName string

@description('The secret value')
@secure()
param secretValue string

@description('The secret description')
@secure()
param secretDescription string

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: secretName
  parent: keyVault
  properties: {
    contentType: secretDescription
    value: secretValue
    attributes: {
      enabled: true
    }
  }
}
