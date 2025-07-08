# Multi-Cloud Storage Integration Module

This Terraform module provisions cloud storage resources for Kubernetes clusters across AWS, Azure, and GCP. It enables persistent storage for workloads by creating S3 buckets, Azure Storage Accounts & File Shares, or Google Cloud Storage buckets, depending on your selected provider.

## Features

| Feature                | AWS         | Azure       | GCP         | Description                                                      |
|------------------------|:-----------:|:-----------:|:-----------:|------------------------------------------------------------------|
| Object Storage         | ✅ S3       | ✅ Blob     | ✅ GCS       | Creates cloud-native object storage buckets/containers           |
| File Share             | ❌          | ✅ Files    | ❌           | Azure Files share for RWX workloads                              |
| Versioning             | ✅          | ✅          | ✅           | Enables versioning where supported                               |
| Tagging/Labeling       | ✅          | ✅          | ✅           | Consistent resource tags/labels                                  |
| CSI Driver Compatible  | ✅          | ✅          | ✅           | Designed for Kubernetes persistent volumes via CSI               |
| Secure Defaults        | ✅          | ✅          | ✅           | Secure defaults (private, TLS, no public access)                 |
| Multi-Cloud Interface  | ✅          | ✅          | ✅           | Unified interface for all major cloud providers                  |

## Usage

```hcl
module "storage" {
  source         = "github.com/your-organization/k8s-cloud-terraform//modules/storage"
  cloud_provider = "aws" # or "azure" or "gcp"

  # AWS
  aws_bucket_name = "my-app-bucket"

  # Azure
  azure_storage_account_name  = "myappstorageacct"
  azure_resource_group_name   = "my-storage-rg"
  azure_location              = "eastus"
  azure_account_tier          = "Standard"
  azure_account_replication_type = "LRS"
  azure_files_share_name      = "myfileshare"
  azure_files_share_quota     = 100

  # GCP
  gcp_bucket_name   = "my-app-gcs-bucket"
  gcp_location      = "us-central1"
  gcp_storage_class = "STANDARD"

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Input Variables

### Core Configuration

| Name            | Type        | Default | Description                                      |
|-----------------|-------------|---------|--------------------------------------------------|
| cloud_provider  | string      | n/a     | Cloud provider to use (`aws`, `azure`, `gcp`)    |
| tags            | map(string) | `{}`    | Tags/labels to apply to all resources            |

### AWS Configuration

| Name             | Type   | Default | Description                |
|------------------|--------|---------|----------------------------|
| aws_bucket_name  | string | null    | Name of the S3 bucket      |

### Azure Configuration

| Name                        | Type   | Default   | Description                                 |
|-----------------------------|--------|-----------|---------------------------------------------|
| azure_storage_account_name  | string | null      | Name of the Storage Account                 |
| azure_resource_group_name   | string | null      | Name of the Resource Group                  |
| azure_location              | string | null      | Azure region                                |
| azure_account_tier          | string | "Standard"| Storage account tier                        |
| azure_account_replication_type | string | "LRS"  | Replication type (LRS, GRS, etc.)           |
| azure_files_share_name      | string | null      | Name of the Azure Files share               |
| azure_files_share_quota     | number | 100       | Quota (GB) for the Azure Files share        |

### GCP Configuration

| Name             | Type   | Default   | Description                        |
|------------------|--------|-----------|------------------------------------|
| gcp_bucket_name  | string | null      | Name of the GCS bucket             |
| gcp_location     | string | null      | GCP region/location                |
| gcp_storage_class| string | "STANDARD"| Storage class (STANDARD, NEARLINE) |

## Outputs

| Name                      | Description                                 |
|---------------------------|---------------------------------------------|
| aws_s3_bucket_name        | The name of the AWS S3 bucket               |
| azure_storage_account_name| The name of the Azure Storage Account       |
| azure_storage_account_id  | The ID of the Azure Storage Account         |
| azure_files_share_name    | The name of the Azure Files share           |
| gcp_bucket_name           | The name of the Google Cloud Storage bucket |

## Notes

- Only the resources for the selected `cloud_provider` will be created.
- For use with Kubernetes, reference the created storage resources in your CSI driver or persistent volume manifests.
- Versioning is enabled by default for Azure and GCP storage resources.

## License

This module is released under the MIT License.
