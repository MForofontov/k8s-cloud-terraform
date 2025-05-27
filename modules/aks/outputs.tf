#==============================================================================
# Azure Kubernetes Service (AKS) Module Outputs
#
# This file defines all output values provided by the AKS module. These outputs
# enable interaction with the provisioned cluster, integration with Azure
# services, and access to important resource identifiers.
#
# Outputs are organized by resource type and include identifiers, endpoints,
# credentials, and status information that can be used for monitoring,
# automation, and application deployment.
#==============================================================================

#==============================================================================
# Core Cluster Information
# Basic details about the provisioned AKS cluster
#==============================================================================
output "id" {
  description = "The ID of the AKS cluster. This unique identifier is used when referencing the cluster in Azure API calls, ARM templates, and when integrating with other Azure services that require the cluster ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "The name of the AKS cluster. This human-readable identifier is used in the Azure portal, Azure CLI commands, and for tagging related resources. It's also used when working with kubectl and other Kubernetes tools."
  value       = azurerm_kubernetes_cluster.this.name
}

output "resource_group_name" {
  description = "The resource group name where the AKS cluster is located. This is the management resource group that contains the AKS resource itself, not the node resources. Used for organizing resources and access control in Azure."
  value       = azurerm_kubernetes_cluster.this.resource_group_name
}

output "location" {
  description = "The Azure region where the AKS cluster is deployed. Important for understanding data residency, compliance requirements, and for planning zone redundancy. Also relevant when deploying supporting services in the same region."
  value       = azurerm_kubernetes_cluster.this.location
}

output "kubernetes_version" {
  description = "The Kubernetes version running on the AKS cluster. Critical for compatibility with kubectl versions, helm charts, and operators. Also useful for planning upgrades and ensuring application compatibility."
  value       = azurerm_kubernetes_cluster.this.kubernetes_version
}

output "node_resource_group" {
  description = "The auto-generated resource group which contains the infrastructure resources for this AKS cluster (VMs, disks, NICs, etc.). This is different from the management resource group and is managed by Azure. Important for network security and firewall configurations."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

#==============================================================================
# Authentication and Access
# Credentials and connection information for the Kubernetes API
#==============================================================================
output "kube_config_raw" {
  description = "Raw Kubernetes config in YAML format to be used with kubectl and other compatible tools. Contains all the information needed to connect to and authenticate with the cluster. Should be treated as sensitive and stored securely."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kube_admin_config_raw" {
  description = "Raw Kubernetes admin config with elevated permissions. This grants admin-level access to the cluster and should be used only when necessary. Available only when AAD integration is not enabled. Handle with extreme caution and restrict access."
  value       = azurerm_kubernetes_cluster.this.kube_admin_config_raw
  sensitive   = true
}

output "host" {
  description = "The Kubernetes cluster server host URL. This is the API server endpoint used by kubectl and other tools to communicate with the cluster. Required when manually configuring Kubernetes clients or CI/CD systems."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "client_certificate" {
  description = "Base64 encoded public certificate used by clients to authenticate to the Kubernetes cluster. Part of the certificate-based authentication method for AKS. Only used when AAD integration is not enabled. Should be rotated periodically for security."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Base64 encoded private key used by clients to authenticate to the Kubernetes cluster. The private component of certificate-based authentication. Must be protected carefully as it grants access to the cluster. Never store in version control."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded public CA certificate used as the root of trust for the Kubernetes cluster. Used by clients to verify the API server's identity and establish secure TLS connections. Required when configuring kubectl or other Kubernetes clients."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

#==============================================================================
# Node Pool Information
# Details about the Kubernetes worker nodes
#==============================================================================
output "default_node_pool" {
  description = "Detailed information about the default node pool including size, scaling configuration, and storage settings. This primary node pool runs essential system pods and must exist for the cluster to function. Use this information for capacity planning and monitoring."
  value = {
    name                = azurerm_kubernetes_cluster.this.default_node_pool[0].name
    vm_size             = azurerm_kubernetes_cluster.this.default_node_pool[0].vm_size
    node_count          = azurerm_kubernetes_cluster.this.default_node_pool[0].node_count
    auto_scaling_enabled = azurerm_kubernetes_cluster.this.default_node_pool[0].auto_scaling_enabled
    min_count           = azurerm_kubernetes_cluster.this.default_node_pool[0].min_count
    max_count           = azurerm_kubernetes_cluster.this.default_node_pool[0].max_count
    os_disk_size_gb     = azurerm_kubernetes_cluster.this.default_node_pool[0].os_disk_size_gb
    os_disk_type        = azurerm_kubernetes_cluster.this.default_node_pool[0].os_disk_type
    vnet_subnet_id      = azurerm_kubernetes_cluster.this.default_node_pool[0].vnet_subnet_id
    zones               = azurerm_kubernetes_cluster.this.default_node_pool[0].zones
  }
}

output "additional_node_pools" {
  description = "Map of all additional node pools created beyond the default. Organized by node pool name, containing detailed configuration for each specialized pool. Use this information to track capacity, understand node distribution, and manage workload placement across pools."
  value = {
    for name, pool in azurerm_kubernetes_cluster_node_pool.additional : name => {
      id                  = pool.id
      vm_size             = pool.vm_size
      node_count          = pool.node_count
      auto_scaling_enabled = pool.auto_scaling_enabled
      min_count           = pool.min_count
      max_count           = pool.max_count
      os_disk_size_gb     = pool.os_disk_size_gb
      os_disk_type        = pool.os_disk_type
      mode                = pool.mode
    }
  }
}

#==============================================================================
# Network Configuration
# Networking settings for pods, services, and external traffic
#==============================================================================
output "network_profile" {
  description = "Comprehensive network configuration for the AKS cluster, including plugin type, policies, and IP ranges. These settings determine how pods communicate, how services are exposed, and how the cluster connects to external networks. Critical for troubleshooting connectivity issues."
  value = {
    network_plugin    = azurerm_kubernetes_cluster.this.network_profile[0].network_plugin
    network_policy    = azurerm_kubernetes_cluster.this.network_profile[0].network_policy
    service_cidr      = azurerm_kubernetes_cluster.this.network_profile[0].service_cidr
    dns_service_ip    = azurerm_kubernetes_cluster.this.network_profile[0].dns_service_ip
    outbound_type     = azurerm_kubernetes_cluster.this.network_profile[0].outbound_type
    load_balancer_sku = azurerm_kubernetes_cluster.this.network_profile[0].load_balancer_sku
  }
}

#==============================================================================
# Identity Information
# Managed identity used by the AKS cluster for Azure resource access
#==============================================================================
output "identity" {
  description = "Managed identity details for the AKS cluster. This identity is used by the cluster to access other Azure resources like load balancers, storage, and ACR. Important for setting up role assignments and understanding the security context of the cluster."
  value = {
    type         = azurerm_kubernetes_cluster.this.identity[0].type
    principal_id = azurerm_kubernetes_cluster.this.identity[0].principal_id
    tenant_id    = azurerm_kubernetes_cluster.this.identity[0].tenant_id
  }
}

#==============================================================================
# Monitoring Configuration
# Log Analytics workspace details for cluster monitoring
#==============================================================================
output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace created for the AKS cluster. This workspace collects and stores container insights data, logs, and metrics. Required when setting up additional diagnostic settings or custom queries. Only available when monitoring is enabled."
  value       = var.enable_log_analytics_workspace ? azurerm_log_analytics_workspace.aks[0].id : null
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace created for the AKS cluster. Use this to locate the workspace in the Azure portal or when configuring monitoring solutions and alerts. Only available when monitoring is enabled."
  value       = var.enable_log_analytics_workspace ? azurerm_log_analytics_workspace.aks[0].name : null
}

#==============================================================================
# Endpoint Information
# URLs for accessing the Kubernetes API
#==============================================================================
output "fqdn" {
  description = "The public Fully Qualified Domain Name (FQDN) of the AKS cluster's API server. This is the public hostname used to access the Kubernetes API when public access is enabled. Important for configuring external systems to communicate with the cluster."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "private_fqdn" {
  description = "The private FQDN of the AKS cluster's API server. This hostname is only resolvable within the virtual network and is used when the cluster is configured as private. Critical for internal systems that need to access the Kubernetes API."
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

#==============================================================================
# Local Configuration
# Files generated for cluster access
#==============================================================================
output "kubeconfig_path" {
  description = "The filesystem path to the generated kubeconfig file. This file contains the cluster credentials and configuration needed by kubectl and other Kubernetes tools. Set the KUBECONFIG environment variable to this path for easy cluster access."
  value       = "${path.module}/kubeconfig_${var.cluster_name}"
}