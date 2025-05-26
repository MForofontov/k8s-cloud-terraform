// GKE Cluster Outputs

# Cluster outputs
output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.this.id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.this.name
}

output "cluster_location" {
  description = "The location of the GKE cluster"
  value       = google_container_cluster.this.location
}

output "cluster_type" {
  description = "The type of the GKE cluster (regional or zonal)"
  value       = var.regional_cluster ? "regional" : "zonal"
}

output "cluster_endpoint" {
  description = "The IP address of the Kubernetes master endpoint"
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate (base64 encoded)"
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_master_version" {
  description = "The Kubernetes master version"
  value       = google_container_cluster.this.master_version
}

output "cluster_network" {
  description = "The VPC network used by the cluster"
  value       = google_container_cluster.this.network
}

output "cluster_subnetwork" {
  description = "The subnetwork used by the cluster"
  value       = google_container_cluster.this.subnetwork
}

output "cluster_self_link" {
  description = "The server-defined URL for the GKE cluster"
  value       = google_container_cluster.this.self_link
}

output "cluster_services_ipv4_cidr" {
  description = "The IP address range of the Kubernetes services in this cluster"
  value       = google_container_cluster.this.services_ipv4_cidr
}

output "cluster_pod_ipv4_cidr" {
  description = "The IP address range of the pods in this cluster"
  value       = google_container_cluster.this.cluster_ipv4_cidr
}

# Node pools outputs
output "default_node_pool" {
  description = "Details of the default node pool if created"
  value       = var.create_default_node_pool ? {
    name            = try(google_container_node_pool.default[0].name, null)
    node_count      = try(google_container_node_pool.default[0].initial_node_count, null)
    machine_type    = try(google_container_node_pool.default[0].node_config[0].machine_type, null)
    disk_size_gb    = try(google_container_node_pool.default[0].node_config[0].disk_size_gb, null)
    disk_type       = try(google_container_node_pool.default[0].node_config[0].disk_type, null)
    auto_scaling    = try(google_container_node_pool.default[0].autoscaling[0], null)
    service_account = try(google_container_node_pool.default[0].node_config[0].service_account, null)
    labels          = try(google_container_node_pool.default[0].node_config[0].labels, null)
    taints          = try(google_container_node_pool.default[0].node_config[0].taint, null)
  } : null
}

output "additional_node_pools" {
  description = "Details of the additional node pools"
  value       = {
    for name, pool in google_container_node_pool.additional : name => {
      name            = pool.name
      node_count      = pool.initial_node_count
      machine_type    = try(pool.node_config[0].machine_type, null)
      disk_size_gb    = try(pool.node_config[0].disk_size_gb, null)
      disk_type       = try(pool.node_config[0].disk_type, null)
      auto_scaling    = try(pool.autoscaling[0], null)
      service_account = try(pool.node_config[0].service_account, null)
      labels          = try(pool.node_config[0].labels, null)
      taints          = try(pool.node_config[0].taint, null)
    }
  }
}

# Authentication outputs
output "client_token" {
  description = "The bearer token for auth"
  value       = data.google_client_config.current.access_token
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Path to the generated kubeconfig file"
  value       = local_file.kubeconfig.filename
}

output "kubeconfig_raw" {
  description = "Raw kubeconfig content"
  value       = local_file.kubeconfig.content
  sensitive   = true
}

# Features and add-ons outputs
output "release_channel" {
  description = "The release channel of the GKE cluster"
  value       = try(google_container_cluster.this.release_channel[0].channel, null)
}

output "workload_identity_enabled" {
  description = "Whether Workload Identity is enabled for the cluster"
  value       = var.enable_workload_identity
}

output "workload_identity_pool" {
  description = "The Workload Identity Pool associated with the cluster"
  value       = var.enable_workload_identity ? "${var.project_id}.svc.id.goog" : null
}

output "network_policy_enabled" {
  description = "Whether Network Policy is enabled for the cluster"
  value       = var.enable_network_policy
}

output "horizontal_pod_autoscaling_enabled" {
  description = "Whether Horizontal Pod Autoscaling is enabled for the cluster"
  value       = var.enable_horizontal_pod_autoscaling
}

output "vertical_pod_autoscaling_enabled" {
  description = "Whether Vertical Pod Autoscaling is enabled for the cluster"
  value       = var.enable_vertical_pod_autoscaling
}

# Private cluster outputs
output "private_cluster_enabled" {
  description = "Whether the cluster has private nodes"
  value       = var.enable_private_nodes
}

output "private_endpoint_enabled" {
  description = "Whether the cluster's master API endpoint is private"
  value       = var.enable_private_endpoint
}

output "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation used for the master network"
  value       = var.enable_private_nodes ? var.master_ipv4_cidr_block : null
}

# Monitoring outputs
output "monitoring_enabled_components" {
  description = "GKE components being monitored"
  value       = var.monitoring_enabled_components
}

output "logging_enabled_components" {
  description = "GKE components being logged"
  value       = var.logging_enabled_components
}

output "managed_prometheus_enabled" {
  description = "Whether managed Prometheus is enabled"
  value       = var.enable_managed_prometheus
}

# Node identity and security outputs
output "service_account" {
  description = "The Google Cloud Platform Service Account used by the node VMs"
  value       = var.service_account
}

output "node_oauth_scopes" {
  description = "The set of Google API scopes for node VMs"
  value       = var.node_oauth_scopes
}

output "secure_boot_enabled" {
  description = "Whether secure boot is enabled for nodes"
  value       = var.enable_secure_boot
}

output "integrity_monitoring_enabled" {
  description = "Whether integrity monitoring is enabled for nodes"
  value       = var.enable_integrity_monitoring
}