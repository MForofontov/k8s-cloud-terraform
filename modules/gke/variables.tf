#==============================================================================
# GKE Cluster Variables
#
# This file defines all configuration options for Google Kubernetes Engine 
# clusters. Variables are organized into logical sections and include detailed
# descriptions, defaults, and usage guidance.
#==============================================================================

#==============================================================================
# Required Variables
# These variables must be provided when using this module
#==============================================================================
variable "project_id" {
  description = "The Google Cloud project ID where the GKE cluster will be created. This determines billing, permissions, and resource isolation."
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster. This identifier will be used in logs, monitoring, and for accessing the cluster. Must be unique within the project and region."
  type        = string
}

#==============================================================================
# Location Configuration
# Controls where the cluster and its nodes are physically deployed
#==============================================================================
variable "region" {
  description = "The Google Cloud region where the GKE cluster will be created (e.g., 'us-central1'). For regional clusters, this determines the control plane location and default node locations."
  type        = string
}

variable "zone" {
  description = "The Google Cloud zone for zonal clusters (e.g., 'us-central1-a'). Only required when creating a zonal cluster (regional_cluster = false). Zonal clusters have a single control plane in one zone."
  type        = string
  default     = null
}

variable "regional_cluster" {
  description = "Whether to create a regional cluster (true) or a zonal cluster (false). Regional clusters have control planes across multiple zones for higher availability but cost more. Recommended for production."
  type        = bool
  default     = true
}

variable "node_locations" {
  description = "The list of zones within the region where worker nodes should be located (e.g., ['us-central1-a', 'us-central1-b']). Only applies to regional clusters. If empty, GKE will use the region's default zones."
  type        = list(string)
  default     = []
}

#==============================================================================
# Basic Cluster Configuration
# General settings for the GKE cluster
#==============================================================================
variable "description" {
  description = "Human-readable description of the GKE cluster. Useful for documenting the purpose of the cluster and its workloads."
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "The Kubernetes version for the cluster master. If not specified, GKE uses the latest supported version. Format: '1.25.5-gke.2000' or just '1.25'. Check available versions with 'gcloud container get-server-config'."
  type        = string
  default     = null
}

variable "release_channel" {
  description = "The release channel determines the frequency of automated Kubernetes version updates. 'RAPID' for early access, 'REGULAR' for standard updates, 'STABLE' for reliable production, or 'UNSPECIFIED' to manage versions manually."
  type        = string
  default     = "REGULAR"
  validation {
    condition     = contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Release channel must be one of UNSPECIFIED, RAPID, REGULAR, or STABLE."
  }
}

variable "deletion_protection" {
  description = "When set to true, the cluster cannot be deleted via Terraform unless this flag is set to false. This prevents accidental deletion of production clusters through automation."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to be applied to the GKE cluster resource. These are distinct from Kubernetes node labels and are useful for organizational billing, filtering in Cloud Console, and enforcing policies. Example: { environment = 'prod', team = 'platform' }"
  type        = map(string)
  default     = {}
}

#==============================================================================
# Networking Configuration
# Defines how the cluster interacts with VPC networks and IP addressing
#==============================================================================
variable "network" {
  description = "The name of the Google Cloud VPC network to host the GKE cluster. Must exist before cluster creation. This network provides connectivity between cluster components and to other Google Cloud services."
  type        = string
}

variable "subnetwork" {
  description = "The name of the Google Cloud VPC subnetwork where the cluster will be created. Must exist within the VPC network specified by 'network' variable and have suitable IP ranges."
  type        = string
}

variable "cluster_ipv4_cidr_block" {
  description = "The IP address range for Pod IPs in CIDR notation (e.g., '10.4.0.0/14'). If not specified, GKE automatically assigns a range from the VPC's secondary ranges. Must not overlap with existing subnet ranges."
  type        = string
  default     = null
}

variable "services_ipv4_cidr_block" {
  description = "The IP address range for Kubernetes Service IPs in CIDR notation (e.g., '10.0.32.0/20'). If not specified, GKE automatically assigns a range. Must not overlap with pod or VPC ranges."
  type        = string
  default     = null
}

variable "enable_private_nodes" {
  description = "When true, nodes only have internal IP addresses and communicate with the control plane through private networking. Increases security by removing public IPs from nodes, but requires NAT for external internet access."
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "When true, the cluster control plane will only be accessible through private IP addresses. This completely isolates the control plane from the public internet, requiring a bastion host or VPN to access kubectl."
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation for the control plane (master) network (e.g., '172.16.0.0/28'). Must be a /28 CIDR block and not overlap with any other IP ranges in use. Required when enabling private nodes."
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_cidr_blocks" {
  description = "List of CIDR blocks authorized to access the Kubernetes control plane API. Use this to restrict access to trusted networks like corporate VPNs or bastion hosts. Example: [{ cidr_block = '10.0.0.0/8', display_name = 'internal-network' }]"
  type        = list(object({ cidr_block = string, display_name = string }))
  default     = []
}

variable "enable_network_policy" {
  description = "Enable Kubernetes NetworkPolicy enforcement using Calico. Network policies provide micro-segmentation for pod-to-pod traffic, allowing you to define rules for which pods can communicate with each other."
  type        = bool
  default     = true
}

variable "network_policy_provider" {
  description = "The network policy provider implementation to use. Currently, only 'CALICO' is supported by GKE. This field is only relevant when enable_network_policy is true."
  type        = string
  default     = "CALICO"
}

variable "datapath_provider" {
  description = "The desired datapath provider for the cluster. 'ADVANCED_DATAPATH' (recommended) enables GKE Dataplane V2 with eBPF for better performance and visibility. 'LEGACY_DATAPATH' uses the standard GKE networking."
  type        = string
  default     = "ADVANCED_DATAPATH"
}

#==============================================================================
# Default Node Pool Configuration
# Settings for the cluster's initial node pool
#==============================================================================
variable "create_default_node_pool" {
  description = "Whether to create a default node pool. Set to false when you want to completely customize node pools and remove the default pool that GKE automatically creates."
  type        = bool
  default     = true
}

variable "default_node_count" {
  description = "The number of nodes in the default node pool. For autoscaled pools, this sets the initial node count. Each node runs multiple pods, so size based on workload requirements."
  type        = number
  default     = 1
}

variable "default_machine_type" {
  description = "The GCE machine type for nodes in the default pool (e.g., 'e2-medium', 'e2-standard-4', 'n2-standard-8'). Determines CPU and memory available to pods. Choose based on workload requirements and cost constraints."
  type        = string
  default     = "e2-medium"
}

variable "default_disk_size_gb" {
  description = "The disk size (in GB) for each node in the default pool. This disk hosts the container OS, Docker images, and emptyDir volumes. For production, 100GB+ is recommended."
  type        = number
  default     = 100
}

variable "default_disk_type" {
  description = "The disk type for nodes in the default pool. Options: 'pd-standard' (HDD, cheaper), 'pd-balanced', or 'pd-ssd' (faster, more expensive). Production workloads typically benefit from SSD performance."
  type        = string
  default     = "pd-standard"
}

variable "default_node_labels" {
  description = "Kubernetes labels applied to nodes in the default pool. These can be used for node selection in pod deployments. Example: { 'workload-type' = 'general', 'environment' = 'prod' }"
  type        = map(string)
  default     = {}
}

variable "default_node_taints" {
  description = "Kubernetes taints applied to nodes in the default pool. Taints prevent pods from scheduling unless they have matching tolerations. Example: [{ key = 'dedicated', value = 'gpu', effect = 'NO_SCHEDULE' }]"
  type        = list(object({ key = string, value = string, effect = string }))
  default     = []
}

variable "default_node_tags" {
  description = "Network tags applied to the GCE instances in the default node pool. These tags can be used for firewall rules or routes. Example: ['gke-node', 'prod-nodes']"
  type        = list(string)
  default     = []
}

variable "default_local_ssd_count" {
  description = "The number of local SSD disks attached to each node in the default pool. Local SSDs provide high-performance storage but data is lost when the node is deleted or repaired."
  type        = number
  default     = 0
}

variable "default_use_spot_instances" {
  description = "Whether to use Spot VMs for the default node pool. Spot VMs are significantly cheaper but can be preempted at any time, making them suitable for fault-tolerant or batch workloads, but not for critical services."
  type        = bool
  default     = false
}

variable "default_min_node_count" {
  description = "Minimum number of nodes in the default node pool when autoscaling is enabled. Sets the lower bound for cluster size. Should be sized to handle minimum expected load with resilience."
  type        = number
  default     = 1
}

variable "default_max_node_count" {
  description = "Maximum number of nodes in the default node pool when autoscaling is enabled. Sets the upper bound for cluster scaling. Consider your quota limits and cost constraints when setting this value."
  type        = number
  default     = 3
}

#==============================================================================
# Additional Node Pools
# Configuration for custom node pools beyond the default
#==============================================================================
variable "node_pools" {
  description = "Map of additional node pool configurations. Use this to create specialized pools for different workloads (e.g., compute-intensive, memory-intensive, GPU). Each pool can have unique machine types, scaling parameters, and node configurations."
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

#==============================================================================
# Node Configuration (Common Settings)
# Settings that apply to all node pools unless overridden
#==============================================================================
variable "image_type" {
  description = "The image type for all nodes. 'COS_CONTAINERD' (Container-Optimized OS) is Google's secure, minimal OS optimized for running containers. Other options include 'UBUNTU_CONTAINERD' for Ubuntu-based nodes."
  type        = string
  default     = "COS_CONTAINERD"
}

variable "service_account" {
  description = "The Google Cloud IAM service account email to be used by node VMs. This account determines what Google Cloud resources nodes can access. If not specified, the project's default compute service account is used."
  type        = string
  default     = null
}

variable "node_oauth_scopes" {
  description = "OAuth scopes granted to the node service account. These determine which Google Cloud APIs nodes can access. The defaults allow logging, monitoring, and read-only storage access."
  type        = list(string)
  default     = [
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/devstorage.read_only"
  ]
}

variable "node_metadata" {
  description = "Metadata key/value pairs assigned to nodes. This can be used to pass configuration information or customize the node environment. Example: { 'cluster-name' = 'prod-cluster', 'node-type' = 'standard' }"
  type        = map(string)
  default     = {}
}

#==============================================================================
# Auto-scaling Configuration
# Controls how node pools automatically adjust capacity
#==============================================================================
variable "enable_node_auto_scaling" {
  description = "Whether to enable cluster autoscaler for node pools. When enabled, GKE automatically adds or removes nodes based on pod scheduling needs, optimizing resource usage and costs."
  type        = bool
  default     = true
}

variable "node_location_policy" {
  description = "Location policy for the node pool autoscaler. 'BALANCED' (default) spreads nodes evenly across zones for high availability. 'ANY' optimizes for resource availability, potentially creating imbalances across zones."
  type        = string
  default     = "BALANCED"
}

#==============================================================================
# Auto-upgrade and Repair
# Settings for automated node maintenance
#==============================================================================
variable "auto_repair" {
  description = "Whether nodes will be automatically repaired by GKE. When enabled, GKE detects and fixes unhealthy nodes, maintaining cluster health. Highly recommended for production clusters."
  type        = bool
  default     = true
}

variable "auto_upgrade" {
  description = "Whether nodes will be automatically upgraded to match the cluster's Kubernetes version. When enabled, GKE handles node version management, keeping nodes compatible with the control plane."
  type        = bool
  default     = true
}

variable "max_surge" {
  description = "The maximum number of additional nodes that can be created during node pool upgrades. Higher values allow faster upgrades but require more spare capacity in your GCP project quotas."
  type        = number
  default     = 1
}

variable "max_unavailable" {
  description = "The maximum number of nodes that can be simultaneously unavailable during node pool upgrades. Higher values speed up upgrades but reduce cluster capacity during the process."
  type        = number
  default     = 0
}

#==============================================================================
# Security Configuration
# Settings to enhance cluster and workload security
#==============================================================================
variable "enable_secure_boot" {
  description = "Enable Secure Boot for nodes. This verifies node boot components are signed by a trusted authority, preventing rootkits and bootkits. Part of GKE's Shielded Nodes feature set for enhanced security."
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Enable integrity monitoring for nodes. This verifies node boot files haven't been tampered with by comparing against known-good baselines. Part of GKE's Shielded Nodes feature set."
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity, which allows Kubernetes service accounts to act as Google Cloud IAM service accounts. This is the recommended way for pods to securely access Google Cloud services without managing keys."
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization, which requires images to be signed by trusted authorities before deployment. This enforces supply-chain security by preventing unauthorized container images from running in your cluster."
  type        = bool
  default     = false
}

#==============================================================================
# Features and Add-ons
# Optional GKE capabilities that can be enabled
#==============================================================================
variable "enable_http_load_balancing" {
  description = "Enable the HTTP (L7) load balancing controller add-on. This integrates with Google Cloud Load Balancing for ingress resources, providing advanced routing, SSL termination, and global load distribution."
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable the Horizontal Pod Autoscaler add-on. This automatically adjusts the number of pod replicas based on CPU utilization or custom metrics, ensuring applications have the right resources."
  type        = bool
  default     = true
}

variable "enable_vertical_pod_autoscaling" {
  description = "Enable Vertical Pod Autoscaling. This automatically adjusts CPU and memory requests/limits for pods based on their usage patterns, improving resource efficiency without manual tuning."
  type        = bool
  default     = false
}

variable "enable_dns_cache" {
  description = "Enable NodeLocal DNSCache add-on. This improves DNS performance by caching queries on each node, reducing latency and the load on kube-dns. Especially beneficial for applications making many DNS lookups."
  type        = bool
  default     = false
}

variable "enable_filestore_csi_driver" {
  description = "Enable the Filestore CSI driver add-on. This allows pods to use Google Cloud Filestore as a shared file system with ReadWriteMany access mode, useful for applications that need shared filesystem access."
  type        = bool
  default     = false
}

variable "enable_gce_persistent_disk_csi_driver" {
  description = "Enable the GCE Persistent Disk CSI driver add-on. This provides improved storage management capabilities for GCE PDs, including volume snapshots, resizing, and topology-aware provisioning."
  type        = bool
  default     = true
}

variable "enable_config_connector" {
  description = "Enable Config Connector add-on. This allows managing Google Cloud resources through Kubernetes custom resources, enabling GitOps workflows for infrastructure beyond just Kubernetes objects."
  type        = bool
  default     = false
}

#==============================================================================
# Monitoring and Logging
# Observability configuration for the GKE cluster
#==============================================================================
variable "logging_enabled_components" {
  description = "List of components to enable logging for. 'SYSTEM_COMPONENTS' covers cluster components like kubelet and scheduler. 'WORKLOADS' covers container logs from user applications."
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_enabled_components" {
  description = "List of components to enable monitoring for. 'SYSTEM_COMPONENTS' covers cluster metrics like node CPU/memory. 'WORKLOADS' covers container metrics from user applications."
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "enable_managed_prometheus" {
  description = "Enable Google Cloud Managed Service for Prometheus. This provides a fully managed, cost-effective metrics solution that's integrated with Google Cloud monitoring, without managing Prometheus servers."
  type        = bool
  default     = false
}

variable "enable_resource_usage_export" {
  description = "Enable resource consumption metering. When enabled, GKE exports resource consumption data to BigQuery for detailed analysis, chargeback, and capacity planning."
  type        = bool
  default     = false
}

variable "enable_network_egress_metering" {
  description = "Enable network egress metering. This tracks and exports network egress traffic data, helping to identify bandwidth-heavy services and potential cost optimization opportunities."
  type        = bool
  default     = false
}

variable "enable_resource_consumption_metering" {
  description = "Enable resource consumption metering. This tracks CPU, memory, and storage usage by namespace and exports the data for analysis. Useful for internal chargeback or usage-based cost allocation."
  type        = bool
  default     = false
}

variable "resource_usage_export_dataset_id" {
  description = "The ID of a BigQuery Dataset for resource usage export. Required when resource usage export is enabled. Must be in the same project as the GKE cluster or have appropriate permissions configured."
  type        = string
  default     = null
}

variable "enable_cost_allocation" {
  description = "Enable cost allocation to track the cost of a shared tenant cluster on a per-namespace basis. This adds special labels to node metadata for billing purposes, enabling more granular cost breakdowns."
  type        = bool
  default     = false
}

#==============================================================================
# Maintenance Window
# Controls when GKE can perform cluster upgrades and maintenance
#==============================================================================
variable "maintenance_start_time" {
  description = "Start time of the maintenance window in RFC3339 format (HH:MM). Combined with end_time and recurrence, this defines when GKE can perform upgrades and maintenance. Example: '01:00'"
  type        = string
  default     = null
}

variable "maintenance_end_time" {
  description = "End time of the maintenance window in RFC3339 format (HH:MM). Maintenance operations will only start during the window and may continue past the end time. Example: '05:00'"
  type        = string
  default     = null
}

variable "maintenance_recurrence" {
  description = "Recurrence of the maintenance window in RRULE format (RFC5545). Defines how frequently the maintenance window occurs. Example: 'FREQ=WEEKLY;BYDAY=SA,SU' for weekends only."
  type        = string
  default     = null
}

#==============================================================================
# Operation Timeouts
# Controls how long Terraform waits for various GKE operations to complete
#==============================================================================
variable "cluster_create_timeout" {
  description = "Timeout for creating the GKE cluster. Increase this value for larger clusters or when experiencing networking/quota issues. Operations exceeding this timeout will cause Terraform to return an error."
  type        = string
  default     = "30m"
}

variable "cluster_update_timeout" {
  description = "Timeout for updating the GKE cluster. Updates involving node auto-upgrades or significant changes may require more time. If timeouts occur frequently, consider incremental changes or maintenance windows."
  type        = string
  default     = "30m"
}

variable "cluster_delete_timeout" {
  description = "Timeout for deleting the GKE cluster. Larger clusters with many resources may take longer to delete. A timeout here doesn't mean resources weren't deleted - they may continue to be removed asynchronously."
  type        = string
  default     = "30m"
}

variable "node_pool_create_timeout" {
  description = "Timeout for creating a node pool. Large node pools or those with custom initialization scripts may require more time. Consider adjusting when creating pools with many nodes or complex configurations."
  type        = string
  default     = "30m"
}

variable "node_pool_update_timeout" {
  description = "Timeout for updating a node pool. Updates involving full node replacement, such as changing machine types, will take longer and may need a higher timeout value to complete successfully."
  type        = string
  default     = "30m"
}

variable "node_pool_delete_timeout" {
  description = "Timeout for deleting a node pool. Deletion involves draining nodes, which depends on pod lifecycle and PodDisruptionBudgets. For pools running critical workloads, a higher value may be needed."
  type        = string
  default     = "30m"
}