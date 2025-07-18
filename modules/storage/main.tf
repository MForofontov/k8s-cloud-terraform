#==============================================================================
# Multi-Cloud Storage Integration Module
#==============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.14.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.14.0"
    }
  }
  required_version = ">= 1.0.0"
}

#------------------------------------------------------------------------------
# AWS S3 Bucket
#------------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  bucket = var.aws_bucket_name
  tags   = var.tags
}

#------------------------------------------------------------------------------
# Azure Storage Account & File Share
#------------------------------------------------------------------------------
resource "azurerm_storage_account" "this" {
  count                    = var.cloud_provider == "azure" ? 1 : 0
  name                     = var.azure_storage_account_name
  resource_group_name      = var.azure_resource_group_name
  location                 = var.azure_location
  account_tier             = var.azure_account_tier
  account_replication_type = var.azure_account_replication_type
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
  # Advanced: Enable blob encryption and disable public access if needed
  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_share" "this" {
  count              = var.cloud_provider == "azure" ? 1 : 0
  name               = var.azure_files_share_name
  storage_account_id = azurerm_storage_account.this[0].id
  quota              = var.azure_files_share_quota
  enabled_protocol   = "SMB"
}

#------------------------------------------------------------------------------
# GCP Storage Bucket
#------------------------------------------------------------------------------
resource "google_storage_bucket" "this" {
  count         = var.cloud_provider == "gcp" ? 1 : 0
  name          = var.gcp_bucket_name
  location      = var.gcp_location
  storage_class = var.gcp_storage_class
  labels        = var.tags

  versioning {
    enabled = true
  }
  uniform_bucket_level_access = true
}
