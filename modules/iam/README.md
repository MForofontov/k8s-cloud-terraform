# Cloud Identity & Access Management (IAM) Module

This Terraform module creates and manages identity and access management (IAM) resources across multiple cloud providers (AWS, Azure, GCP) for Kubernetes workloads. It provides a consistent interface for implementing secure service account integrations and workload identity federation.

## Features

- **Multi-Cloud Support**: Works with AWS, Azure, and GCP through a unified interface
- **Kubernetes Integration**: Seamless service account configuration for pod workloads
- **Workload Identity Federation**: Supports modern workload identity across all providers:
  - AWS IAM Roles for Service Accounts (IRSA)
  - Azure Workload Identity
  - GCP Workload Identity
- **Least Privilege**: Fine-grained access control for Kubernetes applications
- **Secure Defaults**: Implements security best practices for each cloud provider
- **Optional K8s Resource Creation**: Can automatically create Kubernetes service accounts

## Supported Features

| Feature | AWS | Azure | GCP | Description |
|---------|-----|-------|-----|-------------|
| **Service Accounts** | ✅ | ✅ | ✅ | Cloud provider and Kubernetes service accounts |
| **Roles/Policies** | ✅ | ✅ | ✅ | Permissions and access policies |
| **Workload Identity** | ✅ | ✅ | ✅ | Secure pod-to-cloud authentication |
| **Custom Policies** | ✅ | ✅ | ✅ | Support for custom IAM policies |
| **Cross-Account Access** | ✅ | ❌ | ✅ | Access resources in different accounts/projects |
| **Managed Identities** | ❌ | ✅ | ❌ | Azure-specific managed identities |
| **Service Account Keys** | ❌ | ❌ | ✅ | GCP service account key management |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.82.0 |
| azuread | ~> 3.4.0 |
| azurerm | ~> 4.37.0 |
| google | ~> 6.43.0 |
| kubernetes | ~> 2.37.1 |
| kubectl | ~> 1.19.0 |

## Usage

### AWS Example (IRSA)

```hcl
module "eks_pod_identity" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/iam"

  cloud_provider = "aws"
  name_prefix    = "prod"
  environment    = "production"
  
  # Kubernetes service account configuration
  k8s_namespace           = "app-namespace"
  k8s_service_account_name = "app-service-account"
  create_k8s_service_account = true
  
  # AWS IAM configuration
  aws_oidc_provider_arn = module.eks.oidc_provider_arn
  aws_policies = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ]
  
  # Additional inline policies
  aws_inline_policies = {
    "custom-policy" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect    = "Allow"
          Action    = ["secretsmanager:GetSecretValue"]
          Resource  = ["arn:aws:secretsmanager:*:*:secret:app/*"]
        }
      ]
    })
  }
  
  tags = {
    Application = "payment-processor"
    Team        = "platform"
  }
}
```

### Azure Example (Workload Identity)

```hcl
module "aks_pod_identity" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/iam"

  cloud_provider = "azure"
  name_prefix    = "prod"
  environment    = "production"
  
  # Kubernetes service account configuration
  k8s_namespace            = "app-namespace"
  k8s_service_account_name = "app-service-account"
  create_k8s_service_account = true
  
  # Azure identity configuration
  azure_tenant_id        = data.azurerm_client_config.current.tenant_id
  azure_subscription_id  = data.azurerm_client_config.current.subscription_id
  
  # Azure role assignments
  azure_role_assignments = {
    "storage" = {
      scope                = azurerm_storage_account.example.id
      role_definition_name = "Storage Blob Data Reader"
    },
    "keyvault" = {
      scope                = azurerm_key_vault.example.id
      role_definition_name = "Key Vault Secrets User"
    }
  }
  
  tags = {
    Application = "inventory-system"
    Team        = "platform"
  }
}
```

### GCP Example (Workload Identity)

```hcl
module "gke_pod_identity" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/iam"

  cloud_provider = "gcp"
  name_prefix    = "prod"
  environment    = "production"
  
  # Kubernetes service account configuration
  k8s_namespace            = "app-namespace"
  k8s_service_account_name = "app-service-account"
  create_k8s_service_account = true
  
  # GCP configuration
  gcp_project_id = "my-gcp-project"
  
  # GCP IAM roles for the service account
  gcp_roles = [
    "roles/storage.objectViewer",
    "roles/pubsub.subscriber",
    "roles/secretmanager.secretAccessor"
  ]
  
  tags = {
    application = "order-processor"
    team        = "platform"
  }
}
```

## Input Variables

### Common Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloud_provider | Cloud provider to use (aws, azure, gcp) | string | n/a | yes |
| name_prefix | Prefix for all resource names | string | n/a | yes |
| environment | Environment (dev, staging, prod) | string | "dev" | no |
| k8s_namespace | Kubernetes namespace for service account | string | "default" | no |
| k8s_service_account_name | Name of the Kubernetes service account | string | n/a | yes |
| create_k8s_service_account | Whether to create a Kubernetes service account | bool | false | no |
| k8s_service_account_annotations | Additional annotations for the Kubernetes service account | map(string) | {} | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

### AWS-Specific Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_oidc_provider_arn | ARN of the OIDC provider for IRSA | string | null | no |
| aws_oidc_provider_url | URL of the OIDC provider for IRSA | string | null | no |
| aws_policies | List of AWS managed policy ARNs to attach | list(string) | [] | no |
| aws_inline_policies | Map of inline IAM policies to attach to the role | map(string) | {} | no |
| aws_iam_policy_json | Custom IAM policy JSON document | string | null | no |
| aws_region | AWS region where resources will be created | string | null | no |
| aws_max_session_duration | Maximum session duration for the role in seconds | number | 3600 | no |
| aws_role_path | Path for the IAM role | string | "/" | no |
| aws_permissions_boundary | ARN of the permissions boundary to use for the role | string | null | no |

### Azure-Specific Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azure_tenant_id | Azure AD tenant ID | string | null | no |
| azure_subscription_id | Azure subscription ID | string | null | no |
| azure_resource_group_name | Azure resource group name | string | null | no |
| azure_location | Azure location where resources will be created | string | null | no |
| azure_role_assignments | Map of Azure role assignments to create | map(object) | {} | no |
| azure_use_managed_identity | Whether to use managed identity instead of workload identity | bool | false | no |
| azure_federated_credential_issuer | Issuer URL for Azure workload identity | string | null | no |
| azure_federated_credential_subject | Subject for Azure workload identity | string | null | no |

### GCP-Specific Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| gcp_project_id | GCP project ID where resources will be created | string | null | no |
| gcp_roles | List of GCP IAM roles to assign | list(string) | [] | no |
| gcp_service_account_id | ID to use for the GCP service account | string | null | no |
| gcp_service_account_display_name | Display name for the GCP service account | string | null | no |
| gcp_create_service_account_key | Whether to create a service account key | bool | false | no |
| gcp_service_account_key_algorithm | Algorithm to use for the service account key | string | "KEY_ALG_RSA_2048" | no |
| gcp_impersonate_service_account | Service account to impersonate for resource access | string | null | no |

## Output Variables

### Common Outputs

| Name | Description | Type |
|------|-------------|------|
| k8s_service_account_name | Name of the Kubernetes service account | string |
| k8s_namespace | Namespace of the Kubernetes service account | string |
| identity_type | Type of identity created (role, managed-identity, service-account) | string |

### AWS Outputs

| Name | Description | Type |
|------|-------------|------|
| aws_role_arn | ARN of the IAM role created for IRSA | string |
| aws_role_name | Name of the IAM role created for IRSA | string |
| aws_policy_arns | List of policy ARNs attached to the IAM role | list(string) |
| aws_oidc_provider_url | URL of the OIDC provider used for IRSA | string |

### Azure Outputs

| Name | Description | Type |
|------|-------------|------|
| azure_managed_identity_id | ID of the Azure managed identity | string |
| azure_managed_identity_principal_id | Principal ID of the Azure managed identity | string |
| azure_managed_identity_client_id | Client ID of the Azure managed identity | string |
| azure_federated_identity_id | ID of the Azure federated identity credential | string |
| azure_role_assignment_ids | IDs of the Azure role assignments created | map(string) |

### GCP Outputs

| Name | Description | Type |
|------|-------------|------|
| gcp_service_account_id | ID of the GCP service account | string |
| gcp_service_account_email | Email of the GCP service account | string |
| gcp_service_account_unique_id | Unique ID of the GCP service account | string |
| gcp_service_account_key_id | ID of the GCP service account key (if created) | string |
| gcp_service_account_key_private_key | Private key of the GCP service account (if created, sensitive) | string |
| gcp_iam_bindings | List of IAM role bindings created | list(string) |

## Advanced Usage

### AWS Cross-Account Access

```hcl
module "eks_cross_account_access" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/iam"

  cloud_provider = "aws"
  name_prefix    = "prod"
  environment    = "production"
  
  # Kubernetes service account configuration
  k8s_namespace            = "app-namespace"
  k8s_service_account_name = "cross-account-app"
  create_k8s_service_account = true
  
  # AWS IAM configuration
  aws_oidc_provider_arn = module.eks.oidc_provider_arn
  
  # Cross-account access policy
  aws_inline_policies = {
    "cross-account-policy" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect    = "Allow"
          Action    = "sts:AssumeRole"
          Resource  = "arn:aws:iam::123456789012:role/target-account-role"
        }
      ]
    })
  }
  
  tags = {
    Application = "cross-account-app"
    Team        = "platform"
  }
}
```

### Azure Pod-Managed Identity

```hcl
module "aks_managed_identity" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/iam"

  cloud_provider = "azure"
  name_prefix    = "prod"
  environment    = "production"
  
  # Kubernetes service account configuration
  k8s_namespace            = "app-namespace"
  k8s_service_account_name = "managed-identity-app"
  create_k8s_service_account = true
  
  # Azure managed identity configuration
  azure_tenant_id           = data.azurerm_client_config.current.tenant_id
  azure_subscription_id     = data.azurerm_client_config.current.subscription_id
  azure_resource_group_name = "resource-group-name"
  azure_use_managed_identity = true
  
  # Azure role assignments
  azure_role_assignments = {
    "cosmos" = {
      scope                = azurerm_cosmosdb_account.example.id
      role_definition_name = "DocumentDB Account Contributor"
    }
  }
  
  tags = {
    Application = "database-app"
    Team        = "data"
  }
}
```

### GCP Service Account Key Creation

```hcl
module "gke_service_account_key" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/iam"

  cloud_provider = "gcp"
  name_prefix    = "prod"
  environment    = "production"
  
  # Kubernetes service account configuration
  k8s_namespace            = "legacy-app-namespace"
  k8s_service_account_name = "legacy-app"
  create_k8s_service_account = true
  
  # GCP configuration
  gcp_project_id = "my-gcp-project"
  
  # GCP service account configuration
  gcp_roles = [
    "roles/monitoring.viewer",
    "roles/logging.viewer"
  ]
  
  # Create service account key for legacy application
  gcp_create_service_account_key = true
  
  tags = {
    application = "legacy-app"
    team        = "migration"
    security    = "review-required"
  }
}
```

## License

This module is released under the MIT License.
