# Cloud-Agnostic Networking Variables

variable "cloud_provider" {
  description = "The cloud provider to deploy to (aws, azure, gcp)"
  type        = string
  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "Allowed values for cloud_provider are 'aws', 'azure', or 'gcp'."
  }
}

variable "name_prefix" {
  description = "Prefix to use for naming resources"
  type        = string
  default     = "k8s"
}

variable "vpc_name" {
  description = "Name of the VPC/VNet. If not provided, {name_prefix}-vpc will be used"
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC/VNet. Defaults to 10.0.0.0/16"
  type        = string
  default     = null
}

variable "subnet_cidrs" {
  description = "List of CIDR blocks for subnets. If not provided, subnets will be created with calculated CIDRs"
  type        = list(string)
  default     = null
}

variable "subnet_names" {
  description = "List of names for subnets. If not provided, default names will be generated"
  type        = list(string)
  default     = null
}

variable "availability_zones" {
  description = "List of availability zones to use for AWS subnets"
  type        = list(string)
  default     = []
}

variable "public_subnet_indices" {
  description = "List of indices in the subnet_cidrs list that should be public (have internet access)"
  type        = list(number)
  default     = [0, 1]
}

variable "private_subnet_indices" {
  description = "List of indices in the subnet_cidrs list that should be private (no direct internet access)"
  type        = list(number)
  default     = [2, 3]
}

variable "create_internet_gateway" {
  description = "Whether to create an Internet Gateway (AWS) or enable internet connectivity"
  type        = bool
  default     = true
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT Gateway for private subnets to access internet"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Azure specific variables
variable "azure_location" {
  description = "Azure region to deploy resources to"
  type        = string
  default     = "eastus"
}

# GCP specific variables
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = null
}

variable "gcp_region" {
  description = "GCP region to deploy resources to"
  type        = string
  default     = "us-central1"
}