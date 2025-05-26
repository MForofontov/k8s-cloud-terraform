# Outputs for AKS module

# Cluster information
output "id" {
  description = "The Kubernetes Managed Cluster ID"
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "The Kubernetes Managed Cluster name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "resource_group_name" {
  description = "The resource group name where the AKS cluster was created"
  value       = azurerm_kubernetes_cluster.this.resource_group_name
}

output "location" {
  description = "The location where the AKS cluster was created"
  value       = azurerm_kubernetes_cluster.this.location
}

output "kubernetes_version" {
  description = "The Kubernetes version used by the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.kubernetes_version
}

output "dns_prefix" {
  description = "The DNS prefix of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.dns_prefix
}

# Access configuration
output "kube_config" {
  description = "The full kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config
  sensitive   = true
}

output "kube_config_raw" {
  description = "The raw kubeconfig in YAML format"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "host" {
  description = "The Kubernetes cluster server host"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "client_certificate" {
  description = "The client certificate for authentication"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "The client key for authentication"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate"
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
    enable_auto_scaling = azurerm_kubernetes_cluster.this.default_node_pool[0].enable_auto_scaling
    min_count           = azurerm_kubernetes_cluster.this.default_node_pool[0].min_count
    max_count           = azurerm_kubernetes_cluster.this.default_node_pool[0].max_count
    os_disk_size_gb     = azurerm_kubernetes_cluster.this.default_node_pool[0].os_disk_size_gb
    vnet_subnet_id      = azurerm_kubernetes_cluster.this.default_node_pool[0].vnet_subnet_id
    zones               = azurerm_kubernetes_cluster.this.default_node_pool[0].zones
    max_pods            = azurerm_kubernetes_cluster.this.default_node_pool[0].max_pods
  }
}

output "additional_node_pools" {
  description = "Map of additional node pools created"
  value = {
    for name, pool in azurerm_kubernetes_cluster_node_pool.additional_pools : name => {
      id                  = pool.id
      vm_size             = pool.vm_size
      node_count          = pool.node_count
      enable_auto_scaling = pool.enable_auto_scaling
      min_count           = pool.min_count
      max_count           = pool.max_count
      os_disk_size_gb     = pool.os_disk_size_gb
      os_disk_type        = pool.os_disk_type
      mode                = pool.mode
      priority            = pool.priority
    }
  }
}

# Network information
output "network_profile" {
  description = "Network configuration for the AKS cluster"
  value = {
    network_plugin     = azurerm_kubernetes_cluster.this.network_profile[0].network_plugin
    network_policy     = azurerm_kubernetes_cluster.this.network_profile[0].network_policy
    service_cidr       = azurerm_kubernetes_cluster.this.network_profile[0].service_cidr
    dns_service_ip     = azurerm_kubernetes_cluster.this.network_profile[0].dns_service_ip
    docker_bridge_cidr = azurerm_kubernetes_cluster.this.network_profile[0].docker_bridge_cidr
    outbound_type      = azurerm_kubernetes_cluster.this.network_profile[0].outbound_type
    load_balancer_sku  = azurerm_kubernetes_cluster.this.network_profile[0].load_balancer_sku
  }
}

# Identity information
output "identity" {
  description = "Identity configuration for the AKS cluster"
  value = {
    type         = azurerm_kubernetes_cluster.this.identity[0].type
    principal_id = azurerm_kubernetes_cluster.this.identity[0].principal_id
    tenant_id    = azurerm_kubernetes_cluster.this.identity[0].tenant_id
  }
}

# Add-on statuses
output "addon_profiles" {
  description = "Status of AKS add-ons"
  value = {
    http_application_routing_enabled = azurerm_kubernetes_cluster.this.http_application_routing_enabled
    azure_policy_enabled             = azurerm_kubernetes_cluster.this.azure_policy_enabled
    oms_agent_enabled                = var.enable_log_analytics
    key_vault_secrets_provider       = var.enable_key_vault_secrets_provider
    microsoft_defender_enabled       = var.enable_microsoft_defender
  }
}

# Cluster FQDN
output "fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

# Cluster private FQDN
output "private_fqdn" {
  description = "The private FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

# Cluster portal URL
output "portal_fqdn" {
  description = "The portal FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.portal_fqdn
}

# Auto-scaler profile
output "auto_scaler_profile" {
  description = "Auto-scaler profile configuration for the AKS cluster"
  value = {
    balance_similar_node_groups      = azurerm_kubernetes_cluster.this.auto_scaler_profile[0].balance_similar_node_groups
    max_graceful_termination_sec     = azurerm_kubernetes_cluster.this.auto_scaler_profile[0].max_graceful_termination_sec
    scale_down_delay_after_add       = azurerm_kubernetes_cluster.this.auto_scaler_profile[0].scale_down_delay_after_add
    scale_down_delay_after_delete    = azurerm_kubernetes_cluster.this.auto_scaler_profile[0].scale_down_delay_after_delete
    scale_down_delay_after_failure   = azurerm_kubernetes_cluster.this.auto_scaler_profile[0].scale_down_delay_after_failure
    scan_interval                    = azurerm_kubernetes_cluster.this.auto_scaler_profile[0].scan_interval
    scale_down_unneeded              = azurerm_kubernetes_cluster.this.auto_scaler_profile[0].scale_down_unneeded
    scale_down_unready               = azurerm_kubernetes_cluster.this.auto_scaler_profile[0].scale_down_unready
    scale_down_utilization_threshold = azurerm_kubernetes_cluster.this.auto_scaler_profile[0].scale_down_utilization_threshold
  }
}