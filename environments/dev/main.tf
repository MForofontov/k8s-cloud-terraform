#==============================================================================
# Dev Environment - Root Module (GCP Example)
#==============================================================================

module "networking" {
  source         = "../../modules/networking"
  cloud_provider = "gcp"
  name_prefix    = "dev"
  vpc_cidr       = "10.10.0.0/16"
  gcp_project_id = "my-gcp-project"
  gcp_region     = "us-central1"
  tags = {
    Environment = "dev"
    Owner       = "devops"
  }
}

module "storage" {
  source            = "../../modules/storage"
  cloud_provider    = "gcp"
  gcp_bucket_name   = "dev-app-gcs-bucket"
  gcp_location      = "us-central1"
  gcp_storage_class = "STANDARD"
  tags = {
    Environment = "dev"
    Owner       = "devops"
  }
}

module "gke" {
  source       = "../../modules/gke"
  project_id   = "my-gcp-project"
  cluster_name = "dev-gke"
  region       = "us-central1"
  network      = module.networking.gcp_network_name
  subnetwork   = module.networking.gcp_subnetwork_names[0]

  # Basic cluster configuration
  regional_cluster   = true
  kubernetes_version = "1.28"
  release_channel    = "REGULAR"

  # Default node pool
  create_default_node_pool = true
  default_machine_type     = "e2-medium"
  default_node_count       = 1

  # Labels
  labels = {
    environment = "dev"
    owner       = "devops"
  }
}

# Add other modules (k8s-addons, iam, etc.) as needed for your dev environment.