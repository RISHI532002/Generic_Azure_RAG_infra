# Azure RAG Infrastructure

Infrastructure as Code (IaC) for deploying a production-ready **Retrieval-Augmented Generation (RAG)** platform on Azure using Bicep.

All resources are deployed within a **private virtual network** with no public internet exposure, following Azure security best practices.

---

## Architecture

```
                         ┌──────────────────────────────────────────────────┐
                         │                  Virtual Network                 │
                         │                                                  │
                         │  ┌──────────────────────────────────────────┐    │
                         │  │     app-integration-subnet (outbound)    │    │
                         │  │  ┌─────────────┐  ┌──────────────────┐   │    │
                         │  │  │ App Service │  │  Function App    │   │    │
                         │  │  │ (Frontend)  │  │  (Embeddings)    │   │    │
                         │  │  └──────┬──────┘  └────────┬─────────┘   │    │
                         │  └─────────┼───────────────────┼────────────┘    │
                         │            │                   │                 │
                         │  ┌─────────┼───────────────────┼────────────┐    │
                         │  │  app-private-endpoint-subnet (inbound)   │    │
                         │  │    Private Endpoints for App & Function  │    │
                         │  └─────────┼───────────────────┼────────────┘    │
                         │            │                   │                 │
                         │  ┌─────────┼───────────────────┼────────────┐    │
                         │  │     private-endpoint-subnet (PaaS)       │    │
                         │  │                                          │    │
                         │  │  ┌─────────┐ ┌──────────┐ ┌───────────┐  │    │
                         │  │  │ Storage │ │ Cosmos DB│ │    ACR    │  │    │
                         │  │  │ (Blobs) │ │ (Chats)  │ │ (Images)  │  │    │
                         │  │  └─────────┘ └──────────┘ └───────────┘  │    │
                         │  │                                          │    │
                         │  │  ┌─────────┐ ┌──────────┐ ┌───────────┐  │    │
                         │  │  │ OpenAI  │ │AI Search │ │  Doc      │  │    │
                         │  │  │ (GPT5.1)│ │ (Vector) │ │  Intel    │  │    │
                         │  │  └─────────┘ └──────────┘ └───────────┘  │    │
                         │  └──────────────────────────────────────────┘    │
                         └──────────────────────────────────────────────────┘
```

---

## RAG Workflow

```
1. Document Ingestion:
   New document → Blob Storage → Blob Trigger → Function App
   → Document Intelligence (extract text) → OpenAI (create embeddings)
   → AI Search (store vectors)

2. User Query:
   User → App Service (frontend) → OpenAI (generate response using context)
   → AI Search (retrieve relevant documents) → Response to user

3. Chat History:
   App Service → Cosmos DB (store/retrieve user chat history as JSON)
```

---

## Project Structure

```
├── main.bicep                        # Main orchestration file (all 6 phases)
├── main.parameters.dev.json          # Parameters for Dev environment
├── main.parameters.qa.json           # Parameters for QA environment
├── main.parameters.prod.json         # Parameters for Prod environment
├── pipelines/
│   └── azure-pipelines.yml           # CI/CD pipeline (Dev → QA → Prod)
└── modules/
    ├── network/
    │   ├── vnet.bicep                # VNet with 3 subnets and NSGs
    │   ├── privateDnsZones.bicep     # Private DNS zones + VNet links
    │   └── private-endpoint.bicep    # Reusable private endpoint module
    ├── compute/
    │   ├── appService.bicep          # App Service (Docker, frontend)
    │   ├── functionApp.bicep         # Function App (Python, blob-triggered)
    │   └── acr.bicep                 # Azure Container Registry
    ├── storage/
    │   └── storage.bicep             # Storage Account (blob containers)
    ├── database/
    │   └── cosmosdb.bicep            # Cosmos DB (user chat history)
    └── ai/
        ├── openai.bicep              # Azure OpenAI (GPT-5.1)
        ├── aiSearch.bicep            # Azure AI Search (vector store)
        └── documentIntelligence.bicep # Document Intelligence (text extraction)
```

---

## Resources Deployed

| Resource | Purpose | Module |
|----------|---------|--------|
| **Virtual Network** | Network isolation with 3 subnets + NSGs | `network/vnet.bicep` |
| **Private DNS Zones** | DNS resolution for private endpoints | `network/privateDnsZones.bicep` |
| **Storage Account** | Blob storage for documents | `storage/storage.bicep` |
| **Azure Container Registry** | Docker image registry for App Service | `compute/acr.bicep` |
| **Cosmos DB** | Store user chat history (JSON, SQL API) | `database/cosmosdb.bicep` |
| **Azure OpenAI** | GPT-5.1 model for chat and embeddings | `ai/openai.bicep` |
| **Azure AI Search** | Vector database for semantic search | `ai/aiSearch.bicep` |
| **Document Intelligence** | Extract text/tables from PDFs and images | `ai/documentIntelligence.bicep` |
| **App Service** | Frontend web app (Docker container from ACR) | `compute/appService.bicep` |
| **Function App** | Blob-triggered Python function for embeddings | `compute/functionApp.bicep` |
| **Private Endpoints** | Secure inbound access to all resources | `network/private-endpoint.bicep` |

---

## Network Design

### Subnets

| Subnet | CIDR (Dev) | Purpose |
|--------|------------|---------|
| `app-integration-subnet` | `10.0.1.0/24` | App Service & Function App outbound VNet integration |
| `app-private-endpoint-subnet` | `10.0.2.0/24` | Private endpoints for App Service & Function App (inbound) |
| `private-endpoint-subnet` | `10.0.3.0/24` | Private endpoints for PaaS services (Storage, OpenAI, etc.) |

### Network Security Groups (NSGs)

- **app-integration-nsg**: Allows HTTPS outbound to VNet
- **app-pe-nsg**: Allows VNet inbound on 443, denies all other inbound
- **pe-nsg**: Allows inbound only from app-integration-subnet on 443, denies all other inbound

### Private DNS Zones

| Zone | Service |
|------|---------|
| `privatelink.azurewebsites.net` | App Service & Function App |
| `privatelink.azurecr.io` | Container Registry |
| `privatelink.openai.azure.com` | Azure OpenAI |
| `privatelink.search.windows.net` | AI Search |
| `privatelink.blob.core.windows.net` | Blob Storage |
| `privatelink.documents.azure.com` | Cosmos DB |
| `privatelink.vaultcore.azure.net` | Key Vault (reserved) |
| `privatelink.cognitiveservices.azure.com` | Document Intelligence |

---

## Security

- **No public internet access** — All resources have `publicNetworkAccess: Disabled`
- **No API keys** — OpenAI and Document Intelligence use `disableLocalAuth: true` (RBAC only)
- **Managed Identity** — App Service and Function App use system-assigned managed identity
- **ACR admin disabled** — Docker images pulled via AcrPull role assignment
- **HTTPS only** — TLS 1.2 minimum, FTPS disabled
- **Network ACLs** — All services have `defaultAction: Deny`
- **Blob soft delete** — 7-day retention for accidental deletion recovery
- **Zone redundancy** — Cosmos DB and Storage Account are zone-redundant

---

## Role Assignments (RBAC)

| Source | Target | Role | Purpose |
|--------|--------|------|---------|
| App Service | ACR | AcrPull | Pull Docker images |
| Function App | Storage | Storage Blob Data Reader | Read documents (blob trigger) |
| App Service | OpenAI | Cognitive Services OpenAI User | Call GPT API |
| Function App | OpenAI | Cognitive Services OpenAI User | Create embeddings |
| Function App | Document Intelligence | Cognitive Services User | Extract text from documents |
| Function App | AI Search | Search Index Data Contributor | Write embeddings to index |
| App Service | AI Search | Search Index Data Reader | Query search index |

---

## Deployment

### Prerequisites

- Azure CLI with Bicep installed
- Azure DevOps service connection with Contributor + User Access Administrator roles
- Resource groups created for each environment
- Azure DevOps environments (`dev`, `qa`, `prod`) with approvals configured on `qa` and `prod`

### Pipeline

The pipeline deploys in 3 stages:

```
Push to main → Dev (auto) → QA (approval required) → Prod (approval required)
```

Configure the pipeline by updating placeholders in `pipelines/azure-pipelines.yml`:

| Placeholder | Description |
|-------------|-------------|
| `<service-connection-name>` | Azure DevOps service connection name |
| `<dev-resource-group>` | Resource group for Dev |
| `<qa-resource-group>` | Resource group for QA |
| `<prod-resource-group>` | Resource group for Prod |
| `<azure-region>` | Target Azure region |

### Manual Deployment

```bash
# Deploy to Dev
az deployment group create \
  --resource-group <dev-resource-group> \
  --template-file main.bicep \
  --parameters main.parameters.dev.json

# Deploy to QA
az deployment group create \
  --resource-group <qa-resource-group> \
  --template-file main.bicep \
  --parameters main.parameters.qa.json

# Deploy to Prod
az deployment group create \
  --resource-group <prod-resource-group> \
  --template-file main.bicep \
  --parameters main.parameters.prod.json
```

---

## Parameters

Update `<project>` in the parameter files with your project name.

| Parameter | Description | Example |
|-----------|-------------|---------|
| `location` | Azure region | `eastus` |
| `vnetName` | Virtual Network name | `rag-dev-vnet` |
| `vnetAddressPrefix` | VNet CIDR | `10.0.0.0/16` |
| `appIntegrationSubnetPrefix` | Outbound subnet CIDR | `10.0.1.0/24` |
| `appPrivateEndpointSubnetPrefix` | App PE subnet CIDR | `10.0.2.0/24` |
| `privateEndpointSubnetPrefix` | PaaS PE subnet CIDR | `10.0.3.0/24` |
| `storageAccountName` | Storage account (alphanumeric, 3-24 chars) | `ragdevsa` |
| `acrName` | Container registry (alphanumeric, 5-50 chars) | `ragdevacr` |
| `cosmosDbAccountName` | Cosmos DB account name | `rag-dev-cosmosdb` |
| `openAiName` | OpenAI account name | `rag-dev-openai` |
| `searchServiceName` | AI Search service name | `rag-dev-search` |
| `documentIntelligenceName` | Document Intelligence name | `rag-dev-docintell` |
| `appServicePlanName` | App Service Plan name | `rag-dev-asp` |
| `appName` | App Service name | `rag-dev-app` |
| `functionAppServicePlanName` | Function App Plan name | `rag-dev-func-asp` |
| `functionAppName` | Function App name | `rag-dev-func` |

---

## Post-Deployment

After infrastructure deployment:

1. **App Service** — Deploy Docker image via Azure DevOps pipeline using `az webapp config container set`
2. **Function App** — Deploy Python code via Azure DevOps pipeline using `func azure functionapp publish` or `AzureFunctionApp@2` task
3. **AI Search** — Create search index with vector fields for embeddings
4. **Cosmos DB** — The `user_chat` container is auto-created with `/userId` partition key
