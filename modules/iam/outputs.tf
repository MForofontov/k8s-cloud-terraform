#==============================================================================
# Outputs for the Cloud IAM Module
#
# This file defines all output variables for the IAM module, including cloud
# provider-specific resources and cross-cloud common outputs.
#==============================================================================

#==============================================================================
# Common Outputs
# General information useful regardless of cloud provider
#==============================================================================
output "cloud_provider" {
  description = "The cloud provider used for IAM resources"
  value       = var.cloud_provider
}

output "k8s_service_account_name" {
  description = "Name of the Kubernetes service account"
  value       = var.k8s_service_account_name
}

output "k8s_namespace" {
  description = "Kubernetes namespace for the service account"
  value       = var.k8s_namespace
}

output "k8s_service_account_created" {
  description = "Whether a Kubernetes service account was created by this module"
  value       = var.create_k8s_service_account
}

#==============================================================================
# AWS Outputs
# Resources specific to AWS IAM
#==============================================================================
output "aws_role_arn" {
  description = "ARN of the IAM role for Kubernetes service account (IRSA)"
  value       = local.use_aws ? aws_iam_role.k8s_service_account[0].arn : null
}

output "aws_role_name" {
  description = "Name of the IAM role for Kubernetes service account"
  value       = local.use_aws ? aws_iam_role.k8s_service_account[0].name : null
}

output "aws_policy_arn" {
  description = "ARN of the custom IAM policy created for the service account"
  value       = local.use_aws && var.aws_iam_policy_json != null ? aws_iam_policy.k8s_service_account[0].arn : null
}

output "aws_attached_policy_arns" {
  description = "List of all policy ARNs attached to the IAM role"
  value       = local.use_aws ? concat(
    var.aws_iam_policy_json != null ? [aws_iam_policy.k8s_service_account[0].arn] : [],
    var.aws_additional_policy_arns != null ? var.aws_additional_policy_arns : []
  ) : null
}

#==============================================================================
# Azure Outputs
# Resources specific to Azure AD/RBAC
#==============================================================================
output "azure_app_id" {
  description = "Application ID of the Azure AD application"
  value       = local.use_azure ? azuread_application.k8s_app[0].application_id : null
}

output "azure_app_object_id" {
  description = "Object ID of the Azure AD application"
  value       = local.use_azure ? azuread_application.k8s_app[0].object_id : null
}

output "azure_sp_id" {
  description = "Object ID of the Azure AD service principal"
  value       = local.use_azure ? azuread_service_principal.k8s_sp[0].id : null
}

output "azure_sp_display_name" {
  description = "Display name of the Azure AD service principal"
  value       = local.use_azure ? azuread_service_principal.k8s_sp[0].display_name : null
}

output "azure_sp_password" {
  description = "Password for the Azure AD service principal (sensitive)"
  value       = local.use_azure ? azuread_service_principal_password.k8s_sp_password[0].value : null
  sensitive   = true
}

output "azure_role_assignments" {
  description = "Map of Azure role assignments created for the service principal"
  value       = local.use_azure ? { for k, v in azurerm_role_assignment.k8s_sp_role : k => {
    role_definition_name = v.role_definition_name
    scope                = v.scope
    principal_id         = v.principal_id
  }} : null
}

#==============================================================================
# Google Cloud Outputs
# Resources specific to Google Cloud IAM
#==============================================================================
output "gcp_service_account_email" {
  description = "Email address of the GCP service account"
  value       = local.use_gcp ? google_service_account.k8s_sa[0].email : null
}

output "gcp_service_account_id" {
  description = "Unique ID of the GCP service account"
  value       = local.use_gcp ? google_service_account.k8s_sa[0].id : null
}

output "gcp_service_account_name" {
  description = "Fully-qualified name of the GCP service account"
  value       = local.use_gcp ? google_service_account.k8s_sa[0].name : null
}

output "gcp_service_account_key" {
  description = "Private key for the GCP service account in JSON format (sensitive)"
  value       = local.use_gcp && !var.gcp_use_workload_identity ? google_service_account_key.k8s_sa_key[0].private_key : null
  sensitive   = true
}

output "gcp_workload_identity_enabled" {
  description = "Whether GCP Workload Identity is enabled for this service account"
  value       = local.use_gcp ? var.gcp_use_workload_identity : null
}

output "gcp_roles" {
  description = "List of IAM roles assigned to the GCP service account"
  value       = local.use_gcp ? local.gcp_service_account_roles : null
}

#==============================================================================
# Identity Federation Outputs
# Information about cloud-to-k8s identity federation configurations
#==============================================================================
output "identity_federation_type" {
  description = "Type of identity federation configured (irsa, azure-workload-identity, gcp-workload-identity, none)"
  value       = local.use_aws ? "irsa" : (
    local.use_azure && var.azure_use_workload_identity ? "azure-workload-identity" : (
      local.use_gcp && var.gcp_use_workload_identity ? "gcp-workload-identity" : "none"
    )
  )
}

output "k8s_service_account_annotations" {
  description = "Annotations applied to the Kubernetes service account for cloud provider integration"
  value       = var.create_k8s_service_account ? (
    local.use_aws ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.k8s_service_account[0].arn
    } : (
      local.use_gcp && var.gcp_use_workload_identity ? {
        "iam.gke.io/gcp-service-account" = google_service_account.k8s_sa[0].email
      } : {}
    )
  ) : {}
}