#==============================================================================
# Dev Environment - Root Module (GCP Example)
#
# This environment provisions a development-ready GKE cluster and supporting
# infrastructure on Google Cloud Platform. It demonstrates how to compose
# reusable modules for networking, storage, and Kubernetes, using environment-
# specific variables and best practices for modular Terraform.
#
# The configuration implements GCP best practices for:
# - Network isolation and custom VPCs
# - Secure and versioned cloud storage
# - Production-grade GKE clusters with regional availability
# - Tagging and labeling for resource management
#==============================================================================

#==============================================================================
# Provider Configuration
# Specifies the required providers and versions for this environment
#==============================================================================
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.43.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.44.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.1"
    }
  }
}


provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

#==============================================================================
# Module Instantiations
#==============================================================================

module "networking" {
  source         = "../../modules/networking"
  cloud_provider = "gcp"
  name_prefix    = var.environment
  vpc_cidr       = "10.10.0.0/16"
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}

module "storage" {
  source            = "../../modules/storage"
  cloud_provider    = "gcp"
  gcp_bucket_name   = "dev-app-gcs-bucket"
  gcp_location      = var.gcp_region
  gcp_storage_class = "STANDARD"
  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}

module "gke" {
  source       = "../../modules/gke"
  project_id   = var.gcp_project_id
  cluster_name = "dev-gke"
  region       = var.gcp_region
  network      = module.networking.gcp_network_name
  subnetwork   = module.networking.subnet_names[0]

  # Basic cluster configuration
  regional_cluster   = true
  kubernetes_version = "1.29"
  release_channel    = "REGULAR"

  # Default node pool
  create_default_node_pool = true
  default_machine_type     = "e2-medium"
  default_node_count       = 1

  # Labels
  labels = {
    environment = var.environment
    owner       = var.owner
  }
}

# Add other modules (k8s-addons, iam, etc.) as needed for your dev environment.
