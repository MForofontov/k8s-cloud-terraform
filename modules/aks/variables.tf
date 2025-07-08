#==============================================================================
# Azure Kubernetes Service (AKS) Module Variables
#
# This file defines all configuration options for Azure Kubernetes Service
# clusters. Variables are organized into logical sections and include detailed
# descriptions, defaults, and usage guidance.
#
# The module supports various AKS features including multiple node pools,
# networking options, Azure AD integration, and monitoring capabilities.
#==============================================================================

#==============================================================================
# Resource Group Configuration
# Controls which Azure resource group contains the AKS resources
#==============================================================================
variable "resource_group_name" {
  description = "The name of the resource group in which to create the AKS cluster. This resource group must exist prior to deployment and will contain the AKS resource but not necessarily the node resources."
  type        = string
}

variable "node_resource_group_name" {
  description = "The name of the resource group in which to create the AKS cluster's node resources. If not specified, Azure will generate a name using the AKS cluster name. This resource group will contain all infrastructure resources like VMs, NICs, and disks."
  type        = string
  default     = null
}

#==============================================================================
# Cluster Configuration
# Basic settings for the AKS cluster
#==============================================================================
variable "cluster_name" {
  description = "The name of the AKS cluster. This identifier will be used in logs, monitoring, and for accessing the cluster. Must be unique within the resource group and comply with Azure naming restrictions."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix specified when creating the managed cluster. Forms part of the fully qualified domain name used for the Kubernetes API server (e.g., {dns_prefix}.{region}.azmk8s.io). If not specified, the cluster name will be used."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the AKS cluster (e.g., '1.26.3'). If not specified, the latest recommended version will be used. Consider your application compatibility requirements when selecting a version."
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "The SKU tier for the AKS cluster. 'Free' provides no SLA guarantees and is suitable for development environments. 'Paid' (Standard) offers 99.95% SLA and is recommended for production workloads, but incurs additional cost."
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Paid"], var.sku_tier)
    error_message = "The sku_tier must be either 'Free' or 'Paid'."
  }
}

#==============================================================================
# Default Node Pool Configuration
# Settings for the primary node pool that runs essential system pods
#==============================================================================
variable "default_node_pool_name" {
  description = "The name of the default node pool. This pool runs critical system pods and must exist for the cluster to function. Name must start with a lowercase letter, contain only alphanumeric characters, and be between 1-12 characters."
  type        = string
  default     = "default"
}

variable "default_node_pool_vm_size" {
  description = "The size of the VMs in the default node pool (e.g., 'Standard_D2s_v3'). Determines CPU, memory, and cost. For production, consider at least 2 vCPUs and 4GB RAM. Check Azure VM sizes for available options in your region."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "subnet_id" {
  description = "The ID of the subnet where the default node pool should be deployed. This subnet must have sufficient IP addresses available for all nodes and pods. Required for advanced networking and must be within the VNet configured for AKS."
  type        = string
}

variable "availability_zones" {
  description = "A list of availability zones to use for the default node pool (e.g., ['1', '2', '3']). Distributes nodes across zones for high availability. Not all VM sizes support availability zones in all regions. Null means no zone configuration."
  type        = list(string)
  default     = null
}

variable "default_node_pool_node_count" {
  description = "The initial number of nodes in the default node pool. For production clusters, a minimum of 3 nodes is recommended to ensure high availability. When auto-scaling is enabled, this acts as the initial size."
  type        = number
  default     = 1
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for the default node pool. When true, AKS will automatically adjust the number of nodes based on CPU and memory demand. Recommended for production workloads with variable resource requirements."
  type        = bool
  default     = false
}

variable "default_node_pool_min_count" {
  description = "The minimum number of nodes in the default node pool when auto-scaling is enabled. Should be sized to handle minimum expected load plus capacity for node failures. Only used when enable_auto_scaling is true."
  type        = number
  default     = 1
}

variable "default_node_pool_max_count" {
  description = "The maximum number of nodes in the default node pool when auto-scaling is enabled. Sets the upper bound for cluster scaling. Consider your quota limits and cost constraints. Only used when enable_auto_scaling is true."
  type        = number
  default     = 3
}

variable "os_disk_size_gb" {
  description = "The size of the OS disk in GB for each node in the default node pool. Base images require about 30GB. For production, 128GB+ is recommended to accommodate container images, logs, and emptyDir volumes."
  type        = number
  default     = 128
}

variable "os_disk_type" {
  description = "The type of OS disk for each node in the default node pool. 'Managed' (Standard SSD) provides balanced performance. 'Ephemeral' uses local VM storage for better performance but with data persistence limitations."
  type        = string
  default     = "Managed"
}

variable "default_node_pool_labels" {
  description = "A map of Kubernetes labels to apply to nodes in the default node pool. These labels can be used for node selection in pod deployments using nodeSelector or node affinity. Example: { 'environment': 'prod', 'workload-type': 'system' }"
  type        = map(string)
  default     = {}
}

#==============================================================================
# Additional Node Pools
# Configuration for specialized node pools beyond the default
#==============================================================================
variable "additional_node_pools" {
  description = "Map of additional node pool configurations to create. Use this to create specialized pools for different workloads (e.g., compute-intensive, memory-intensive, GPU). Each pool can have unique VM sizes, scaling parameters, and node configurations."
  type = map(object({
    vm_size         = string       # VM size (e.g., 'Standard_D4s_v3', 'Standard_NC6s_v3' for GPU)
    node_count      = optional(number) # Initial/fixed number of nodes if not autoscaling
    min_count       = optional(number) # Minimum nodes for autoscaling
    max_count       = optional(number) # Maximum nodes for autoscaling
    os_disk_size_gb = optional(number) # OS disk size in GB
    os_disk_type    = optional(string) # 'Managed' or 'Ephemeral'
    node_labels     = optional(map(string)) # Kubernetes labels for node selection
    mode            = optional(string, "User") # 'User' or 'System' (for critical system pods)
  }))
  default = {}
}

#==============================================================================
# Azure AD Integration
# Authentication and authorization configuration
#==============================================================================
variable "admin_group_object_ids" {
  description = "A list of Azure AD group object IDs that will have admin role on the cluster. Members of these groups will have full access to the Kubernetes API with cluster-admin role. Recommended for implementing proper RBAC with Azure AD integration."
  type        = list(string)
  default     = []
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization. When true, Kubernetes RBAC will be integrated with Azure RBAC, allowing you to manage access using Azure role assignments. This provides a unified access control experience across Azure resources."
  type        = bool
  default     = false
}

variable "tenant_id" {
  description = "The tenant ID used for Azure Active Directory application integration. If not specified, the tenant ID of the current subscription will be used. Required when cluster is in a different tenant than the deploying identity."
  type        = string
  default     = null
}

#==============================================================================
# Networking Configuration
# Controls how pods, services, and external traffic are handled
#==============================================================================
variable "network_plugin" {
  description = "The network plugin to use for the AKS cluster. 'azure' (CNI) provides better performance and direct VNet integration but uses more IPs. 'kubenet' is more IP-efficient but has limitations with network policies and services."
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "The network_plugin must be either 'azure' or 'kubenet'."
  }
}

variable "network_policy" {
  description = "The network policy to use for the AKS cluster. 'azure' uses Azure's native implementation, 'calico' offers more advanced features, 'cilium' provides eBPF-based networking. Empty string disables network policy enforcement."
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "calico", "cilium", ""], var.network_policy)
    error_message = "The network_policy must be one of 'azure', 'calico', 'cilium', or empty string."
  }
}

variable "dns_service_ip" {
  description = "IP address within the Kubernetes service address range that will be used by cluster service discovery (kube-dns). Must be within the service_cidr range and not the first IP in the range. Typically .10 in the service CIDR."
  type        = string
  default     = "10.0.0.10"
}

variable "service_cidr" {
  description = "The CIDR block for Kubernetes services. Must not overlap with any subnet in the VNet. This address space is used internally by Kubernetes services and isn't routable outside the cluster."
  type        = string
  default     = "10.0.0.0/16"
}

variable "outbound_type" {
  description = "The outbound (egress) routing method for the AKS cluster. 'loadBalancer' uses a public Standard SKU LB, 'userDefinedRouting' for custom routing, 'managedNATGateway' or 'userAssignedNATGateway' for NAT Gateway egress."
  type        = string
  default     = "loadBalancer"
  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "managedNATGateway", "userAssignedNATGateway"], var.outbound_type)
    error_message = "The outbound_type must be one of 'loadBalancer', 'userDefinedRouting', 'managedNATGateway', or 'userAssignedNATGateway'."
  }
}

#==============================================================================
# API Server Access
# Controls access to the Kubernetes API server
#==============================================================================
variable "api_server_authorized_ip_ranges" {
  description = "List of IP ranges authorized to access the Kubernetes API server in CIDR notation. When specified, the API server will only be accessible from these ranges, enhancing security by limiting API access to trusted networks."
  type        = list(string)
  default     = null
}

variable "enable_private_cluster" {
  description = "Enable private cluster for the AKS cluster. When true, the Kubernetes API server will only have private IP addresses and won't be accessible from the public internet. Requires proper network planning and private DNS configuration."
  type        = bool
  default     = false
}

#==============================================================================
# Maintenance Window
# Controls when automatic maintenance can occur
#==============================================================================
variable "maintenance_window_day" {
  description = "The day of the week for maintenance window. This controls when Azure can perform planned maintenance operations that might cause disruption. Plan for non-critical business hours or weekends for production clusters."
  type        = string
  default     = "Sunday"
  validation {
    condition     = contains(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"], var.maintenance_window_day)
    error_message = "The maintenance_window_day must be a valid day of the week."
  }
}

variable "maintenance_window_hours" {
  description = "The hours of the day for maintenance window (0-23). These are the specific hours during the maintenance day when operations can occur. For minimal disruption, choose off-peak hours for your business or application usage patterns."
  type        = list(number)
  default     = [0, 1, 2]
}

#==============================================================================
# Monitoring and Logging
# Observability configuration for the AKS cluster
#==============================================================================
variable "enable_log_analytics_workspace" {
  description = "Enable Log Analytics workspace for the AKS cluster. When true, the module will create a workspace for storing container insights data, providing enhanced monitoring, logging, and diagnostics capabilities."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_sku" {
  description = "The SKU of the Log Analytics workspace. 'PerGB2018' is recommended and charges based on data ingestion. Other options include legacy SKUs like 'Free', 'PerNode', 'Standard', 'Premium', but these are not recommended for new deployments."
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_in_days" {
  description = "The retention period for logs in days. Controls how long Log Analytics will keep data, affecting both compliance requirements and costs. Higher values increase logging costs but provide longer history for troubleshooting and analysis."
  type        = number
  default     = 30
}

#==============================================================================
# Resource Tagging
# Azure tags applied to all resources created by this module
#==============================================================================
variable "tags" {
  description = "A map of tags to assign to the resources created by this module. These tags help with resource organization, cost allocation, and access control. Common tags include: Environment, Owner, Project, and CostCenter."
  type        = map(string)
  default     = {}
}
