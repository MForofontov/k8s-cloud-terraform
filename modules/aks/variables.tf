// AKS Cluster Variables

variable "resource_group_name" {
  description = "Name of the resource group where the AKS cluster will be created"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster. If not specified, the cluster name will be used"
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.27"
}

variable "node_resource_group_name" {
  description = "Name of the resource group where the AKS node resources will be created"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "The SKU tier for the AKS cluster (Free or Standard)"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "The sku_tier must be either Free or Standard."
  }
}

# Default node pool variables
variable "default_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "default"
}

variable "default_node_pool_vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "subnet_id" {
  description = "Subnet ID for the AKS cluster"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for the AKS nodes"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "default_node_pool_node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling for the default node pool"
  type        = bool
  default     = true
}

variable "default_node_pool_min_count" {
  description = "Minimum number of nodes for the default node pool when auto scaling is enabled"
  type        = number
  default     = 1
}

variable "default_node_pool_max_count" {
  description = "Maximum number of nodes for the default node pool when auto scaling is enabled"
  type        = number
  default     = 5
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB for the default node pool"
  type        = number
  default     = 128
}

variable "os_disk_type" {
  description = "OS disk type for the default node pool"
  type        = string
  default     = "Managed"
}

variable "default_node_pool_labels" {
  description = "Labels to apply to nodes in the default node pool"
  type        = map(string)
  default     = {}
}

variable "default_node_pool_taints" {
  description = "Taints to apply to nodes in the default node pool"
  type        = list(string)
  default     = []
}

# Network configuration
variable "network_plugin" {
  description = "Network plugin for the AKS cluster"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy for the AKS cluster"
  type        = string
  default     = "azure"
}

variable "dns_service_ip" {
  description = "IP address for the DNS service"
  type        = string
  default     = "10.0.0.10"
}

variable "service_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "docker_bridge_cidr" {
  description = "CIDR block for the Docker bridge"
  type        = string
  default     = "172.17.0.1/16"
}

variable "outbound_type" {
  description = "Outbound traffic type for the AKS cluster"
  type        = string
  default     = "loadBalancer"
}

# Security configuration
variable "admin_group_object_ids" {
  description = "Azure AD group object IDs with admin access to the cluster"
  type        = list(string)
  default     = []
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = true
}

variable "api_server_authorized_ip_ranges" {
  description = "IP ranges authorized to access the API server"
  type        = list(string)
  default     = []
}

variable "enable_private_cluster" {
  description = "Enable private cluster (API server only accessible via private IP)"
  type        = bool
  default     = false
}

# Add-ons
variable "enable_azure_policy" {
  description = "Enable Azure Policy add-on"
  type        = bool
  default     = false
}

variable "enable_log_analytics_workspace" {
  description = "Enable Log Analytics workspace for container insights"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_sku" {
  description = "SKU for the Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_in_days" {
  description = "Retention period in days for logs"
  type        = number
  default     = 30
}

variable "enable_key_vault_secrets_provider" {
  description = "Enable Key Vault Secrets Provider"
  type        = bool
  default     = false
}

variable "secret_rotation_enabled" {
  description = "Enable secret rotation for Key Vault Secrets Provider"
  type        = bool
  default     = false
}

variable "secret_rotation_interval" {
  description = "Secret rotation interval for Key Vault Secrets Provider (e.g., '2m')"
  type        = string
  default     = "2m"
}

# Maintenance and upgrades
variable "maintenance_window_day" {
  description = "Day of the week for maintenance window (e.g., 'Sunday')"
  type        = string
  default     = "Sunday"
}

variable "maintenance_window_hours" {
  description = "Hours during the maintenance day when upgrades are allowed (e.g., [0, 1, 2])"
  type        = list(number)
  default     = [0, 1, 2]
}

variable "upgrade_channel" {
  description = "Upgrade channel for the AKS cluster (stable, rapid, node-image, patch)"
  type        = string
  default     = "stable"
  validation {
    condition     = contains(["stable", "rapid", "node-image", "patch"], var.upgrade_channel)
    error_message = "The upgrade_channel must be one of: stable, rapid, node-image, patch."
  }
}

# Additional node pools
variable "additional_node_pools" {
  description = "Map of additional node pools to create"
  type = map(object({
    vm_size             = string
    node_count          = number
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    os_disk_size_gb     = number
    os_disk_type        = string
    node_labels         = map(string)
    node_taints         = list(string)
    mode                = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}