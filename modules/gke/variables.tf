// GKE Cluster Variables

# Required variables
variable "project_id" {
  description = "The project ID to host the cluster in"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}

# Location variables
variable "region" {
  description = "The region to host the cluster in (required for regional clusters)"
  type        = string
}

variable "zone" {
  description = "The zone to host the cluster in (required for zonal clusters)"
  type        = string
  default     = null
}

variable "regional_cluster" {
  description = "Whether to create a regional cluster (true) or a zonal cluster (false)"
  type        = bool
  default     = true
}

variable "node_locations" {
  description = "The list of zones in which the cluster's nodes should be located (regional clusters only)"
  type        = list(string)
  default     = []
}

# Cluster configuration
variable "description" {
  description = "Description of the cluster"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "The Kubernetes version of the masters. If not set, the latest available version is used"
  type        = string
  default     = null
}

variable "release_channel" {
  description = "The release channel of the cluster (UNSPECIFIED, RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
  validation {
    condition     = contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Release channel must be one of UNSPECIFIED, RAPID, REGULAR, or STABLE."
  }
}

variable "deletion_protection" {
  description = "Whether or not to allow Terraform to destroy the cluster"
  type        = bool
  default     = true
}

variable "labels" {
  description = "The GCE resource labels to be applied to the cluster"
  type        = map(string)
  default     = {}
}

# Networking variables
variable "network" {
  description = "The VPC network to host the cluster in"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster in"
  type        = string
}

variable "cluster_ipv4_cidr_block" {
  description = "The IP address range for the cluster pod IPs in CIDR notation"
  type        = string
  default     = null
}

variable "services_ipv4_cidr_block" {
  description = "The IP address range for the cluster service IPs in CIDR notation"
  type        = string
  default     = null
}

variable "enable_private_nodes" {
  description = "When true, nodes have internal IP addresses only"
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "When true, the cluster's private endpoint is used as the primary"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation to use for the hosted master network"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_cidr_blocks" {
  description = "List of master authorized networks. If none are provided, disallow external access (except the cluster node IPs, which GKE automatically allows)"
  type        = list(object({ cidr_block = string, display_name = string }))
  default     = []
}

variable "enable_network_policy" {
  description = "Enable network policy addon"
  type        = bool
  default     = true
}

variable "network_policy_provider" {
  description = "The network policy provider (CALICO)"
  type        = string
  default     = "CALICO"
}

variable "datapath_provider" {
  description = "The desired datapath provider for this cluster (DATAPATH_PROVIDER_UNSPECIFIED, LEGACY_DATAPATH, ADVANCED_DATAPATH)"
  type        = string
  default     = "ADVANCED_DATAPATH"
}

# Default node pool configuration
variable "create_default_node_pool" {
  description = "Create a default node pool"
  type        = bool
  default     = true
}

variable "default_node_count" {
  description = "The number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "default_machine_type" {
  description = "The machine type for the default node pool"
  type        = string
  default     = "e2-medium"
}

variable "default_disk_size_gb" {
  description = "The disk size (in GB) for the default node pool"
  type        = number
  default     = 100
}

variable "default_disk_type" {
  description = "The disk type for the default node pool"
  type        = string
  default     = "pd-standard"
}

variable "default_node_labels" {
  description = "The Kubernetes labels (key/value pairs) to be applied to nodes in the default pool"
  type        = map(string)
  default     = {}
}

variable "default_node_taints" {
  description = "The Kubernetes taints to be applied to nodes in the default pool"
  type        = list(object({ key = string, value = string, effect = string }))
  default     = []
}

variable "default_node_tags" {
  description = "The list of instance tags applied to all nodes in the default pool"
  type        = list(string)
  default     = []
}

variable "default_local_ssd_count" {
  description = "The number of local SSD disks to be attached to each node in the default pool"
  type        = number
  default     = 0
}

variable "default_use_spot_instances" {
  description = "Whether to use spot instances for the default node pool"
  type        = bool
  default     = false
}

variable "default_min_node_count" {
  description = "Minimum number of nodes in the default node pool when autoscaling is enabled"
  type        = number
  default     = 1
}

variable "default_max_node_count" {
  description = "Maximum number of nodes in the default node pool when autoscaling is enabled"
  type        = number
  default     = 3
}

# Additional node pools
variable "node_pools" {
  description = "List of node pool configurations"
  type        = map(object({
    machine_type    = string
    node_count      = number
    min_count       = optional(number)
    max_count       = optional(number)
    disk_size_gb    = optional(number)
    disk_type       = optional(string)
    image_type      = optional(string)
    service_account = optional(string)
    oauth_scopes    = optional(list(string))
    labels          = optional(map(string), {})
    taints          = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    local_ssd_count = optional(number)
    tags            = optional(list(string))
    metadata        = optional(map(string))
    enable_secure_boot = optional(bool)
    enable_integrity_monitoring = optional(bool)
    spot            = optional(bool)
    auto_repair     = optional(bool)
    auto_upgrade    = optional(bool)
    max_surge       = optional(number)
    max_unavailable = optional(number)
    location_policy = optional(string)
  }))
  default = {}
}

# Node configuration (common)
variable "image_type" {
  description = "The image type to use for nodes. Defaults to COS_CONTAINERD"
  type        = string
  default     = "COS_CONTAINERD"
}

variable "service_account" {
  description = "The Google Cloud Platform Service Account to be used by the node VMs"
  type        = string
  default     = null
}

variable "node_oauth_scopes" {
  description = "The set of Google API scopes to be made available on all of the node VMs"
  type        = list(string)
  default     = [
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/devstorage.read_only"
  ]
}

variable "node_metadata" {
  description = "The metadata key/value pairs assigned to nodes"
  type        = map(string)
  default     = {}
}

# Auto-scaling configuration
variable "enable_node_auto_scaling" {
  description = "Whether to enable node pool autoscaling"
  type        = bool
  default     = true
}

variable "node_location_policy" {
  description = "Location policy for the node pool autoscaler (BALANCED, ANY)"
  type        = string
  default     = "BALANCED"
}

# Auto-upgrade and repair
variable "auto_repair" {
  description = "Whether the nodes will be automatically repaired"
  type        = bool
  default     = true
}

variable "auto_upgrade" {
  description = "Whether the nodes will be automatically upgraded"
  type        = bool
  default     = true
}

variable "max_surge" {
  description = "The number of additional nodes that can be added during an upgrade"
  type        = number
  default     = 1
}

variable "max_unavailable" {
  description = "The number of nodes that can be simultaneously unavailable during an upgrade"
  type        = number
  default     = 0
}

# Security variables
variable "enable_secure_boot" {
  description = "Enable secure boot for nodes"
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Enable integrity monitoring for nodes"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity on the cluster"
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization on the cluster"
  type        = bool
  default     = false
}

# Features and add-ons
variable "enable_http_load_balancing" {
  description = "Enable HTTP load balancing add-on"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable horizontal pod autoscaling add-on"
  type        = bool
  default     = true
}

variable "enable_vertical_pod_autoscaling" {
  description = "Enable vertical pod autoscaling"
  type        = bool
  default     = false
}

variable "enable_dns_cache" {
  description = "Enable NodeLocal DNSCache add-on"
  type        = bool
  default     = false
}

variable "enable_filestore_csi_driver" {
  description = "Enable Filestore CSI driver add-on"
  type        = bool
  default     = false
}

variable "enable_gce_persistent_disk_csi_driver" {
  description = "Enable GCE Persistent Disk CSI driver add-on"
  type        = bool
  default     = true
}

variable "enable_config_connector" {
  description = "Enable Config Connector add-on"
  type        = bool
  default     = false
}

# Monitoring and logging
variable "logging_enabled_components" {
  description = "List of components to enable logging (SYSTEM_COMPONENTS, WORKLOADS)"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_enabled_components" {
  description = "List of components to enable monitoring (SYSTEM_COMPONENTS, WORKLOADS)"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "enable_managed_prometheus" {
  description = "Enable managed Prometheus"
  type        = bool
  default     = false
}

variable "enable_resource_usage_export" {
  description = "Enable resource consumption metering"
  type        = bool
  default     = false
}

variable "enable_network_egress_metering" {
  description = "Enable network egress metering for this cluster"
  type        = bool
  default     = false
}

variable "enable_resource_consumption_metering" {
  description = "Enable resource consumption metering on this cluster"
  type        = bool
  default     = false
}

variable "resource_usage_export_dataset_id" {
  description = "The ID of a BigQuery Dataset for resource usage export"
  type        = string
  default     = null
}

variable "enable_cost_allocation" {
  description = "Enable cost allocation to determine the cost of a shared tenant cluster on a per-namespace basis"
  type        = bool
  default     = false
}

# Maintenance window
variable "maintenance_start_time" {
  description = "Start time of the maintenance window in RFC3339 format (HH:MM)"
  type        = string
  default     = null
}

variable "maintenance_end_time" {
  description = "End time of the maintenance window in RFC3339 format (HH:MM)"
  type        = string
  default     = null
}

variable "maintenance_recurrence" {
  description = "Recurrence of the maintenance window (RRULE format)"
  type        = string
  default     = null
}

# Timeouts
variable "cluster_create_timeout" {
  description = "Timeout for creating the cluster"
  type        = string
  default     = "30m"
}

variable "cluster_update_timeout" {
  description = "Timeout for updating the cluster"
  type        = string
  default     = "30m"
}

variable "cluster_delete_timeout" {
  description = "Timeout for deleting the cluster"
  type        = string
  default     = "30m"
}

variable "node_pool_create_timeout" {
  description = "Timeout for creating a node pool"
  type        = string
  default     = "30m"
}

variable "node_pool_update_timeout" {
  description = "Timeout for updating a node pool"
  type        = string
  default     = "30m"
}

variable "node_pool_delete_timeout" {
  description = "Timeout for deleting a node pool"
  type        = string
  default     = "30m"
}