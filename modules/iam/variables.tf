#==============================================================================
# Variables for the Cloud IAM Module
#
# This file defines all input variables for the IAM module, including common
# configuration options and cloud provider-specific settings.
#==============================================================================

#==============================================================================
# Common Variables
# Configuration options that apply across all cloud providers
#==============================================================================
variable "cloud_provider" {
  description = "Target cloud provider for IAM resources (aws, azure, gcp)"
  type        = string
  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "The cloud_provider value must be one of: aws, azure, gcp."
  }
}

variable "name_prefix" {
  description = "Prefix for naming resources created by this module"
  type        = string
  validation {
    condition     = length(var.name_prefix) > 0 && length(var.name_prefix) <= 20
    error_message = "The name_prefix must be between 1 and 20 characters in length."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, test, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = length(var.environment) > 0 && length(var.environment) <= 10
    error_message = "The environment must be between 1 and 10 characters in length."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources created by this module"
  type        = map(string)
  default     = {}
}

#==============================================================================
# Kubernetes Configuration
# Settings for Kubernetes service account integration
#==============================================================================
variable "k8s_namespace" {
  description = "Kubernetes namespace for service account"
  type        = string
  default     = "default"
}

variable "k8s_service_account_name" {
  description = "Name of the Kubernetes service account to create or reference"
  type        = string
}

variable "create_k8s_service_account" {
  description = "Whether to create a Kubernetes service account (requires kubernetes provider)"
  type        = bool
  default     = false
}

variable "k8s_service_account_annotations" {
  description = "Additional annotations to apply to the Kubernetes service account"
  type        = map(string)
  default     = {}
}

variable "k8s_service_account_labels" {
  description = "Additional labels to apply to the Kubernetes service account"
  type        = map(string)
  default     = {}
}

#==============================================================================
# AWS Configuration
# Settings specific to AWS IAM resources
#==============================================================================
variable "aws_oidc_provider_arn" {
  description = "ARN of the AWS OIDC provider for EKS service account integration"
  type        = string
  default     = null
}

variable "aws_oidc_provider_url" {
  description = "URL of the AWS OIDC provider for EKS service account integration (without https://)"
  type        = string
  default     = null
}

variable "aws_iam_policy_json" {
  description = "JSON string containing a custom IAM policy to attach to the service account role"
  type        = string
  default     = null
}

variable "aws_additional_policy_arns" {
  description = "List of additional AWS managed policy ARNs to attach to the service account role"
  type        = list(string)
  default     = []
}

#==============================================================================
# Azure Configuration
# Settings specific to Azure AD and RBAC resources
#==============================================================================
variable "azure_application_owners" {
  description = "List of Azure AD object IDs that will be assigned as application owners"
  type        = list(string)
  default     = []
}

variable "azure_role_assignments" {
  description = "Map of Azure role assignments to create for the service principal"
  type        = map(object({
    scope                = string
    role_definition_name = string
  }))
  default     = {}
}

variable "azure_use_workload_identity" {
  description = "Whether to configure Azure Workload Identity for AKS"
  type        = bool
  default     = false
}

#==============================================================================
# Google Cloud Configuration
# Settings specific to GCP IAM resources
#==============================================================================
variable "gcp_project_id" {
  description = "GCP project ID where service accounts will be created"
  type        = string
  default     = null
}

variable "gcp_roles" {
  description = "List of GCP IAM roles to assign to the service account"
  type        = list(string)
  default     = []
}

variable "gcp_use_workload_identity" {
  description = "Whether to configure Workload Identity Federation for GKE"
  type        = bool
  default     = false
}
