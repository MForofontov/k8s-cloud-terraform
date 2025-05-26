// AKS Cluster Outputs

output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_resource_group_name" {
  description = "The resource group where the AKS cluster is deployed"
  value       = azurerm_kubernetes_cluster.this.resource_group_name
}

output "cluster_version" {
  description = "The Kubernetes version of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.kubernetes_version
}

output "kube_config_raw" {
  description = "Raw Kubernetes config to be used by kubectl and other compatible tools"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kube_config_path" {
  description = "Path to the generated kubeconfig file"
  value       = local_file.kubeconfig.filename
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

output "node_resource_group" {
  description = "The auto-generated resource group which contains the resources for this managed Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "principal_id" {
  description = "The principal ID of the system assigned identity of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "kubelet_identity" {
  description = "The kubelet identity of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity
}

output "network_profile" {
  description = "Network profile of the AKS cluster"
  value = {
    network_plugin     = azurerm_kubernetes_cluster.this.network_profile[0].network_plugin
    network_policy     = azurerm_kubernetes_cluster.this.network_profile[0].network_policy
    service_cidr       = azurerm_kubernetes_cluster.this.network_profile[0].service_cidr
    dns_service_ip     = azurerm_kubernetes_cluster.this.network_profile[0].dns_service_ip
    docker_bridge_cidr = azurerm_kubernetes_cluster.this.network_profile[0].docker_bridge_cidr
    outbound_type      = azurerm_kubernetes_cluster.this.network_profile[0].outbound_type
    pod_cidr           = azurerm_kubernetes_cluster.this.network_profile[0].pod_cidr
  }
}

output "additional_node_pools" {
  description = "Map of additional node pools and their properties"
  value       = { for k, v in azurerm_kubernetes_cluster_node_pool.additional : k => {
    id                  = v.id
    name                = v.name
    vm_size             = v.vm_size
    os_disk_size_gb     = v.os_disk_size_gb
    os_disk_type        = v.os_disk_type
    os_type             = v.os_type
    enable_auto_scaling = v.enable_auto_scaling
    node_count          = v.node_count
    min_count           = v.min_count
    max_count           = v.max_count
    node_labels         = v.node_labels
    node_taints         = v.node_taints
    zones               = v.zones
    mode                = v.mode
  }}
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  value       = var.enable_log_analytics_workspace ? azurerm_log_analytics_workspace.aks[0].id : null
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace"
  value       = var.enable_log_analytics_workspace ? azurerm_log_analytics_workspace.aks[0].name : null
}