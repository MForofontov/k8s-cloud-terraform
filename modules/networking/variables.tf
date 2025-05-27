#------------------------------------------------------------------------------
# Cloud-Agnostic Networking Module Variables
#
# This file defines input variables for the Networking module, supporting
# consistent configuration across AWS, Azure, and GCP.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Provider Selection and General Configuration
#------------------------------------------------------------------------------
variable "cloud_provider" {
  description = "Cloud provider to use (aws, azure, gcp)"
  type        = string
  
  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "The cloud_provider value must be one of: aws, azure, gcp."
  }
}

variable "name_prefix" {
  description = "Prefix for all resource names to ensure uniqueness and consistency"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod) for tagging and naming"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Networking Configuration
#------------------------------------------------------------------------------
variable "vpc_name" {
  description = "Name for the VPC/VNet. If not provided, will be auto-generated from name_prefix"
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC/VNet. Default is 10.0.0.0/16"
  type        = string
  default     = null
}

variable "subnet_cidrs" {
  description = "List of CIDR blocks for subnets. If not provided, will be auto-generated from vpc_cidr"
  type        = list(string)
  default     = null
}

variable "subnet_names" {
  description = "List of subnet names. If not provided, will be auto-generated from name_prefix"
  type        = list(string)
  default     = null
}

variable "public_subnet_indices" {
  description = "List of subnet indices that should be treated as public (0-based indexing)"
  type        = list(number)
  default     = [0, 1]
}

variable "private_subnet_indices" {
  description = "List of subnet indices that should be treated as private (0-based indexing)"
  type        = list(number)
  default     = [2, 3]
}

variable "create_internet_gateway" {
  description = "Whether to create an internet gateway for public subnets"
  type        = bool
  default     = true
}

variable "create_nat_gateway" {
  description = "Whether to create NAT gateway(s) for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Whether to use a single NAT gateway for all private subnets (true) or one per availability zone (false)"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Whether to enable IPv6 support"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC flow logs for network traffic analysis"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 30
}

variable "enable_service_endpoints" {
  description = "Whether to enable service endpoints/PrivateLink/Private Service Access"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# AWS Specific Configuration
#------------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "availability_zones" {
  description = "List of availability zones to use for resources. Should match the number of subnets"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Azure Specific Configuration
#------------------------------------------------------------------------------
variable "azure_location" {
  description = "Azure location where resources will be created"
  type        = string
  default     = "eastus"
}

variable "azure_enable_zones" {
  description = "Whether to enable availability zones for Azure resources that support it"
  type        = bool
  default     = true
}

variable "azure_enable_ddos_protection" {
  description = "Whether to enable DDoS protection for Azure virtual network"
  type        = bool
  default     = false
}

variable "azure_service_endpoints" {
  description = "List of Azure service endpoints to enable on private subnets"
  type        = list(string)
  default     = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry"]
}

variable "azure_subnet_delegations" {
  description = "Map of subnet delegations for Azure services"
  type        = map(object({
    service_name = string
    actions      = list(string)
  }))
  default     = {}
}

variable "azure_log_analytics_workspace_id" {
  description = "Azure Log Analytics workspace ID for flow logs analysis"
  type        = string
  default     = null
}

variable "azure_log_analytics_workspace_resource_id" {
  description = "Azure Log Analytics workspace resource ID for flow logs analysis"
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# GCP Specific Configuration
#------------------------------------------------------------------------------
variable "gcp_project_id" {
  description = "GCP project ID where resources will be created"
  type        = string
  default     = null
}

variable "gcp_project_number" {
  description = "GCP project number for VPC Service Controls"
  type        = string
  default     = null
}

variable "gcp_region" {
  description = "GCP region where resources will be created"
  type        = string
  default     = "us-central1"
}

variable "gcp_routing_mode" {
  description = "GCP network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "REGIONAL"
  
  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.gcp_routing_mode)
    error_message = "The gcp_routing_mode value must be one of: REGIONAL, GLOBAL."
  }
}

variable "gcp_enable_vpc_service_controls" {
  description = "Whether to enable VPC Service Controls for GCP network (Enterprise feature)"
  type        = bool
  default     = false
}

variable "gcp_access_policy_id" {
  description = "GCP Access Context Manager policy ID for VPC Service Controls"
  type        = string
  default     = null
}

variable "gcp_restricted_services" {
  description = "List of GCP services to restrict in the VPC Service Controls perimeter"
  type        = list(string)
  default     = ["storage.googleapis.com", "bigquery.googleapis.com"]
}

variable "gcp_allowed_services" {
  description = "List of GCP services allowed in the VPC Service Controls perimeter"
  type        = list(string)
  default     = ["compute.googleapis.com", "container.googleapis.com"]
}

variable "gcp_allowed_identities" {
  description = "List of identities allowed to access restricted services"
  type        = list(string)
  default     = []
}