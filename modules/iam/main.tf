#==============================================================================
# Cloud IAM Module for Kubernetes
#
# This module creates and manages Identity and Access Management (IAM) resources
# across multiple cloud providers to support Kubernetes deployments. It handles
# service accounts, roles, policies, and other IAM resources required for secure
# Kubernetes cluster operations.
#
# The module supports AWS IAM, Azure AD/RBAC, and Google Cloud IAM with a
# consistent interface, making it easier to implement infrastructure across
# different cloud environments while maintaining security best practices.
#==============================================================================

#==============================================================================
# Provider Configuration
# Specifies the required providers and versions for this module
#==============================================================================
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.98.0"
      configuration_aliases = [aws.alternate]
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.30.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.50.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.42.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19.0"
    }
  }
  required_version = ">= 1.5.0"
}

#==============================================================================
# Local Variables
# Computed values used throughout the module
#==============================================================================
locals {
  # Determine which provider to use based on input variable
  use_aws   = var.cloud_provider == "aws"
  use_azure = var.cloud_provider == "azure"
  use_gcp   = var.cloud_provider == "gcp"

  # Common name prefixes for resources
  resource_prefix = "${var.name_prefix}-${var.environment}"

  # Create standardized tags with required and optional values
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "iam"
    }
  )

  # AWS-specific locals
  aws_policy_arns = var.aws_additional_policy_arns != null ? var.aws_additional_policy_arns : []

  # Azure-specific locals
  azure_role_assignments = var.azure_role_assignments != null ? var.azure_role_assignments : {}

  # GCP-specific locals
  gcp_service_account_roles = var.gcp_roles != null ? var.gcp_roles : []
}

#==============================================================================
# AWS IAM Resources
# IAM roles, policies, and service accounts for AWS environments
#==============================================================================
# AWS IAM Role for Kubernetes service accounts (IRSA)
resource "aws_iam_role" "k8s_service_account" {
  count = local.use_aws ? 1 : 0

  name = "${local.resource_prefix}-k8s-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.aws_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.aws_oidc_provider_url}:sub" = "system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account_name}"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# AWS IAM custom policy for Kubernetes service accounts
resource "aws_iam_policy" "k8s_service_account" {
  count = local.use_aws && var.aws_iam_policy_json != null ? 1 : 0

  name        = "${local.resource_prefix}-k8s-sa-policy"
  description = "Custom policy for Kubernetes service account ${var.k8s_service_account_name}"
  policy      = var.aws_iam_policy_json

  tags = local.common_tags
}

# Attach custom policy to the IAM role
resource "aws_iam_role_policy_attachment" "k8s_service_account_custom" {
  count = local.use_aws && var.aws_iam_policy_json != null ? 1 : 0

  role       = aws_iam_role.k8s_service_account[0].name
  policy_arn = aws_iam_policy.k8s_service_account[0].arn
}

# Attach additional AWS managed policies to the IAM role
resource "aws_iam_role_policy_attachment" "k8s_service_account_additional" {
  count = local.use_aws ? length(local.aws_policy_arns) : 0

  role       = aws_iam_role.k8s_service_account[0].name
  policy_arn = local.aws_policy_arns[count.index]
}

#==============================================================================
# Azure IAM Resources
# Azure AD applications, service principals, and role assignments
#==============================================================================
# Azure AD Application
resource "azuread_application" "k8s_app" {
  count = local.use_azure ? 1 : 0

  display_name = "${local.resource_prefix}-k8s-app"
  owners       = var.azure_application_owners

  # Application identity configuration
  sign_in_audience = "AzureADMyOrg"

  # API settings and permissions
  api {
    oauth2_permission_scope {
      admin_consent_description  = "Allow the application to access ${local.resource_prefix}-k8s-app on behalf of the signed-in user."
      admin_consent_display_name = "Access ${local.resource_prefix}-k8s-app"
      enabled                    = true
      id                         = "00000000-0000-0000-0000-000000000000"
      type                       = "User"
      user_consent_description   = "Allow the application to access ${local.resource_prefix}-k8s-app on your behalf."
      user_consent_display_name  = "Access ${local.resource_prefix}-k8s-app"
      value                      = "user_impersonation"
    }
  }

  # Required resources access (Microsoft Graph, etc.)
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
}

# Azure AD Service Principal
resource "azuread_service_principal" "k8s_sp" {
  count = local.use_azure ? 1 : 0

  client_id = azuread_application.k8s_app[0].client_id # Changed from application_id to client_id
  owners    = var.azure_application_owners

  # Service principal settings
  app_role_assignment_required = false
  tags                         = keys(local.common_tags)
}

# Azure AD Service Principal Password
resource "azuread_service_principal_password" "k8s_sp_password" {
  count = local.use_azure ? 1 : 0

  service_principal_id = azuread_service_principal.k8s_sp[0].id
  display_name         = "${local.resource_prefix}-k8s-sp-password"

  # Replace end_date_relative with end_date
  end_date = timeadd(timestamp(), "87600h") # 10 years
}

# Azure Role Assignments
resource "azurerm_role_assignment" "k8s_sp_role" {
  for_each = local.use_azure ? local.azure_role_assignments : {}

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azuread_service_principal.k8s_sp[0].id
}

#==============================================================================
# Google Cloud IAM Resources
# GCP service accounts, roles, and bindings
#==============================================================================
# GCP Service Account
resource "google_service_account" "k8s_sa" {
  count = local.use_gcp ? 1 : 0

  account_id   = "${replace(local.resource_prefix, "-", "_")}_k8s_sa"
  display_name = "${local.resource_prefix} Kubernetes Service Account"
  description  = "Service account for Kubernetes workloads"
  project      = var.gcp_project_id
}

# GCP Service Account IAM Binding
resource "google_project_iam_member" "k8s_sa_roles" {
  count = local.use_gcp ? length(local.gcp_service_account_roles) : 0

  project = var.gcp_project_id
  role    = local.gcp_service_account_roles[count.index]
  member  = "serviceAccount:${google_service_account.k8s_sa[0].email}"
}

# GCP Service Account Key (for non-Workload Identity scenarios)
resource "google_service_account_key" "k8s_sa_key" {
  count = local.use_gcp && !var.gcp_use_workload_identity ? 1 : 0

  service_account_id = google_service_account.k8s_sa[0].name
}

# GCP Workload Identity IAM Binding
resource "google_service_account_iam_binding" "k8s_sa_workload_identity" {
  count = local.use_gcp && var.gcp_use_workload_identity ? 1 : 0

  service_account_id = google_service_account.k8s_sa[0].name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_service_account_name}]"
  ]
}

#==============================================================================
# Cross-Cloud Kubernetes Service Account Creation
# Creates the Kubernetes service account in the cluster
#==============================================================================
resource "kubernetes_service_account" "k8s_sa" {
  count = var.create_k8s_service_account ? 1 : 0

  metadata {
    name      = var.k8s_service_account_name
    namespace = var.k8s_namespace

    annotations = merge(
      local.use_aws ? {
        "eks.amazonaws.com/role-arn" = aws_iam_role.k8s_service_account[0].arn
      } : {},
      local.use_gcp && var.gcp_use_workload_identity ? {
        "iam.gke.io/gcp-service-account" = google_service_account.k8s_sa[0].email
      } : {},
      var.k8s_service_account_annotations
    )

    labels = merge(
      {
        "app.kubernetes.io/managed-by" = "terraform"
      },
      var.k8s_service_account_labels
    )
  }

  automount_service_account_token = true

  depends_on = [
    aws_iam_role.k8s_service_account,
    google_service_account.k8s_sa,
    google_service_account_iam_binding.k8s_sa_workload_identity
  ]
}

#==============================================================================
# Azure Workload Identity Configuration
# Configure Azure Workload Identity for Kubernetes (AKS)
#==============================================================================
resource "kubectl_manifest" "azure_federated_identity" {
  count = local.use_azure && var.azure_use_workload_identity ? 1 : 0

  yaml_body = <<YAML
apiVersion: azure.microsoft.com/v1alpha1
kind: AzureIdentity
metadata:
  name: ${var.k8s_service_account_name}-azure-identity
  namespace: ${var.k8s_namespace}
spec:
  type: 0
  resourceID: ${azuread_service_principal.k8s_sp[0].id}
  clientID: ${azuread_application.k8s_app[0].application_id}
YAML

  depends_on = [
    kubernetes_service_account.k8s_sa
  ]
}

resource "kubectl_manifest" "azure_identity_binding" {
  count = local.use_azure && var.azure_use_workload_identity ? 1 : 0

  yaml_body = <<YAML
apiVersion: azure.microsoft.com/v1alpha1
kind: AzureIdentityBinding
metadata:
  name: ${var.k8s_service_account_name}-azure-identity-binding
  namespace: ${var.k8s_namespace}
spec:
  azureIdentity: ${var.k8s_service_account_name}-azure-identity
  selector: ${var.k8s_service_account_name}-azure-identity
YAML

  depends_on = [
    kubectl_manifest.azure_federated_identity
  ]
}
