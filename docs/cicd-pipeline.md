# n8n Azure Container Apps CI/CD Pipeline

This document provides a detailed overview of the CI/CD pipeline architecture for deploying n8n on Azure Container Apps.

## Pipeline Overview

The pipeline follows a multi-environment deployment strategy with automated infrastructure provisioning, security management, and testing. It uses Azure DevOps with Bicep templates for Infrastructure as Code.

## Mermaid Diagram

```mermaid
graph TB
    %% Pipeline Triggers
    subgraph "Pipeline Triggers"
        A[Code Push] --> B[Pipeline Trigger]
        B --> C{Branch Check}
        C -->|main/master/feature/*| D[Pipeline Starts]
        C -->|other branches| E[No Action]
    end

    %% Development Stage
    subgraph "Development Stage (Auto Deploy)"
        D --> F[PreConfigDev Job]
        F --> G[Generate Random Passwords]
        G --> H[DeployToDev Job]
        H --> I[Build & Validate Bicep]
        I --> J[Dry Run Analysis]
        J --> K[Deploy Infrastructure]
        K --> L[PostConfigDev Job]
        L --> M[TestDev Job]
        M --> N[Health Check Test]
    end

    %% Acceptance Stage
    subgraph "Acceptance Stage (Approval Required)"
        N --> O{Dev Success?}
        O -->|Yes| P[Approval Gate: ACC]
        P --> Q[DeployToAcc Job]
        Q --> R[Build & Validate Bicep]
        R --> S[Dry Run Analysis]
        S --> T[Deploy Infrastructure]
        T --> U[PostConfigAcc Job]
        U --> V[TestAcc Job]
        V --> W[Health Check Test]
    end

    %% Production Stage
    subgraph "Production Stage (Approval Required)"
        W --> X{Acc Success?}
        X -->|Yes| Y[Approval Gate: PRD]
        Y --> Z[PreConfigPrd Job]
        Z --> AA[Generate Random Passwords]
        AA --> BB[DeployToPrd Job]
        BB --> CC[Build & Validate Bicep]
        CC --> DD[Dry Run Analysis]
        DD --> EE[Deploy Infrastructure]
        EE --> FF[PostConfigPrd Job]
        FF --> GG[TestPrd Job]
        GG --> HH[Health Check Test]
    end

    %% Success/Failure Paths
    HH --> II[Pipeline Complete]
    O -->|No| JJ[Pipeline Failed]
    X -->|No| JJ
    P -->|Rejected| JJ
    Y -->|Rejected| JJ

    %% Styling
    classDef success fill:#d4edda,stroke:#155724,color:#155724
    classDef failure fill:#f8d7da,stroke:#721c24,color:#721c24
    classDef approval fill:#fff3cd,stroke:#856404,color:#856404
    classDef process fill:#d1ecf1,stroke:#0c5460,color:#0c5460
    classDef security fill:#e2e3e5,stroke:#383d41,color:#383d41

    class II success
    class JJ failure
    class P,Y approval
    class H,Q,BB process
    class G,AA security
```

## Detailed Stage Breakdown

### 1. Development Stage

```mermaid
graph LR
    subgraph "Dev Stage Jobs"
        A[PreConfigDev] --> B[DeployToDev]
        B --> C[PostConfigDev]
        C --> D[TestDev]
    end

    subgraph "PreConfigDev Steps"
        A1[Generate PostgreSQL Password] --> A2[Generate n8n Encryption Key]
        A2 --> A3[Store as Pipeline Variables]
    end

    subgraph "DeployToDev Steps"
        B1[Build Bicep Files] --> B2[Validate Infrastructure]
        B2 --> B3[Dry Run Analysis]
        B3 --> B4[Deploy Infrastructure]
        B4 --> B5[Get Deployment Outputs]
    end

    subgraph "PostConfigDev Steps"
        C1[Clear Sensitive Variables]
    end

    subgraph "TestDev Steps"
        D1[Wait for Container App] --> D2[Health Check Test]
    end
```

### 2. Acceptance Stage

```mermaid
graph LR
    subgraph "Acc Stage Jobs"
        A[DeployToAcc] --> B[PostConfigAcc]
        B --> C[TestAcc]
    end

    subgraph "DeployToAcc Steps"
        A1[Build Bicep Files] --> A2[Validate Infrastructure]
        A2 --> A3[Dry Run Analysis]
        A3 --> A4[Deploy Infrastructure]
        A4 --> A5[Get Deployment Outputs]
    end

    subgraph "PostConfigAcc Steps"
        B1[Clear Sensitive Variables]
    end

    subgraph "TestAcc Steps"
        C1[Wait for Container App] --> C2[Health Check Test]
    end
```

### 3. Production Stage

```mermaid
graph LR
    subgraph "Prd Stage Jobs"
        A[PreConfigPrd] --> B[DeployToPrd]
        B --> C[PostConfigPrd]
        C --> D[TestPrd]
    end

    subgraph "PreConfigPrd Steps"
        A1[Generate PostgreSQL Password] --> A2[Generate n8n Encryption Key]
        A2 --> A3[Store as Pipeline Variables]
    end

    subgraph "DeployToPrd Steps"
        B1[Build Bicep Files] --> B2[Validate Infrastructure]
        B2 --> B3[Dry Run Analysis]
        B3 --> B4[Deploy Infrastructure]
        B4 --> B5[Get Deployment Outputs]
    end

    subgraph "PostConfigPrd Steps"
        C1[Clear Sensitive Variables]
    end

    subgraph "TestPrd Steps"
        D1[Wait for Container App] --> D2[Health Check Test]
    end
```

## Security Flow

```mermaid
graph TB
    subgraph "Password Generation & Storage"
        A[OpenSSL Random Generation] --> B[PostgreSQL Password]
        A --> C[n8n Encryption Key]
        B --> D[Store as Pipeline Secret]
        C --> E[Store as Pipeline Secret]
        D --> F[Pass to Bicep Template]
        E --> F
    end

    subgraph "Infrastructure Deployment"
        F --> G[PostgreSQL Server Creation]
        F --> H[Container App Configuration]
        G --> I[Key Vault Secret Storage]
        H --> I
        I --> J[Deployment Complete]
    end

    subgraph "Post-Deployment Security"
        J --> K[Clear Pipeline Variables]
        K --> L[Secrets Stored in Key Vault]
        L --> M[Container App Access Policy]
    end

    classDef security fill:#e2e3e5,stroke:#383d41,color:#383d41
    classDef process fill:#d1ecf1,stroke:#0c5460,color:#0c5460
    classDef storage fill:#d4edda,stroke:#155724,color:#155724

    class A,B,C,D,E security
    class F,G,H,I process
    class K,L,M storage
```

## Infrastructure Deployment Flow

```mermaid
graph TB
    subgraph "Azure Resources"
        A[Resource Group] --> B[Log Analytics Workspace]
        A --> C[Container Apps Environment]
        A --> D[PostgreSQL Flexible Server]
        A --> E[PostgreSQL Database]
        A --> F[n8n Container App]
        A --> G[Key Vault Access Policy]
        A --> H[Key Vault Secrets]
    end

    subgraph "Deployment Process"
        I[Bicep Template] --> J[Build Bicep Files]
        J --> K[Validate Resources]
        K --> L[What-If Analysis]
        L --> M[Deploy Resources]
        M --> N[Configure Container App]
        N --> O[Setup Database Connection]
        O --> P[Configure Scaling Rules]
        P --> Q[Setup Key Vault Integration]
    end

    subgraph "Post-Deployment"
        R[Health Check] --> S[Deployment Success]
    end

    I --> A
    M --> B
    M --> C
    M --> D
    M --> E
    M --> F
    M --> G
    M --> H
    Q --> R
```

## Environment Configuration

```mermaid
graph LR
    subgraph "Environment Configs"
        A[config-infra-dev.yml] --> B[Development Settings]
        C[config-infra-acc.yml] --> D[Acceptance Settings]
        E[config-infra-prd.yml] --> F[Production Settings]
    end

    subgraph "Development"
        B --> B1[CPU: 1.0, Memory: 2Gi]
        B --> B2[Min: 1, Max: 1 replicas]
        B --> B3[Key Vault: n8n-kv-dev]
        B --> B4[Resource Group: n8n-rg-dev]
    end

    subgraph "Acceptance"
        D --> D1[CPU: 1.0, Memory: 2Gi]
        D --> D2[Min: 1, Max: 1 replicas]
        D --> D3[Key Vault: n8n-kv-acc]
        D --> D4[Resource Group: n8n-rg-acc]
    end

    subgraph "Production"
        F --> F1[CPU: 1.0, Memory: 2Gi]
        F --> F2[Min: 1, Max: 1 replicas]
        F --> F3[Key Vault: n8n-kv-prd]
        F --> F4[Resource Group: n8n-rg-prd]
    end
```

## Pipeline Templates

```mermaid
graph TB
    subgraph "Pipeline Templates"
        A[provision-infra.yml] --> A1[Infrastructure Deployment]
        B[run-health-check.yml] --> B1[Health Verification]
    end

    subgraph "Template Parameters"
        A1 --> A2[Azure Subscription]
        A1 --> A3[Resource Group]
        A1 --> A4[Environment Config]
        A1 --> A5[Key Vault Name]
        A1 --> A6[Container Settings]
        A1 --> A7[PostgreSQL Settings]
        
        B1 --> B2[Container App Name]
        B1 --> B3[Resource Group]
        B1 --> B4[Wait Time]
    end

    subgraph "Template Functions"
        A1 --> A8[Build Bicep Files]
        A1 --> A9[Validate Infrastructure]
        A1 --> A10[Dry Run Analysis]
        A1 --> A11[Deploy Resources]
        A1 --> A12[Get Outputs]
        
        B1 --> B5[Wait for Container App]
        B1 --> B6[Test HTTP Response]
        B1 --> B7[Verify Health Status]
    end
```

## Infrastructure Components (main.bicep)

```mermaid
graph TB
    subgraph "Core Infrastructure"
        A[Log Analytics Workspace] --> B[Container Apps Environment]
        B --> C[n8n Container App]
        D[PostgreSQL Flexible Server] --> E[PostgreSQL Database]
    end

    subgraph "Security Components"
        F[Key Vault Access Policy] --> G[Container App Identity]
        H[PostgreSQL Password Secret] --> I[Key Vault Storage]
        J[n8n Encryption Key Secret] --> I
    end

    subgraph "Container App Configuration"
        C --> K[Environment Variables]
        C --> L[Scaling Rules]
        C --> M[Ingress Configuration]
        C --> N[Resource Allocation]
    end

    subgraph "Database Configuration"
        E --> O[SSL Enabled]
        E --> P[UTF8 Charset]
        E --> Q[Public Schema]
    end

    subgraph "Monitoring"
        A --> R[App Logs Configuration]
        R --> S[Log Analytics Integration]
    end
```

## Success Criteria

```mermaid
graph TB
    subgraph "Pipeline Success Criteria"
        A[All Stages Complete] --> B[Infrastructure Deployed]
        B --> C[Passwords Generated & Stored]
        C --> D[Key Vault Integration Active]
        D --> E[Health Checks Pass]
        E --> F[n8n Accessible]
        F --> G[Pipeline Success]
    end

    subgraph "Failure Points"
        H[Branch Not Supported] --> I[Pipeline Skipped]
        J[Infrastructure Validation Failed] --> K[Deployment Stopped]
        L[Password Generation Failed] --> M[Deployment Failed]
        N[Health Check Failed] --> O[Deployment Failed]
        P[Approval Rejected] --> Q[Stage Skipped]
        R[Dry Run Errors] --> S[Deployment Blocked]
    end

    classDef success fill:#d4edda,stroke:#155724,color:#155724
    classDef failure fill:#f8d7da,stroke:#721c24,color:#721c24

    class G success
    class I,K,M,O,Q,S failure
```

## Cost Optimization

```mermaid
graph LR
    subgraph "Cost Optimization Features"
        A[Configurable Scaling] --> B[Environment-Specific Settings]
        C[PostgreSQL Burstable Tier] --> D[Cost-Effective Database]
        E[Log Analytics Integration] --> F[Centralized Monitoring]
        G[Key Vault Integration] --> H[Secure Secret Management]
    end

    subgraph "Cost Savings"
        B --> I[Optimized Resource Allocation]
        D --> J[Pay-per-use Database]
        F --> K[Efficient Logging]
        H --> L[No Manual Secret Management]
    end

    subgraph "Monthly Estimates"
        M[Development: $40-50] --> N[1 CPU, 2Gi Memory]
        O[Acceptance: $40-50] --> P[1 CPU, 2Gi Memory]
        Q[Production: $40-50] --> R[1 CPU, 2Gi Memory]
    end
```

## Security Architecture

```mermaid
graph TB
    subgraph "Security Layers"
        A[Code Repository] --> B[Azure DevOps]
        B --> C[Pipeline Security]
        C --> D[Infrastructure Security]
        D --> E[Application Security]
    end

    subgraph "Security Features"
        C --> C1[Dynamic Password Generation]
        C --> C2[Pipeline Variable Encryption]
        C --> C3[Approval Gates]
        
        D --> D1[SSL/TLS Encryption]
        D --> D2[System-Assigned Identity]
        D --> D3[Key Vault Integration]
        
        E --> E1[n8n Authentication]
        E --> E2[Database Encryption]
        E --> E3[Encryption Key Management]
    end

    classDef security fill:#e2e3e5,stroke:#383d41,color:#383d41
    class C1,C2,C3,D1,D2,D3,E1,E2,E3 security
```

## Key Features

### Infrastructure as Code
- **Bicep Templates**: Complete infrastructure definition in `infrastructure/main.bicep`
- **Modular Design**: Separate Key Vault modules for access policies and secrets
- **Environment-Specific Configs**: Dedicated configuration files for dev, acc, and prd

### Security
- **Dynamic Password Generation**: OpenSSL-based random password generation
- **Key Vault Integration**: Secure storage of PostgreSQL passwords and n8n encryption keys
- **System-Assigned Identity**: Container App identity for Key Vault access
- **Pipeline Variable Encryption**: Sensitive data encrypted in pipeline variables

### Deployment Strategy
- **Multi-Environment**: Separate stages for dev, acceptance, and production
- **Approval Gates**: Manual approval required for acc and prd environments
- **Dry Run Support**: What-if analysis before actual deployment
- **Health Checks**: Automated testing of deployed applications

### Monitoring & Logging
- **Log Analytics Integration**: Centralized logging and monitoring
- **Health Check Templates**: Automated verification of deployment success
- **Deployment Outputs**: Capture and display of deployment results

---

## Pipeline Summary

This CI/CD pipeline provides:

- **Multi-environment deployment** with approval gates for production stages
- **Infrastructure as Code** using Bicep templates with modular design
- **Dynamic password generation** with Azure Key Vault integration
- **Automated testing** and health checks
- **Cost optimization** with configurable resource allocation
- **Security best practices** with encrypted secrets and system-assigned identities

The pipeline ensures reliable, secure, and cost-effective deployment of n8n across development, acceptance, and production environments using Azure Container Apps and PostgreSQL Flexible Server.
