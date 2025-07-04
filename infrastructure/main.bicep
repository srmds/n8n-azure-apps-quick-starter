@description('The name of the Container App Environment')
param environmentName string = 'n8n-env'

@description('The name of the Container App')
param containerAppName string = 'n8n-app'

@description('The name of the PostgreSQL Flexible Server')
param postgresServerName string = 'n8n-postgres'

@description('PostgreSQL admin username')
param postgresAdminUsername string = 'n8nadmin'

@description('PostgreSQL admin password')
@secure()
param postgresAdminPassword string

@description('N8N encryption key')
@secure()
param n8nEncryptionKey string

@description('Container CPU allocation')
param containerCpu string = '0.5'

@description('Container memory allocation')
param containerMemory string = '1Gi'

@description('Minimum number of replicas')
param minReplicas string = '0' // will be casted to int before usage

@description('Maximum number of replicas')
param maxReplicas string = '1' // will be casted to int before usage

@description('n8n Docker image to deploy')
param n8nImage string = 'docker.io/n8nio/n8n:latest'

@description('The location into which regionally scoped resources should be deployed (default: westeurope)')
param location string = resourceGroup().location

@description('The pipeline Build ID')
param buildId string

@description('The keyvault name')
param keyVaultName string

// Variables
var postgresServerFqdn = '${postgresServerName}.postgres.database.azure.com'

// Log Analytics Workspace for monitoring
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'n8n-law-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Container Apps Environment
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: postgresServerName
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: postgresAdminUsername
    administratorLoginPassword: postgresAdminPassword
    version: '14'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    network: {
      delegatedSubnetResourceId: ''
      privateDnsZoneArmResourceId: ''
    }
  }
}

// PostgreSQL Database
resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = {
  parent: postgresServer
  name: 'n8n'
  properties: {
    charset: 'utf8'
    collation: 'en_US.utf8'
  }
}

// Container App for n8n
resource n8nContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 5678
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      secrets: [
        {
          name: 'postgres-password'
          value: postgresAdminPassword
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'n8n'
          image: n8nImage
          env: [
            {
              name: 'NODE_ENV'
              value: 'production'
            }
            {
              name: 'N8N_PROTOCOL'
              value: 'http'
            }
            {
              name: 'N8N_PORT'
              value: '5678'
            }
            {
              name: 'GENERIC_TIMEZONE'
              value: 'Europe/Amsterdam'
            }
            {
              name: 'DB_TYPE'
              value: 'postgresdb'
            }
            {
              name: 'DB_POSTGRESDB_HOST'
              value: postgresServerFqdn
            }
            {
              name: 'DB_POSTGRESDB_PORT'
              value: '5432'
            }
            {
              name: 'DB_POSTGRESDB_DATABASE'
              value: 'n8n'
            }
            {
              name: 'DB_POSTGRESDB_USER'
              value: postgresAdminUsername
            }
            {
              name: 'DB_POSTGRESDB_PASSWORD'
              value: postgresAdminPassword
            }
            {
              name: 'DB_POSTGRESDB_SCHEMA'
              value: 'public'
            }
            {
              name: 'DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED'
              value: 'true'
            }
            {
              name: 'N8N_LOG_LEVEL'
              value: 'info'
            }
            {
              name: 'N8N_DIAGNOSTICS_ENABLED'
              value: 'false'
            }
            {
              name: 'N8N_METRICS'
              value: 'false'
            }
            {
              name: 'N8N_USER_MANAGEMENT_DISABLED'
              value: 'false'
            }
            {
              name: 'N8N_BASIC_AUTH_ACTIVE'
              value: 'true'
            }
            {
              name: 'TRUST_PROXY'
              value: 'true'
            }
            {
              name: 'N8N_RUNNERS_ENABLED'
              value: 'true'
            }
            {
              name: 'WEBHOOK_URL'
              value: 'https://${containerAppName}.${containerAppEnvironment.properties.defaultDomain}'
            }
            {
              name: 'DB_POSTGRESDB_SSL_ENABLED'
              value: 'true'
            }
            {
              name: 'AZURE_TENANT_ID'
              value: subscription().tenantId
            }
            {
              name: 'APPSETTING_WEBSITE_SITE_NAME'
              value: 'azcli-workaround'
            }
            {
              name: 'N8N_ENCRYPTION_KEY'
              value: n8nEncryptionKey
            }
          ]

          resources: {
            cpu: json(containerCpu)
            memory: containerMemory
          }
        }
      ]
      scale: {
        minReplicas: int(minReplicas)
        maxReplicas: int(maxReplicas)
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
          {
            name: 'cpu-scaling'
            custom: {
              type: 'cpu'
              metadata: {
                type: 'Utilization'
                value: '70'
              }
            }
          }
        ]
      }
    }
  }
}

// Create keyvault policy so that the container app can access the keyvault to read secrets
module appKeyVaultAccessPolicyModule 'keyvault/kv_access_policy.bicep' = {
  name: 'appAccessPolicy-${buildId}'
  params: {
    keyVaultName: keyVaultName
    principalId: n8nContainerApp.identity.principalId
  }
}

// Create initial postgres db admin password secret
module postgresAdminPasswordSecret 'keyvault/kv_secrets.bicep' = {
  name: 'postgresAdminPasswordSecret-${buildId}'
  params: {
    keyVaultName: keyVaultName
    secretName: '${postgresServerName}-admin-password'
    secretValue: postgresAdminPassword
    secretDescription: 'Admin password of ${postgresServerName}'
  }
}

// Create initial n8n encryption key secret
module n8nEncryptionKeySecret 'keyvault/kv_secrets.bicep' = {
  name: 'n8nEncryptionKeySecret-${buildId}'
  params: {
    keyVaultName: keyVaultName
    secretName: '${containerAppName}-encryption-key'
    secretValue: n8nEncryptionKey
    secretDescription: 'Encryption key for n8n'
  }
}

// Outputs
output containerAppUrl string = n8nContainerApp.properties.configuration.ingress.fqdn
output postgresServerFqdn string = postgresServerFqdn
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id 
