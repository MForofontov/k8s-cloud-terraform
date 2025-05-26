# Variables for Azure Kubernetes Service (AKS) module

# Resource Group
variable "resource_group_name" {
  description = "The name of the resource group in which to create the AKS cluster"
  type        = string
}

# Cluster Configuration
variable "cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix specified when creating the managed cluster"
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the AKS cluster"
  type        = string
  default     = null
}

variable "node_resource_group_name" {
  description = "The name of the resource group in which to create the AKS cluster resources"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "The SKU tier for the AKS cluster (Free or Paid)"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Paid"], var.sku_tier)
    error_message = "The sku_tier must be either 'Free' or 'Paid'."
  }
}

# Default Node Pool
variable "default_node_pool_name" {
  description = "The name of the default node pool"
  type        = string
  default     = "default"
}

variable "default_node_pool_vm_size" {
  description = "The size of the VMs in the default node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "subnet_id" {
  description = "The ID of the subnet where the default node pool should be deployed"
  type        = string
}

variable "availability_zones" {
  description = "A list of availability zones to use for the default node pool"
  type        = list(string)
  default     = null
}

variable "default_node_pool_node_count" {
  description = "The initial number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for the default node pool"
  type        = bool
  default     = false
}

variable "default_node_pool_min_count" {
  description = "The minimum number of nodes in the default node pool when auto-scaling is enabled"
  type        = number
  default     = 1
}

variable "default_node_pool_max_count" {
  description = "The maximum number of nodes in the default node pool when auto-scaling is enabled"
  type        = number
  default     = 3
}

variable "os_disk_size_gb" {
  description = "The size of the OS disk in GB for each node in the default node pool"
  type        = number
  default     = 128
}

variable "os_disk_type" {
  description = "The type of OS disk for each node in the default node pool"
  type        = string
  default     = "Managed"
}

variable "default_node_pool_labels" {
  description = "A map of Kubernetes labels to apply to nodes in the default node pool"
  type        = map(string)
  default     = {}
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

# Azure AD Integration
variable "admin_group_object_ids" {
  description = "A list of Azure AD group object IDs that will have admin role on the cluster"
  type        = list(string)
  default     = []
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = false
}

variable "tenant_id" {
  description = "The tenant ID used for Azure Active Directory application"
  type        = string
  default     = null
}

# Networking
variable "network_plugin" {
  description = "The network plugin to use for the AKS cluster (azure or kubenet)"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "The network_plugin must be either 'azure' or 'kubenet'."
  }
}

variable "network_policy" {
  description = "The network policy to use for the AKS cluster (azure, calico)"
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "calico", "cilium", ""], var.network_policy)
    error_message = "The network_policy must be one of 'azure', 'calico', 'cilium', or empty string."
  }
}

variable "dns_service_ip" {
  description = "IP address within the Kubernetes service address range that will be used by cluster service discovery"
  type        = string
  default     = "10.0.0.10"
}

variable "service_cidr" {
  description = "The CIDR block for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "outbound_type" {
  description = "The outbound (egress) routing method for the AKS cluster"
  type        = string
  default     = "loadBalancer"
  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "managedNATGateway", "userAssignedNATGateway"], var.outbound_type)
    error_message = "The outbound_type must be one of 'loadBalancer', 'userDefinedRouting', 'managedNATGateway', or 'userAssignedNATGateway'."
  }
}

# API Server Access
variable "api_server_authorized_ip_ranges" {
  description = "List of IP ranges authorized to access the Kubernetes API server"
  type        = list(string)
  default     = null
}

variable "enable_private_cluster" {
  description = "Enable private cluster for the AKS cluster"
  type        = bool
  default     = false
}

# Maintenance Window
variable "maintenance_window_day" {
  description = "The day of the week for maintenance window"
  type        = string
  default     = "Sunday"
  validation {
    condition     = contains(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"], var.maintenance_window_day)
    error_message = "The maintenance_window_day must be a valid day of the week."
  }
}

variable "maintenance_window_hours" {
  description = "The hours of the day for maintenance window"
  type        = list(number)
  default     = [0, 1, 2]
}

# Log Analytics
variable "enable_log_analytics_workspace" {
  description = "Enable Log Analytics workspace for the AKS cluster"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_sku" {
  description = "The SKU of the Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_in_days" {
  description = "The retention period for logs in days"
  type        = number
  default     = 30
}

# Additional Node Pools
variable "additional_node_pools" {
  description = "Map of additional node pool configurations"
  type = map(object({
    vm_size         = string
    node_count      = optional(number)
    min_count       = optional(number)
    max_count       = optional(number)
    os_disk_size_gb = optional(number)
    os_disk_type    = optional(string)
    node_labels     = optional(map(string))
    mode            = optional(string, "User")
  }))
  default = {}
}