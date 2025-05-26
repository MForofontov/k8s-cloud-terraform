# Output variables for the AKS module

# Cluster information
output "id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "resource_group_name" {
  description = "The resource group name where the AKS cluster is located"
  value       = azurerm_kubernetes_cluster.this.resource_group_name
}

output "location" {
  description = "The location where the AKS cluster is deployed"
  value       = azurerm_kubernetes_cluster.this.location
}

output "kubernetes_version" {
  description = "The Kubernetes version of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.kubernetes_version
}

output "node_resource_group" {
  description = "The auto-generated resource group which contains the resources for this AKS cluster"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

# Access information
output "kube_config_raw" {
  description = "Raw Kubernetes config to be used with kubectl and other compatible tools"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kube_admin_config_raw" {
  description = "Raw Kubernetes admin config to be used with kubectl and other compatible tools"
  value       = azurerm_kubernetes_cluster.this.kube_admin_config_raw
  sensitive   = true
}

output "host" {
  description = "The Kubernetes cluster server host"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "client_certificate" {
  description = "Base64 encoded public certificate used by clients to authenticate to the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Base64 encoded private key used by clients to authenticate to the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded public CA certificate used as the root of trust for the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

# Node pool information
output "default_node_pool" {
  description = "Information about the default node pool"
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
  description = "Map of additional node pools created"
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

# Network information
output "network_profile" {
  description = "Network configuration for the AKS cluster"
  value = {
    network_plugin    = azurerm_kubernetes_cluster.this.network_profile[0].network_plugin
    network_policy    = azurerm_kubernetes_cluster.this.network_profile[0].network_policy
    service_cidr      = azurerm_kubernetes_cluster.this.network_profile[0].service_cidr
    dns_service_ip    = azurerm_kubernetes_cluster.this.network_profile[0].dns_service_ip
    outbound_type     = azurerm_kubernetes_cluster.this.network_profile[0].outbound_type
    load_balancer_sku = azurerm_kubernetes_cluster.this.network_profile[0].load_balancer_sku
  }
}

# Identity information
output "identity" {
  description = "Identity used for the AKS cluster"
  value = {
    type         = azurerm_kubernetes_cluster.this.identity[0].type
    principal_id = azurerm_kubernetes_cluster.this.identity[0].principal_id
    tenant_id    = azurerm_kubernetes_cluster.this.identity[0].tenant_id
  }
}

# Log Analytics information
output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace created for the AKS cluster"
  value       = var.enable_log_analytics_workspace ? azurerm_log_analytics_workspace.aks[0].id : null
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace created for the AKS cluster"
  value       = var.enable_log_analytics_workspace ? azurerm_log_analytics_workspace.aks[0].name : null
}

# Cluster endpoints
output "fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "private_fqdn" {
  description = "The private FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

# Kubeconfig path
output "kubeconfig_path" {
  description = "Path to the generated kubeconfig file"
  value       = "${path.module}/kubeconfig_${var.cluster_name}"
}