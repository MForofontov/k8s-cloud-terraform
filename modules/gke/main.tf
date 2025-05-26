// GKE Cluster Terraform Module

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.20.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.20.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
  }
}

# Get project and region information
data "google_project" "project" {
  project_id = var.project_id
}

# Create GKE cluster
resource "google_container_cluster" "this" {
  name                     = var.cluster_name
  location                 = var.regional_cluster ? var.region : var.zone
  project                  = var.project_id
  description              = var.description
  min_master_version       = var.kubernetes_version
  network                  = var.network
  subnetwork               = var.subnetwork
  
  # Use either zones or node_locations based on regional vs zonal
  dynamic "node_locations" {
    for_each = var.regional_cluster && length(var.node_locations) > 0 ? [1] : []
    content {
      locations = var.node_locations
    }
  }
  
  # Remove default node pool and create custom ones
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }
  
  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_cidr_blocks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_cidr_blocks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }
  
  # Network policy configuration
  network_policy {
    enabled  = var.enable_network_policy
    provider = var.network_policy_provider
  }
  
  # IP allocation policy for VPC-native clusters
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.cluster_ipv4_cidr_block
    services_ipv4_cidr_block = var.services_ipv4_cidr_block
  }
  
  # Binary authorization
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  # Workload identity configuration
  workload_identity_config {
    workload_pool = var.enable_workload_identity ? "${var.project_id}.svc.id.goog" : null
  }
  
  # Release channel
  release_channel {
    channel = var.release_channel
  }
  
  # Maintenance policy
  maintenance_policy {
    dynamic "recurring_window" {
      for_each = var.maintenance_start_time != null ? [1] : []
      content {
        start_time = var.maintenance_start_time
        end_time   = var.maintenance_end_time
        recurrence = var.maintenance_recurrence
      }
    }
  }
  
  # Cluster addons
  addons_config {
    http_load_balancing {
      disabled = !var.enable_http_load_balancing
    }
    
    horizontal_pod_autoscaling {
      disabled = !var.enable_horizontal_pod_autoscaling
    }
    
    network_policy_config {
      disabled = !var.enable_network_policy
    }
    
    gcp_filestore_csi_driver_config {
      enabled = var.enable_filestore_csi_driver
    }
    
    gce_persistent_disk_csi_driver_config {
      enabled = var.enable_gce_persistent_disk_csi_driver
    }
    
    dns_cache_config {
      enabled = var.enable_dns_cache
    }
    
    config_connector_config {
      enabled = var.enable_config_connector
    }
  }
  
  # Logging and monitoring
  logging_config {
    enable_components = var.logging_enabled_components
  }
  
  monitoring_config {
    enable_components = var.monitoring_enabled_components
    
    # Managed Prometheus
    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
  }
  
  # Node config defaults for node pools
  node_config {
    # This empty node_config is required for the cluster resource, but actual node configs
    # will be specified in the node pools
    # This configuration won't be used since remove_default_node_pool = true
  }
  
  # Networking
  networking_mode = "VPC_NATIVE"  # Recommended for all new clusters
  
  # Datapath provider
  datapath_provider = var.datapath_provider
  
  # Vertical Pod Autoscaling
  vertical_pod_autoscaling {
    enabled = var.enable_vertical_pod_autoscaling
  }
  
  # Resource usage export to BigQuery
  dynamic "resource_usage_export_config" {
    for_each = var.enable_resource_usage_export ? [1] : []
    content {
      enable_network_egress_metering = var.enable_network_egress_metering
      enable_resource_consumption_metering = var.enable_resource_consumption_metering
      
      bigquery_destination {
        dataset_id = var.resource_usage_export_dataset_id
      }
    }
  }
  
  # Cost management
  dynamic "cost_management_config" {
    for_each = var.enable_cost_allocation ? [1] : []
    content {
      enabled = true
    }
  }
  
  # Set deletion protection
  deletion_protection = var.deletion_protection
  
  # Tags
  resource_labels = var.labels
  
  # Timeouts
  timeouts {
    create = var.cluster_create_timeout
    update = var.cluster_update_timeout
    delete = var.cluster_delete_timeout
  }
  
  # Lifecycle to ignore certain changes
  lifecycle {
    ignore_changes = [
      node_config,
      initial_node_count
    ]
  }
}

# Create default node pool
resource "google_container_node_pool" "default" {
  count                 = var.create_default_node_pool ? 1 : 0
  name                  = "${var.cluster_name}-default-pool"
  cluster               = google_container_cluster.this.id
  location              = var.regional_cluster ? var.region : var.zone
  project               = var.project_id
  initial_node_count    = var.default_node_count
  
  # Auto-scaling configuration
  autoscaling {
    min_node_count  = var.enable_node_auto_scaling ? var.default_min_node_count : null
    max_node_count  = var.enable_node_auto_scaling ? var.default_max_node_count : null
    location_policy = var.enable_node_auto_scaling ? var.node_location_policy : null
  }
  
  # Auto-upgrade and repair
  management {
    auto_repair  = var.auto_repair
    auto_upgrade = var.auto_upgrade
  }
  
  # Upgrade strategy
  upgrade_settings {
    max_surge       = var.max_surge
    max_unavailable = var.max_unavailable
  }
  
  # Node configuration
  node_config {
    machine_type    = var.default_machine_type
    disk_size_gb    = var.default_disk_size_gb
    disk_type       = var.default_disk_type
    image_type      = var.image_type
    service_account = var.service_account
    
    # OAuth scopes for the nodes
    oauth_scopes = var.node_oauth_scopes
    
    # Labels
    labels = var.default_node_labels
    
    # Taints
    dynamic "taint" {
      for_each = var.default_node_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
    
    # Local SSD
    dynamic "local_ssd_count" {
      for_each = var.default_local_ssd_count > 0 ? [1] : []
      content {
        count = var.default_local_ssd_count
      }
    }
    
    # Tags and metadata
    tags     = var.default_node_tags
    metadata = var.node_metadata
    
    # Workload identity
    workload_metadata_config {
      mode = var.enable_workload_identity ? "GKE_METADATA" : "GCE_METADATA"
    }
    
    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = var.enable_secure_boot
      enable_integrity_monitoring = var.enable_integrity_monitoring
    }
    
    # Spot VMs
    spot = var.default_use_spot_instances
  }
  
  # Timeouts
  timeouts {
    create = var.node_pool_create_timeout
    update = var.node_pool_update_timeout
    delete = var.node_pool_delete_timeout
  }
  
  # Lifecycle to ignore auto-scaling changes
  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

# Create additional node pools
resource "google_container_node_pool" "additional" {
  for_each             = var.node_pools
  name                 = each.key
  cluster              = google_container_cluster.this.id
  location             = var.regional_cluster ? var.region : var.zone
  project              = var.project_id
  initial_node_count   = each.value.node_count
  
  # Auto-scaling configuration
  autoscaling {
    min_node_count  = each.value.min_count != null ? each.value.min_count : null
    max_node_count  = each.value.max_count != null ? each.value.max_count : null
    location_policy = each.value.location_policy != null ? each.value.location_policy : var.node_location_policy
  }
  
  # Auto-upgrade and repair
  management {
    auto_repair  = each.value.auto_repair != null ? each.value.auto_repair : var.auto_repair
    auto_upgrade = each.value.auto_upgrade != null ? each.value.auto_upgrade : var.auto_upgrade
  }
  
  # Upgrade strategy
  upgrade_settings {
    max_surge       = each.value.max_surge != null ? each.value.max_surge : var.max_surge
    max_unavailable = each.value.max_unavailable != null ? each.value.max_unavailable : var.max_unavailable
  }
  
  # Node configuration
  node_config {
    machine_type    = each.value.machine_type
    disk_size_gb    = each.value.disk_size_gb != null ? each.value.disk_size_gb : var.default_disk_size_gb
    disk_type       = each.value.disk_type != null ? each.value.disk_type : var.default_disk_type
    image_type      = each.value.image_type != null ? each.value.image_type : var.image_type
    service_account = each.value.service_account != null ? each.value.service_account : var.service_account
    
    # OAuth scopes for the nodes
    oauth_scopes = each.value.oauth_scopes != null ? each.value.oauth_scopes : var.node_oauth_scopes
    
    # Labels
    labels = each.value.labels
    
    # Taints
    dynamic "taint" {
      for_each = each.value.taints != null ? each.value.taints : []
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
    
    # Local SSD
    dynamic "local_ssd_count" {
      for_each = each.value.local_ssd_count != null && each.value.local_ssd_count > 0 ? [1] : []
      content {
        count = each.value.local_ssd_count
      }
    }
    
    # Tags and metadata
    tags     = each.value.tags != null ? each.value.tags : var.default_node_tags
    metadata = each.value.metadata != null ? each.value.metadata : var.node_metadata
    
    # Workload identity
    workload_metadata_config {
      mode = var.enable_workload_identity ? "GKE_METADATA" : "GCE_METADATA"
    }
    
    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = each.value.enable_secure_boot != null ? each.value.enable_secure_boot : var.enable_secure_boot
      enable_integrity_monitoring = each.value.enable_integrity_monitoring != null ? each.value.enable_integrity_monitoring : var.enable_integrity_monitoring
    }
    
    # Spot VMs
    spot = each.value.spot != null ? each.value.spot : false
  }
  
  # Timeouts
  timeouts {
    create = var.node_pool_create_timeout
    update = var.node_pool_update_timeout
    delete = var.node_pool_delete_timeout
  }
  
  # Lifecycle to ignore auto-scaling changes
  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }
}

# Generate kubeconfig
resource "local_file" "kubeconfig" {
  content  = templatefile("${path.module}/templates/kubeconfig.tpl", {
    cluster_name    = google_container_cluster.this.name
    endpoint        = google_container_cluster.this.endpoint
    cluster_ca      = google_container_cluster.this.master_auth[0].cluster_ca_certificate
    client_token    = data.google_client_config.current.access_token
    gcp_project     = var.project_id
    gcp_location    = var.regional_cluster ? var.region : var.zone
  })
  filename = "${path.module}/kubeconfig_${var.cluster_name}"
}

# Get current client config for kubeconfig
data "google_client_config" "current" {}