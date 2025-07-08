#==============================================================================
# Variables for Multi-Cloud Storage Integration Module
#==============================================================================

variable "cloud_provider" {
  description = "The cloud provider to use for storage resources. Valid values: aws, azure, gcp."
  type        = string
}

variable "tags" {
  description = "A map of tags or labels to assign to resources."
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# AWS Variables
#------------------------------------------------------------------------------
variable "aws_bucket_name" {
  description = "The name of the AWS S3 bucket."
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# Azure Variables
#------------------------------------------------------------------------------
variable "azure_storage_account_name" {
  description = "The name of the Azure Storage Account."
  type        = string
  default     = null
}

variable "azure_resource_group_name" {
  description = "The name of the Azure Resource Group."
  type        = string
  default     = null
}

variable "azure_location" {
  description = "The Azure region for the storage account."
  type        = string
  default     = null
}

variable "azure_account_tier" {
  description = "The performance tier of the storage account (Standard or Premium)."
  type        = string
  default     = "Standard"
}

variable "azure_account_replication_type" {
  description = "The replication type for the storage account (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)."
  type        = string
  default     = "LRS"
}

variable "azure_files_share_name" {
  description = "The name of the Azure Files share."
  type        = string
  default     = null
}

variable "azure_files_share_quota" {
  description = "The quota (in GB) for the Azure Files share."
  type        = number
  default     = 100
}

#------------------------------------------------------------------------------
# GCP Variables
#------------------------------------------------------------------------------
variable "gcp_bucket_name" {
  description = "The name of the Google Cloud Storage bucket."
  type        = string
  default     = null
}

variable "gcp_location" {
  description = "The location for the Google Cloud Storage bucket."
  type        = string
  default     = null
}

variable "gcp_storage_class" {
  description = "The storage class for the Google Cloud Storage bucket (e.g., STANDARD, NEARLINE, COLDLINE, ARCHIVE)."
  type        = string
  default     = "STANDARD"
}
