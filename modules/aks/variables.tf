# Variables for AKS module

# Core cluster configuration
variable "cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "The Azure region where the AKS cluster will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Default node pool configuration
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

variable "default_node_pool_node_count" {
  description = "Initial number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for the default node pool"
  type        = bool
  default     = false
}

variable "min_node_count" {
  description = "Minimum number of nodes for auto-scaling"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes for auto-scaling"
  type        = number
  default     = 5
}

variable "vnet_subnet_id" {
  description = "The ID of the subnet where the default node pool should be deployed"
  type        = string
  default     = null
}

variable "availability_zones" {
  description = "List of availability zones to use for the default node pool"
  type        = list(string)
  default     = null
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB for default node pool VMs"
  type        = number
  default     = 128
}

variable "os_disk_type" {
  description = "OS disk type for default node pool VMs"
  type        = string
  default     = "Managed"
}

variable "max_pods" {
  description = "Maximum number of pods per node in the default node pool"
  type        = number
  default     = 30
}

variable "node_labels" {
  description = "Labels to apply to nodes in the default node pool"
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "Taints to apply to nodes in the default node pool"
  type        = list(string)
  default     = []
}

# Identity configuration
variable "identity_type" {
  description = "Type of identity to use for the AKS cluster (SystemAssigned, UserAssigned, SystemAssigned, UserAssigned)"
  type        = string
  default     = "SystemAssigned"
}

variable "user_assigned_identity_ids" {
  description = "List of user-assigned identity IDs to be assigned to the AKS cluster"
  type        = list(string)
  default     = []
}

# Network configuration
variable "network_plugin" {
  description = "Network plugin to use for the AKS cluster (azure or kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy to use for the AKS cluster (azure or calico)"
  type        = string
  default     = "azure"
}

variable "service_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for Kubernetes DNS service"
  type        = string
  default     = "10.0.0.10"
}

variable "docker_bridge_cidr" {
  description = "CIDR block for Docker bridge network"
  type        = string
  default     = "172.17.0.1/16"
}

variable "outbound_type" {
  description = "Outbound (egress) routing method for the AKS cluster (loadBalancer, userDefinedRouting, managedNATGateway, userAssignedNATGateway)"
  type        = string
  default     = "loadBalancer"
}

# Azure Active Directory RBAC configuration
variable "enable_azure_active_directory" {
  description = "Enable Azure Active Directory integration for AKS"
  type        = bool
  default     = false
}

variable "admin_group_object_ids" {
  description = "List of Azure AD group object IDs that will have admin access to the AKS cluster"
  type        = list(string)
  default     = []
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = false
}

# Add-ons configuration
variable "enable_microsoft_defender" {
  description = "Enable Microsoft Defender for AKS"
  type        = bool
  default     = false
}

variable "enable_log_analytics" {
  description = "Enable Log Analytics integration for AKS"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for AKS monitoring"
  type        = string
  default     = null
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace for container insights solution"
  type        = string
  default     = null
}

variable "create_log_analytics_solution" {
  description = "Create the Log Analytics solution for containers"
  type        = bool
  default     = false
}

variable "enable_key_vault_secrets_provider" {
  description = "Enable Key Vault Secrets Provider for AKS"
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

variable "enable_aci_connector_linux" {
  description = "Enable ACI Connector for Linux for AKS"
  type        = bool
  default     = false
}

variable "aci_connector_linux_subnet_name" {
  description = "Subnet name for ACI Connector for Linux"
  type        = string
  default     = null
}

variable "enable_app_gateway" {
  description = "Enable Application Gateway Ingress Controller for AKS"
  type        = bool
  default     = false
}

variable "app_gateway_id" {
  description = "ID of an existing Application Gateway to use with AGIC"
  type        = string
  default     = null
}

variable "app_gateway_name" {
  description = "Name of the Application Gateway to create for AGIC"
  type        = string
  default     = null
}

variable "app_gateway_subnet_id" {
  description = "ID of the subnet where Application Gateway will be deployed"
  type        = string
  default     = null
}

variable "app_gateway_subnet_cidr" {
  description = "CIDR range for the Application Gateway subnet"
  type        = string
  default     = null
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy for AKS"
  type        = bool
  default     = false
}

variable "enable_http_application_routing" {
  description = "Enable HTTP application routing for AKS"
  type        = bool
  default     = false
}

# Auto-scaler profile configuration
variable "balance_similar_node_groups" {
  description = "Balance similar node groups for the cluster autoscaler"
  type        = bool
  default     = false
}

variable "max_graceful_termination_sec" {
  description = "Maximum number of seconds the cluster autoscaler waits for pod termination when trying to scale down a node"
  type        = string
  default     = "600"
}

variable "scale_down_delay_after_add" {
  description = "How long after the scale up of AKS nodes the scale down evaluation resumes"
  type        = string
  default     = "10m"
}

variable "scale_down_delay_after_delete" {
  description = "How long after node deletion that scale down evaluation resumes"
  type        = string
  default     = "10s"
}

variable "scale_down_delay_after_failure" {
  description = "How long after scale down failure that scale down evaluation resumes"
  type        = string
  default     = "3m"
}

variable "scan_interval" {
  description = "How often the cluster autoscaler checks for scale up/down opportunities"
  type        = string
  default     = "10s"
}

variable "scale_down_unneeded" {
  description = "How long a node should be unneeded before it is eligible for scale down"
  type        = string
  default     = "10m"
}

variable "scale_down_unready" {
  description = "How long an unready node should be unneeded before it is eligible for scale down"
  type        = string
  default     = "20m"
}

variable "scale_down_utilization_threshold" {
  description = "Node utilization level, defined as sum of requested resources divided by capacity, below which a node can be considered for scale down"
  type        = string
  default     = "0.5"
}

# Additional node pools configuration
variable "additional_node_pools" {
  description = "Map of additional node pools to create"
  type = map(object({
    vm_size             = string
    node_count          = number
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    vnet_subnet_id      = string
    zones               = list(string)
    os_disk_size_gb     = number
    os_disk_type        = string
    max_pods            = number
    node_labels         = map(string)
    node_taints         = list(string)
    mode                = string
    priority            = string
    eviction_policy     = string
    spot_max_price      = number
    os_type             = string
    tags                = map(string)
  }))
  default = {}
}

# Role assignment configuration
variable "assign_network_contributor_role" {
  description = "Assign Network Contributor role to the AKS managed identity"
  type        = bool
  default     = false
}

variable "vnet_id" {
  description = "ID of the VNet for Network Contributor role assignment"
  type        = string
  default     = null
}