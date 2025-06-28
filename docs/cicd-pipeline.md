# n8n Azure Container Apps CI/CD Pipeline

This document provides a detailed overview of the CI/CD pipeline architecture for deploying n8n on Azure Container Apps.

## Pipeline Overview

The pipeline follows a multi-environment deployment strategy with automated infrastructure provisioning, security management, and testing.

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
        D --> F[Deploy to Dev]
        F --> G[Generate Random Password]
        G --> H[Store in Key Vault]
        H --> I[Build Bicep Files]
        I --> J[Validate Infrastructure]
        J --> K[Dry Run Analysis]
        K --> L[Deploy Infrastructure]
        L --> M[Configure DNS & SSL]
        M --> N[Health Check Test]
    end

    %% Acceptance Stage
    subgraph "Acceptance Stage (Approval Required)"
        N --> O{Dev Success?}
        O -->|Yes| P[Approval Gate: ACC]
        P --> Q[Deploy to Acceptance]
        Q --> R[Generate Random Password]
        R --> S[Store in Key Vault]
        S --> T[Build Bicep Files]
        T --> U[Validate Infrastructure]
        U --> V[Dry Run Analysis]
        V --> W[Deploy Infrastructure]
        W --> X[Configure DNS & SSL]
        X --> Y[Health Check Test]
    end

    %% Production Stage
    subgraph "Production Stage (Approval Required)"
        Y --> Z{Acc Success?}
        Z -->|Yes| AA[Approval Gate: PRD]
        AA --> BB[Deploy to Production]
        BB --> CC[Generate Random Password]
        CC --> DD[Store in Key Vault]
        DD --> EE[Build Bicep Files]
        EE --> FF[Validate Infrastructure]
        FF --> GG[Dry Run Analysis]
        GG --> HH[Deploy Infrastructure]
        HH --> II[Configure DNS & SSL]
        II --> JJ[Health Check Test]
    end

    %% Success/Failure Paths
    JJ --> KK[Pipeline Complete]
    O -->|No| LL[Pipeline Failed]
    Z -->|No| LL
    P -->|Rejected| LL
    AA -->|Rejected| LL

    %% Styling
    classDef success fill:#d4edda,stroke:#155724,color:#155724
    classDef failure fill:#f8d7da,stroke:#721c24,color:#721c24
    classDef approval fill:#fff3cd,stroke:#856404,color:#856404
    classDef process fill:#d1ecf1,stroke:#0c5460,color:#0c5460
    classDef security fill:#e2e3e5,stroke:#383d41,color:#383d41

    class KK success
    class LL failure
    class P,AA approval
    class F,Q,BB process
    class G,R,CC,H,S,DD security
```

## Detailed Stage Breakdown

### 1. Development Stage

```mermaid
graph LR
    subgraph "Dev Stage Jobs"
        A[Deploy Job] --> B[Config DNS Job]
        B --> C[Test Job]
    end

    subgraph "Deploy Job Steps"
        A1[Generate Password] --> A2[Store in Key Vault]
        A2 --> A3[Build Bicep]
        A3 --> A4[Validate]
        A4 --> A5[Dry Run]
        A5 --> A6[Deploy]
        A6 --> A7[Get Outputs]
    end

    subgraph "DNS Job Steps"
        B1[Configure Domain] --> B2[Setup SSL]
    end

    subgraph "Test Job Steps"
        C1[Health Check] --> C2[Verify Deployment]
    end
```

### 2. Acceptance Stage

```mermaid
graph LR
    subgraph "Acc Stage Jobs"
        A[DeployInfrastructureAcc] --> B[ConfigDNSAcc]
        B --> C[TestAcc]
    end

    subgraph "DeployInfrastructureAcc Steps"
        A1[Generate Password] --> A2[Store in Key Vault]
        A2 --> A3[Build Bicep]
        A3 --> A4[Validate]
        A4 --> A5[Dry Run]
        A5 --> A6[Deploy]
        A6 --> A7[Get Outputs]
    end

    subgraph "ConfigDNSAcc Steps"
        B1[Configure Domain] --> B2[Setup SSL]
    end

    subgraph "TestAcc Steps"
        C1[Health Check] --> C2[Verify Deployment]
    end
```

### 3. Production Stage

```mermaid
graph LR
    subgraph "Prd Stage Jobs"
        A[DeployInfrastructurePrd] --> B[ConfigDNSPrd]
        B --> C[TestPrd]
    end

    subgraph "DeployInfrastructurePrd Steps"
        A1[Generate Password] --> A2[Store in Key Vault]
        A2 --> A3[Build Bicep]
        A3 --> A4[Validate]
        A4 --> A5[Dry Run]
        A5 --> A6[Deploy]
        A6 --> A7[Get Outputs]
    end

    subgraph "ConfigDNSPrd Steps"
        B1[Configure Domain] --> B2[Setup SSL]
    end

    subgraph "TestPrd Steps"
        C1[Health Check] --> C2[Verify Deployment]
    end
```

## Security Flow

```mermaid
graph TB
    subgraph "Password Generation & Storage"
        A[OpenSSL Random Generation] --> B[25-Character Password]
        B --> C[Store as Pipeline Secret]
        C --> D{Key Vault Configured?}
        D -->|Yes| E[Create Key Vault if needed]
        D -->|No| F[Skip Key Vault]
        E --> G[Store in Key Vault]
        G --> H[Secret URL Generated]
        F --> I[Use Pipeline Secret Only]
    end

    subgraph "Password Usage"
        H --> J[Pass to Bicep Template]
        I --> J
        J --> K[PostgreSQL Server Creation]
        K --> L[Container App Configuration]
        L --> M[Deployment Complete]
    end

    classDef security fill:#e2e3e5,stroke:#383d41,color:#383d41
    classDef process fill:#d1ecf1,stroke:#0c5460,color:#0c5460
    classDef decision fill:#fff3cd,stroke:#856404,color:#856404

    class A,B,C,G,H security
    class J,K,L,M process
    class D decision
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
        A --> G[Key Vault]
    end

    subgraph "Deployment Process"
        H[Bicep Template] --> I[Validate Resources]
        I --> J[What-If Analysis]
        J --> K[Deploy Resources]
        K --> L[Configure Container App]
        L --> M[Setup Database Connection]
        M --> N[Configure Scaling Rules]
    end

    subgraph "Post-Deployment"
        O[Custom Domain Setup] --> P[SSL Certificate]
        P --> Q[Health Check]
        Q --> R[Deployment Success]
    end

    H --> A
    K --> B
    K --> C
    K --> D
    K --> E
    K --> F
    K --> G
    N --> O
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
        B --> B2[Min: 0, Max: 1 replicas]
        B --> B3[Key Vault: n8n-kv-dev]
        B --> B4[Domain: n8n-dev.yourdomain.com]
    end

    subgraph "Acceptance"
        D --> D1[CPU: 1.0, Memory: 2Gi]
        D --> D2[Min: 1, Max: 1 replicas]
        D --> D3[Key Vault: n8n-kv-acc]
        D --> D4[Domain: n8n-acc.yourdomain.com]
    end

    subgraph "Production"
        F --> F1[CPU: 2.0, Memory: 2Gi]
        F --> F2[Min: 1, Max: 2 replicas]
        F --> F3[Key Vault: n8n-kv-prd]
        F --> F4[Domain: n8n.yourdomain.com]
    end
```

## Pipeline Templates

```mermaid
graph TB
    subgraph "Pipeline Templates"
        A[provision-infra.yml] --> A1[Infrastructure Deployment]
        B[configure-dns.yml] --> B1[DNS Configuration]
        C[run-health-check.yml] --> C1[Health Verification]
        D[keyvault-storage.yml] --> D1[Secret Storage]
        E[keyvault-retrieval.yml] --> E1[Secret Retrieval]
    end

    subgraph "Template Parameters"
        A1 --> A2[Azure Subscription]
        A1 --> A3[Resource Group]
        A1 --> A4[Environment Config]
        A1 --> A5[Key Vault Name]
        
        B1 --> B2[Domain Name]
        B1 --> B3[Container App]
        
        C1 --> C2[Health Check URL]
        C1 --> C3[Wait Time]
        
        D1 --> D2[Key Vault Name]
        D1 --> D3[Secret Name]
        D1 --> D4[Secret Value]
        
        E1 --> E2[Key Vault Name]
        E1 --> E3[Secret Name]
        E1 --> E4[Output Variable]
    end
```

## Success Criteria

```mermaid
graph TB
    subgraph "Pipeline Success Criteria"
        A[All Stages Complete] --> B[Infrastructure Deployed]
        B --> C[Passwords Generated & Stored]
        C --> D[DNS Configured]
        D --> E[SSL Certificates Active]
        E --> F[Health Checks Pass]
        F --> G[n8n Accessible]
        G --> H[Pipeline Success]
    end

    subgraph "Failure Points"
        I[Branch Not Supported] --> J[Pipeline Skipped]
        K[Infrastructure Validation Failed] --> L[Deployment Stopped]
        M[Key Vault Creation Failed] --> N[Password Storage Failed]
        O[Health Check Failed] --> P[Deployment Failed]
        Q[Approval Rejected] --> R[Stage Skipped]
    end

    classDef success fill:#d4edda,stroke:#155724,color:#155724
    classDef failure fill:#f8d7da,stroke:#721c24,color:#721c24

    class H success
    class J,L,N,P,R failure
```

## Cost Optimization

```mermaid
graph LR
    subgraph "Cost Optimization Features"
        A[Scale to Zero] --> B[Dev Environment]
        C[Auto Scaling] --> D[Production Load]
        E[Pay per Use] --> F[Container Apps]
        G[Shared Resources] --> H[Log Analytics]
    end

    subgraph "Cost Savings"
        B --> I[~$0 when idle]
        D --> J[Only pay for usage]
        F --> K[No idle charges]
        H --> L[Centralized logging]
    end

    subgraph "Monthly Estimates"
        M[Development: $30-40] --> N[Scales to $0 when idle]
        O[Acceptance: $40-50] --> P[Always available]
        Q[Production: $55-75] --> R[High availability]
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
        C --> C2[Key Vault Integration]
        C --> C3[Approval Gates]
        
        D --> D1[SSL/TLS Encryption]
        D --> D2[Private Networking]
        D --> D3[RBAC Access Control]
        
        E --> E1[n8n Authentication]
        E --> E2[Database Encryption]
        E --> E3[Audit Logging]
    end

    classDef security fill:#e2e3e5,stroke:#383d41,color:#383d41
    class C1,C2,C3,D1,D2,D3,E1,E2,E3 security
```

---

## Pipeline Summary

This CI/CD pipeline provides:

- **Multi-environment deployment** with approval gates for production stages
- **Infrastructure as Code** using Bicep templates
- **Dynamic password generation** with Azure Key Vault integration
- **Automated testing** and health checks
- **Cost optimization** with scale-to-zero capabilities
- **Security best practices** with encrypted secrets and SSL/TLS

The pipeline ensures reliable, secure, and cost-effective deployment of n8n across development, acceptance, and production environments.
