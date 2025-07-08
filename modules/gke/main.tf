#==============================================================================
# Google Kubernetes Engine (GKE) Cluster Module
#
# This module provisions a production-ready GKE cluster with customizable
# configurations for networking, node pools, security, and operations.
# It supports both regional (high-availability) and zonal deployments with
# various node pool configurations to support different workload requirements.
#
# The module implements Google best practices for cluster configuration:
# - VPC-native clusters with custom pod/service IP ranges
# - Security hardening via private clusters, secure boot, and workload identity
# - Flexible node pool configurations with auto-scaling and auto-repair
# - Comprehensive monitoring and logging integrations
#==============================================================================

#==============================================================================
# Provider Configuration
# Specifies the required providers and versions for this module
#==============================================================================
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.37.0"  # Latest stable Google provider at time of creation
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.37.0"  # Used for GKE features that are in beta
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.1"  # For generating kubeconfig and potential future K8s resource management
    }
  }
}

#==============================================================================
# Data Sources
# References to existing Google Cloud resources
#==============================================================================
# Retrieve current project information for use in IAM bindings and resource naming
data "google_project" "project" {
  project_id = var.project_id
}

# Retrieve authentication token for kubeconfig generation
data "google_client_config" "current" {}

#==============================================================================
# GKE Cluster Resource
# The primary resource that defines the Kubernetes cluster
#==============================================================================
resource "google_container_cluster" "this" {
  name                     = var.cluster_name
  location                 = var.regional_cluster ? var.region : var.zone  # Regional clusters deploy control plane across multiple zones
  project                  = var.project_id
  description              = var.description
  min_master_version       = var.kubernetes_version  # Specific Kubernetes version or null for latest supported
  network                  = var.network             # VPC network for cluster networking
  subnetwork               = var.subnetwork          # Subnet within the VPC for node IP allocation

  #--------------------------------------------------------------
  # Node Locations
  # For regional clusters, specifies which zones to deploy nodes in
  #--------------------------------------------------------------
  dynamic "node_locations" {
    for_each = var.regional_cluster && length(var.node_locations) > 0 ? [1] : []
    content {
      locations = var.node_locations  # List of zones within the region for node placement
    }
  }

  #--------------------------------------------------------------
  # Default Node Pool Configuration
  # We remove the default pool and create custom ones with more options
  #--------------------------------------------------------------
  remove_default_node_pool = true  # Remove the minimal default pool GKE creates automatically
  initial_node_count       = 1     # Required even when removing the default pool

  #--------------------------------------------------------------
  # Private Cluster Configuration
  # Controls public/private networking for nodes and control plane
  #--------------------------------------------------------------
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes      # When true, nodes only have internal IPs
    enable_private_endpoint = var.enable_private_endpoint   # When true, API server is only accessible from internal networks
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block    # /28 CIDR for the control plane's private network
  }

  #--------------------------------------------------------------
  # Master Authorized Networks
  # Restricts which external networks can access the Kubernetes API
  #--------------------------------------------------------------
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_cidr_blocks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_cidr_blocks
        content {
          cidr_block   = cidr_blocks.value.cidr_block    # IP range in CIDR notation
          display_name = cidr_blocks.value.display_name  # Human-readable identifier
        }
      }
    }
  }

  #--------------------------------------------------------------
  # Network Policy Configuration
  # Enables Kubernetes NetworkPolicy enforcement using Calico
  #--------------------------------------------------------------
  network_policy {
    enabled  = var.enable_network_policy    # When true, enables pod-to-pod network policy
    provider = var.network_policy_provider  # Currently only CALICO is supported
  }

  #--------------------------------------------------------------
  # IP Allocation Policy
  # Configures Pod and Service IP ranges for VPC-native clusters
  #--------------------------------------------------------------
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.cluster_ipv4_cidr_block   # CIDR for pod IPs, must not overlap with VPC ranges
    services_ipv4_cidr_block = var.services_ipv4_cidr_block  # CIDR for service IPs, must not overlap with VPC or pod ranges
  }

  #--------------------------------------------------------------
  # Binary Authorization
  # Enforces deployment of approved container images only
  #--------------------------------------------------------------
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"  # Enforces the policy configured at the project level
    }
  }

  #--------------------------------------------------------------
  # Workload Identity Configuration
  # Allows Kubernetes service accounts to act as IAM service accounts
  #--------------------------------------------------------------
  workload_identity_config {
    workload_pool = var.enable_workload_identity ? "${var.project_id}.svc.id.goog" : null  # The Workload Identity Pool
  }

  #--------------------------------------------------------------
  # Release Channel Configuration
  # Controls the rate at which clusters receive updates
  #--------------------------------------------------------------
  release_channel {
    channel = var.release_channel  # RAPID, REGULAR, STABLE, or UNSPECIFIED
  }

  #--------------------------------------------------------------
  # Maintenance Window Configuration
  # Defines when automatic maintenance can occur
  #--------------------------------------------------------------
  maintenance_policy {
    dynamic "recurring_window" {
      for_each = var.maintenance_start_time != null ? [1] : []
      content {
        start_time = var.maintenance_start_time    # Time when maintenance window begins (HH:MM format)
        end_time   = var.maintenance_end_time      # Time when maintenance window ends
        recurrence = var.maintenance_recurrence    # RRULE format defining frequency (e.g., "FREQ=WEEKLY;BYDAY=SA,SU")
      }
    }
  }

  #--------------------------------------------------------------
  # Cluster Add-ons Configuration
  # Enables/disables various GKE features and integrations
  #--------------------------------------------------------------
  addons_config {
    http_load_balancing {
      disabled = !var.enable_http_load_balancing  # Integrates with Google Cloud Load Balancing
    }

    horizontal_pod_autoscaling {
      disabled = !var.enable_horizontal_pod_autoscaling  # Automatically scales pod replicas based on CPU/memory
    }

    network_policy_config {
      disabled = !var.enable_network_policy  # Required for network policy enforcement
    }

    gcp_filestore_csi_driver_config {
      enabled = var.enable_filestore_csi_driver  # For ReadWriteMany persistent volumes using Filestore
    }

    gce_persistent_disk_csi_driver_config {
      enabled = var.enable_gce_persistent_disk_csi_driver  # Enhanced PD volume features (snapshots, resize)
    }

    dns_cache_config {
      enabled = var.enable_dns_cache  # NodeLocal DNSCache for improved DNS performance
    }

    config_connector_config {
      enabled = var.enable_config_connector  # Kubernetes operator for Google Cloud resources
    }
  }

  #--------------------------------------------------------------
  # Logging Configuration
  # Controls which components send logs to Cloud Logging
  #--------------------------------------------------------------
  logging_config {
    enable_components = var.logging_enabled_components  # SYSTEM_COMPONENTS and/or WORKLOADS
  }

  #--------------------------------------------------------------
  # Monitoring Configuration
  # Controls which components send metrics to Cloud Monitoring
  #--------------------------------------------------------------
  monitoring_config {
    enable_components = var.monitoring_enabled_components  # SYSTEM_COMPONENTS and/or WORKLOADS

    # Managed Prometheus for scalable metrics collection
    managed_prometheus {
      enabled = var.enable_managed_prometheus  # Automatically collects Prometheus metrics
    }
  }

  #--------------------------------------------------------------
  # Default Node Configuration
  # This placeholder is required but won't be used
  #--------------------------------------------------------------
  node_config {
    # This empty node_config is required by the API, but won't actually be used
    # since remove_default_node_pool = true. Actual node configurations are
    # specified in the node pool resources below.
  }

  #--------------------------------------------------------------
  # Networking Mode
  # Sets the cluster to use VPC-native networking (alias IP)
  #--------------------------------------------------------------
  networking_mode = "VPC_NATIVE"  # Recommended for all new clusters for better performance and scalability

  #--------------------------------------------------------------
  # Datapath Provider
  # Controls how network traffic is processed
  #--------------------------------------------------------------
  datapath_provider = var.datapath_provider  # ADVANCED_DATAPATH enables GKE Dataplane V2 with eBPF

  #--------------------------------------------------------------
  # Vertical Pod Autoscaling
  # Automatically adjusts resource requests/limits
  #--------------------------------------------------------------
  vertical_pod_autoscaling {
    enabled = var.enable_vertical_pod_autoscaling  # When true, VPA can recommend or apply resource changes
  }

  #--------------------------------------------------------------
  # Resource Usage Export
  # Sends cluster usage metrics to BigQuery for analysis
  #--------------------------------------------------------------
  dynamic "resource_usage_export_config" {
    for_each = var.enable_resource_usage_export ? [1] : []
    content {
      enable_network_egress_metering = var.enable_network_egress_metering             # Track network egress by namespace
      enable_resource_consumption_metering = var.enable_resource_consumption_metering  # Track CPU/memory by namespace

      bigquery_destination {
        dataset_id = var.resource_usage_export_dataset_id  # BigQuery dataset to store metrics
      }
    }
  }

  #--------------------------------------------------------------
  # Cost Management
  # Enables more granular cost allocation
  #--------------------------------------------------------------
  dynamic "cost_management_config" {
    for_each = var.enable_cost_allocation ? [1] : []
    content {
      enabled = true  # Enables cost breakdown by namespace/label
    }
  }

  #--------------------------------------------------------------
  # Deletion Protection
  # Prevents accidental cluster deletion
  #--------------------------------------------------------------
  deletion_protection = var.deletion_protection  # When true, requires explicit disabling before deletion

  #--------------------------------------------------------------
  # Resource Labels
  # GCP-level labels for organization and billing
  #--------------------------------------------------------------
  resource_labels = var.labels  # Key-value pairs applied to the cluster resource

  #--------------------------------------------------------------
  # Operation Timeouts
  # Configures how long to wait for various operations
  #--------------------------------------------------------------
  timeouts {
    create = var.cluster_create_timeout  # Timeout for cluster creation
    update = var.cluster_update_timeout  # Timeout for cluster updates
    delete = var.cluster_delete_timeout  # Timeout for cluster deletion
  }

  #--------------------------------------------------------------
  # Lifecycle Management
  # Controls how Terraform handles certain changes
  #--------------------------------------------------------------
  lifecycle {
    ignore_changes = [
      node_config,          # Ignore changes to the placeholder node config
      initial_node_count    # Ignore changes to the initial count as it's managed by node pools
    ]
  }
}

#==============================================================================
# Default Node Pool
# Creates the primary node pool for general workloads
#==============================================================================
resource "google_container_node_pool" "default" {
  count                 = var.create_default_node_pool ? 1 : 0  # Only create if explicitly requested
  name                  = "${var.cluster_name}-default-pool"    # Standard naming convention
  cluster               = google_container_cluster.this.id      # Reference to the cluster created above
  location              = var.regional_cluster ? var.region : var.zone  # Match cluster's location
  project               = var.project_id
  initial_node_count    = var.default_node_count  # Starting number of nodes

  #--------------------------------------------------------------
  # Auto-scaling Configuration
  # Automatically adjusts the number of nodes based on demand
  #--------------------------------------------------------------
  autoscaling {
    min_node_count  = var.enable_node_auto_scaling ? var.default_min_node_count : null  # Minimum node count when scaling down
    max_node_count  = var.enable_node_auto_scaling ? var.default_max_node_count : null  # Maximum node count when scaling up
    location_policy = var.enable_node_auto_scaling ? var.node_location_policy : null    # BALANCED or ANY for zone selection
  }

  #--------------------------------------------------------------
  # Node Management Configuration
  # Controls automatic repair and upgrades
  #--------------------------------------------------------------
  management {
    auto_repair  = var.auto_repair   # Automatically repair unhealthy nodes
    auto_upgrade = var.auto_upgrade  # Automatically upgrade node software
  }

  #--------------------------------------------------------------
  # Upgrade Strategy
  # Controls how nodes are upgraded to minimize disruption
  #--------------------------------------------------------------
  upgrade_settings {
    max_surge       = var.max_surge        # Maximum additional nodes during upgrade
    max_unavailable = var.max_unavailable  # Maximum nodes unavailable during upgrade
  }

  #--------------------------------------------------------------
  # Node Configuration
  # Defines the VM type and properties for each node
  #--------------------------------------------------------------
  node_config {
    machine_type    = var.default_machine_type  # VM instance type (e.g., e2-standard-4)
    disk_size_gb    = var.default_disk_size_gb  # Boot disk size for container images and runtime
    disk_type       = var.default_disk_type     # pd-standard, pd-balanced, or pd-ssd
    image_type      = var.image_type            # OS image (COS_CONTAINERD, UBUNTU_CONTAINERD)
    service_account = var.service_account       # IAM service account for node VMs

    #----------------------------------------------------------
    # OAuth Scopes
    # Controls which Google APIs nodes can access
    #----------------------------------------------------------
    oauth_scopes = var.node_oauth_scopes  # List of API scopes for node VMs

    #----------------------------------------------------------
    # Labels
    # Kubernetes labels applied to nodes
    #----------------------------------------------------------
    labels = var.default_node_labels  # Key-value pairs for node selection

    #----------------------------------------------------------
    # Taints
    # Kubernetes taints for workload isolation
    #----------------------------------------------------------
    dynamic "taint" {
      for_each = var.default_node_taints
      content {
        key    = taint.value.key     # Taint identifier (e.g., "dedicated")
        value  = taint.value.value   # Taint value (e.g., "gpu")
        effect = taint.value.effect  # NoSchedule, PreferNoSchedule, or NoExecute
      }
    }

    #----------------------------------------------------------
    # Local SSD Configuration
    # Adds high-performance local storage to nodes
    #----------------------------------------------------------
    dynamic "local_ssd_count" {
      for_each = var.default_local_ssd_count > 0 ? [1] : []
      content {
        count = var.default_local_ssd_count  # Number of 375GB local SSD disks
      }
    }

    #----------------------------------------------------------
    # Tags and Metadata
    # GCE-level settings for networking and customization
    #----------------------------------------------------------
    tags     = var.default_node_tags  # Network tags for firewall rules
    metadata = var.node_metadata      # VM metadata key-value pairs

    #----------------------------------------------------------
    # Workload Identity Metadata
    # Controls access to the instance metadata server
    #----------------------------------------------------------
    workload_metadata_config {
      mode = var.enable_workload_identity ? "GKE_METADATA" : "GCE_METADATA"  # GKE_METADATA needed for Workload Identity
    }

    #----------------------------------------------------------
    # Shielded Node Configuration
    # Enhanced security features for node VMs
    #----------------------------------------------------------
    shielded_instance_config {
      enable_secure_boot          = var.enable_secure_boot           # Verifies boot integrity
      enable_integrity_monitoring = var.enable_integrity_monitoring  # Monitors for runtime integrity
    }

    #----------------------------------------------------------
    # Spot VM Configuration
    # Uses discounted but preemptible Spot VMs
    #----------------------------------------------------------
    spot = var.default_use_spot_instances  # When true, uses lower-cost preemptible VMs
  }

  #--------------------------------------------------------------
  # Operation Timeouts
  # Configures how long to wait for node pool operations
  #--------------------------------------------------------------
  timeouts {
    create = var.node_pool_create_timeout  # Timeout for node pool creation
    update = var.node_pool_update_timeout  # Timeout for node pool updates
    delete = var.node_pool_delete_timeout  # Timeout for node pool deletion
  }

  #--------------------------------------------------------------
  # Lifecycle Management
  # Controls how Terraform handles node count changes
  #--------------------------------------------------------------
  lifecycle {
    ignore_changes = [
      initial_node_count  # Ignore changes as this will be managed by autoscaler
    ]
  }
}

#==============================================================================
# Additional Node Pools
# Creates specialized node pools for different workload types
#==============================================================================
resource "google_container_node_pool" "additional" {
  for_each             = var.node_pools                    # Create multiple pools from map input
  name                 = each.key                          # Use the map key as the pool name
  cluster              = google_container_cluster.this.id  # Reference to the cluster
  location             = var.regional_cluster ? var.region : var.zone
  project              = var.project_id
  initial_node_count   = each.value.node_count            # Starting number of nodes

  #--------------------------------------------------------------
  # Auto-scaling Configuration
  # Each pool can have its own scaling parameters
  #--------------------------------------------------------------
  autoscaling {
    min_node_count  = each.value.min_count != null ? each.value.min_count : null
    max_node_count  = each.value.max_count != null ? each.value.max_count : null
    location_policy = each.value.location_policy != null ? each.value.location_policy : var.node_location_policy
  }

  #--------------------------------------------------------------
  # Node Management Configuration
  # Controls automatic repair and upgrades per pool
  #--------------------------------------------------------------
  management {
    auto_repair  = each.value.auto_repair != null ? each.value.auto_repair : var.auto_repair
    auto_upgrade = each.value.auto_upgrade != null ? each.value.auto_upgrade : var.auto_upgrade
  }

  #--------------------------------------------------------------
  # Upgrade Strategy
  # Controls node replacement strategy during upgrades
  #--------------------------------------------------------------
  upgrade_settings {
    max_surge       = each.value.max_surge != null ? each.value.max_surge : var.max_surge
    max_unavailable = each.value.max_unavailable != null ? each.value.max_unavailable : var.max_unavailable
  }

  #--------------------------------------------------------------
  # Node Configuration
  # Customized VM settings for each specialized pool
  #--------------------------------------------------------------
  node_config {
    machine_type    = each.value.machine_type  # Required - VM type for this pool
    disk_size_gb    = each.value.disk_size_gb != null ? each.value.disk_size_gb : var.default_disk_size_gb
    disk_type       = each.value.disk_type != null ? each.value.disk_type : var.default_disk_type
    image_type      = each.value.image_type != null ? each.value.image_type : var.image_type
    service_account = each.value.service_account != null ? each.value.service_account : var.service_account

    #----------------------------------------------------------
    # OAuth Scopes
    # API access permissions for nodes in this pool
    #----------------------------------------------------------
    oauth_scopes = each.value.oauth_scopes != null ? each.value.oauth_scopes : var.node_oauth_scopes

    #----------------------------------------------------------
    # Labels
    # Kubernetes labels for node selection
    #----------------------------------------------------------
    labels = each.value.labels  # Pool-specific labels

    #----------------------------------------------------------
    # Taints
    # Kubernetes taints to control pod scheduling
    #----------------------------------------------------------
    dynamic "taint" {
      for_each = each.value.taints != null ? each.value.taints : []
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    #----------------------------------------------------------
    # Local SSD Configuration
    # High-performance local storage
    #----------------------------------------------------------
    dynamic "local_ssd_count" {
      for_each = each.value.local_ssd_count != null && each.value.local_ssd_count > 0 ? [1] : []
      content {
        count = each.value.local_ssd_count
      }
    }

    #----------------------------------------------------------
    # Tags and Metadata
    # GCE-level configuration
    #----------------------------------------------------------
    tags     = each.value.tags != null ? each.value.tags : var.default_node_tags
    metadata = each.value.metadata != null ? each.value.metadata : var.node_metadata

    #----------------------------------------------------------
    # Workload Identity Metadata
    # Controls access to instance metadata
    #----------------------------------------------------------
    workload_metadata_config {
      mode = var.enable_workload_identity ? "GKE_METADATA" : "GCE_METADATA"
    }

    #----------------------------------------------------------
    # Shielded Node Configuration
    # Enhanced security features
    #----------------------------------------------------------
    shielded_instance_config {
      enable_secure_boot          = each.value.enable_secure_boot != null ? each.value.enable_secure_boot : var.enable_secure_boot
      enable_integrity_monitoring = each.value.enable_integrity_monitoring != null ? each.value.enable_integrity_monitoring : var.enable_integrity_monitoring
    }

    #----------------------------------------------------------
    # Spot VM Configuration
    # Cost-saving but preemptible instances
    #----------------------------------------------------------
    spot = each.value.spot != null ? each.value.spot : false
  }

  #--------------------------------------------------------------
  # Operation Timeouts
  # Configures wait times for operations
  #--------------------------------------------------------------
  timeouts {
    create = var.node_pool_create_timeout
    update = var.node_pool_update_timeout
    delete = var.node_pool_delete_timeout
  }

  #--------------------------------------------------------------
  # Lifecycle Management
  # Handles autoscaling-driven changes
  #--------------------------------------------------------------
  lifecycle {
    ignore_changes = [
      initial_node_count  # Ignore as the autoscaler will manage this
    ]
  }
}

#==============================================================================
# Kubeconfig Generation
# Creates a local kubeconfig file for cluster access
#==============================================================================
resource "local_file" "kubeconfig" {
  content  = templatefile("${path.module}/templates/kubeconfig.tpl", {
    cluster_name    = google_container_cluster.this.name
    endpoint        = google_container_cluster.this.endpoint
    cluster_ca      = google_container_cluster.this.master_auth[0].cluster_ca_certificate
    client_token    = data.google_client_config.current.access_token
    gcp_project     = var.project_id
    gcp_location    = var.regional_cluster ? var.region : var.zone
  })
  filename = "${path.module}/kubeconfig_${var.cluster_name}"  # Generated filename includes cluster name
}
