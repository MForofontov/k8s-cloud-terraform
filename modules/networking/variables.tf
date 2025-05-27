#-----------------------------------------------------------------------------
# Cloud-Agnostic Networking Variables
# 
# This module creates networking infrastructure across AWS, Azure, and GCP
# with a consistent interface. These variables control the network topology,
# subnetting, and connectivity features for your infrastructure.
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# REQUIRED PARAMETERS
#-----------------------------------------------------------------------------

variable "cloud_provider" {
  description = "The cloud provider to deploy to (aws, azure, gcp). This determines which cloud-specific resources will be created."
  type        = string
  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "Allowed values for cloud_provider are 'aws', 'azure', or 'gcp'."
  }
}

#-----------------------------------------------------------------------------
# OPTIONAL GENERAL PARAMETERS
#-----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix to use for naming resources. This helps identify related resources across your infrastructure."
  type        = string
  default     = "k8s"
}

variable "vpc_name" {
  description = "Name of the VPC/VNet. If not provided, {name_prefix}-vpc will be used. This is the main network container in each cloud provider."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC/VNet (e.g., '10.0.0.0/16'). If not specified, defaults to 10.0.0.0/16. This defines the overall IP address range for your network."
  type        = string
  default     = null
}

variable "subnet_cidrs" {
  description = "List of CIDR blocks for subnets (e.g., ['10.0.0.0/24', '10.0.1.0/24']). If not provided, subnets will be automatically created with calculated CIDRs based on the VPC CIDR block."
  type        = list(string)
  default     = null
}

variable "subnet_names" {
  description = "List of names for subnets. Should match the length of subnet_cidrs if provided. If not specified, names will be auto-generated as '{name_prefix}-subnet-{index}'."
  type        = list(string)
  default     = null
}

variable "availability_zones" {
  description = "List of availability zones to use for AWS subnets. For high availability, specify at least two zones (e.g., ['us-east-1a', 'us-east-1b'])."
  type        = list(string)
  default     = []
}

variable "public_subnet_indices" {
  description = "List of indices in the subnet_cidrs list that should be public (have internet access). By default, the first two subnets will be public. These subnets will have routes to the internet gateway."
  type        = list(number)
  default     = [0, 1]
}

variable "private_subnet_indices" {
  description = "List of indices in the subnet_cidrs list that should be private (no direct internet access). By default, the third and fourth subnets will be private. These subnets will route through the NAT gateway if enabled."
  type        = list(number)
  default     = [2, 3]
}

variable "create_internet_gateway" {
  description = "Whether to create an Internet Gateway (AWS) or equivalent in other clouds to enable outbound/inbound internet access for public subnets."
  type        = bool
  default     = true
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT Gateway for private subnets to access internet. This allows instances in private subnets to initiate outbound connections while remaining inaccessible from the internet."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources. Use this to categorize resources by environment, cost center, owner, etc. Example: {Environment = 'Production', Owner = 'DevOps'}"
  type        = map(string)
  default     = {}
}

#-----------------------------------------------------------------------------
# AZURE-SPECIFIC PARAMETERS
#-----------------------------------------------------------------------------

variable "azure_location" {
  description = "Azure region to deploy resources to (e.g., 'eastus', 'westeurope'). Only used when cloud_provider is 'azure'."
  type        = string
  default     = "eastus"
}

#-----------------------------------------------------------------------------
# GCP-SPECIFIC PARAMETERS
#-----------------------------------------------------------------------------

variable "gcp_project_id" {
  description = "GCP project ID where resources will be created. Required when cloud_provider is 'gcp'."
  type        = string
  default     = null
}

variable "gcp_region" {
  description = "GCP region to deploy resources to (e.g., 'us-central1', 'europe-west1'). Only used when cloud_provider is 'gcp'."
  type        = string
  default     = "us-central1"
}