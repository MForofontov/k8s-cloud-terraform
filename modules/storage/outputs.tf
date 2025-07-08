#==============================================================================
# Outputs for Multi-Cloud Storage Integration Module
#==============================================================================

#------------------------------------------------------------------------------
# AWS S3 Output
#------------------------------------------------------------------------------
output "aws_s3_bucket_name" {
  description = "The name of the AWS S3 bucket."
  value       = try(aws_s3_bucket.this[0].bucket, null)
}

#------------------------------------------------------------------------------
# Azure Storage Outputs
#------------------------------------------------------------------------------
output "azure_storage_account_name" {
  description = "The name of the Azure Storage Account."
  value       = try(azurerm_storage_account.this[0].name, null)
}

output "azure_storage_account_id" {
  description = "The ID of the Azure Storage Account."
  value       = try(azurerm_storage_account.this[0].id, null)
}

output "azure_files_share_name" {
  description = "The name of the Azure Files share."
  value       = try(azurerm_storage_share.this[0].name, null)
}

#------------------------------------------------------------------------------
# GCP Storage Output
#------------------------------------------------------------------------------
output "gcp_bucket_name" {
  description = "The name of the Google Cloud Storage bucket."
  value       = try(google_storage_bucket.this[0].name, null)
}
