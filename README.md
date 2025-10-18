# Azure-Native Medallion Insurance Data Pipeline

**Batch-only Medallion Architecture for Insurance ML Workflows on Azure Synapse Analytics**

[![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com)
[![Synapse](https://img.shields.io/badge/Synapse-164F94?style=for-the-badge&logo=microsoft&logoColor=white)](https://azure.microsoft.com/services/synapse-analytics/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Delta Lake](https://img.shields.io/badge/Delta_Lake-003366?style=for-the-badge&logo=delta&logoColor=white)](https://delta.io/)

## 📋 Overview

Simplified Batch Medallion architecture for insurance ML workflows using **Azure-native services** (no Fabric, no Databricks):

- ✅ **Azure Synapse Analytics** - Spark Pools + Pipelines orchestration
- ✅ **ADLS Gen2** - Delta Lake storage with HNS enabled
- ✅ **Medallion Pattern** - Bronze (raw) → Silver (cleaned + SCD2) → Gold (features)
- ✅ **Schema Validation** - YAML-based contracts with inline enforcement
- ✅ **IaC (Bicep)** - Infrastructure as Code for reproducible deployments
- ✅ **GitHub Actions** - Automated deployment from push (first-time ready)
- ✅ **Zero Manual Setup** - Complete automation including data upload

## 🏗️ Architecture

```mermaid
flowchart LR
  CSV[CSV Samples] -->|Upload to ADLS| Files[(ADLS Files)]
  Files -->|Synapse Spark Ingest| Bronze[Delta Bronze]
  Bronze -->|Clean + YAML Validation| Silver[Delta Silver SCD2]
  Silver -->|Feature Engineering| Gold[Delta Gold]
  Gold --> BI[Power BI / ML]
```

## 📂 Project Structure

```
Azure-Native-Medallion-Insurance-Data-Pipeline/
├── infrastructure/                # Bicep IaC
│   ├── main.bicep                # Main orchestration
│   └── modules/
│       ├── storage.bicep         # ADLS Gen2 + containers
│       ├── keyvault.bicep        # Secrets management
│       ├── synapse.bicep         # Workspace + Spark Pools
│       └── roles.bicep           # RBAC assignments
│
├── synapse/
│   ├── notebooks/                # PySpark notebooks (.ipynb)
│   │   ├── bronze_ingest_*.ipynb
│   │   ├── silver_clean_*.ipynb
│   │   └── gold_create_*.ipynb
│   └── pipelines/
│       └── master_batch_pipeline.json
│
├── config/
│   └── schemas/                  # YAML schema contracts
│       ├── bronze/*.yaml
│       └── silver/*.yaml
│
├── data/
│   └── samples/
│       └── batch/*.csv           # Sample insurance data
│
├── .github/workflows/
│   └── deploy.yml                # Automated deployment
│
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- Azure subscription
- GitHub repository
- Azure CLI installed (for local testing)

### Deployment (Fully Automated)

#### 1. Create Azure Service Principal

```bash
az ad sp create-for-rbac \
  --name "github-actions-insml" \
  --role Contributor \
  --scopes /subscriptions/{your-subscription-id} \
  --sdk-auth
```

Copy the output JSON (you'll need `clientId`, `clientSecret`, `subscriptionId`, `tenantId`).

#### 2. Configure GitHub Secrets

Navigate to **GitHub Repository → Settings → Secrets and variables → Actions**, then add:

**`AZURE_CREDENTIALS`** (JSON format):
```json
{
  "clientId": "your-client-id",
  "clientSecret": "your-client-secret",
  "subscriptionId": "your-subscription-id",
  "tenantId": "your-tenant-id"
}
```

**`AZURE_SUBSCRIPTION_ID`**:
```
your-subscription-id
```

**`AAD_OBJECT_ID`** (Your Azure AD Object ID for Synapse Administrator access):
```
your-aad-object-id
```

To find your AAD Object ID:
```bash
az ad signed-in-user show --query id -o tsv
```

#### 3. Push to GitHub

```bash
git push origin main
```

#### 4. GitHub Actions will automatically:
- **Register required Azure resource providers** (Microsoft.Storage, Synapse, KeyVault, Network)
- Deploy all Azure resources (Synapse, ADLS, Key Vault)
- Upload sample data and schemas to ADLS
- Import Synapse notebooks and pipelines
- Create and start daily triggers

#### 5. Verify Deployment

- Navigate to Azure Portal → Synapse Workspace
- Run `master_batch_pipeline` manually (or wait for daily trigger at 2:00 UTC)
- Check Delta tables in ADLS: `bronze_*`, `silver_*`, `gold_*`

## 🔧 Key Components

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Compute** | Synapse Spark Pools | Distributed PySpark processing |
| **Storage** | ADLS Gen2 (HNS enabled) | Delta Lake tables + files |
| **Orchestration** | Synapse Pipelines | Batch workflow scheduling |
| **Secrets** | Azure Key Vault | Secure credential storage |
| **IaC** | Bicep | Reproducible infrastructure |
| **CI/CD** | GitHub Actions | Automated deployment |

## 📊 Data Flow

### Bronze Layer (Raw Ingestion)
- Read CSV with `inferSchema=false` (all columns as strings)
- Add metadata: `ingestion_timestamp`, `process_id`, `source_file_name`
- Write to Delta: `abfss://tables@<storage>.dfs.core.windows.net/bronze/bronze_*`

### Silver Layer (Cleaned + SCD2)
- Read Bronze Delta tables
- Apply YAML schema transformations (type casting, validation)
- Add SCD Type 2 columns: `effective_from`, `effective_to`, `is_current` for change tracking
- **Note**: Current implementation uses `overwrite` mode with SCD2 columns for change tracking. For full SCD2 history maintenance with version closure, consider implementing `MERGE INTO` strategy in production.
- Write to Delta: `abfss://tables@<storage>.dfs.core.windows.net/silver/silver_*`

### Gold Layer (ML Features)
- Aggregate features by customer/policy
- Time-series analysis (monthly claims summary)
- Write to Delta: `abfss://tables@<storage>.dfs.core.windows.net/gold/gold_*`

## 🔐 Security

- **Managed Identity**: Synapse Workspace MI accesses ADLS/Key Vault
- **RBAC**: Least-privilege role assignments (Synapse Administrator assigned to AAD_OBJECT_ID)
- **Secrets**: All credentials stored in Key Vault
- **Network**: Dev/Test uses open firewall for convenience; Production should restrict to specific IPs or enable Private Endpoints

## 📝 Configuration

### Infrastructure Parameters

Edit `infrastructure/main.bicep` parameters:
- `baseName`: Resource naming prefix (default: `insml`)
- `location`: Azure region (default: resource group location)
- `sparkPoolSize`: Small/Medium/Large (default: `Small`)
- `sparkPoolAutoScale`: Enable/disable auto-scaling (default: `true`)

### Deployment Scripts

The `scripts/` directory contains utility scripts for deployment:

#### `update_notebook_config.py`

Automatically updates storage account placeholders in all Synapse notebooks. This script is executed automatically during GitHub Actions deployment.

**Manual Usage** (if needed):
```bash
# Get storage account name from deployment
STORAGE_ACCOUNT=$(az deployment group show \
  --resource-group rg-insurance-ml-pipeline \
  --name main-12345 \
  --query "properties.outputs.storageAccountName.value" -o tsv)

# Update all notebooks
python scripts/update_notebook_config.py $STORAGE_ACCOUNT
```

**Note:** This script runs automatically in the CI/CD pipeline before importing notebooks to Synapse.

## 🧪 Testing

Run notebooks individually in Synapse Studio:
1. Bronze: `bronze_ingest_claims.ipynb`
2. Silver: `silver_clean_claims.ipynb`
3. Gold: `gold_create_claims_features.ipynb`

Or trigger full pipeline:
```bash
az synapse pipeline run \
  --workspace-name <synapse-workspace> \
  --name master_batch_pipeline
```

## 📖 License

MIT License - see LICENSE file

## 🙏 Acknowledgments

Based on Medallion architecture best practices and Azure-native design patterns.
