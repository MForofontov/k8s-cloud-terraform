#==============================================================================
# Google Kubernetes Engine (GKE) Cluster Outputs
#
# This file defines all output values exposed by the GKE module. These outputs
# can be used to interact with the cluster, configure authentication, integrate
# with other modules, or monitor the state of cluster components.
#==============================================================================

#==============================================================================
# Core Cluster Information
# Basic details about the provisioned GKE cluster
#==============================================================================
output "cluster_id" {
  description = "The fully-qualified ID of the GKE cluster in the format 'projects/{project_id}/locations/{location}/clusters/{cluster_name}'. Use this when referencing the cluster in GCP APIs or cross-project operations."
  value       = google_container_cluster.this.id
}

output "cluster_name" {
  description = "The name of the GKE cluster as specified during creation. Use this identifier for logs, monitoring dashboards, and when creating additional resources for the cluster."
  value       = google_container_cluster.this.name
}

output "cluster_location" {
  description = "The location (region or zone) where the GKE cluster is deployed. For regional clusters, this is the region (e.g., 'us-central1'); for zonal clusters, this is the zone (e.g., 'us-central1-a')."
  value       = google_container_cluster.this.location
}

output "cluster_type" {
  description = "The type of the GKE cluster: 'regional' (control plane replicated across multiple zones for high availability) or 'zonal' (single-zone control plane). Regional clusters provide higher availability but at increased cost."
  value       = var.regional_cluster ? "regional" : "zonal"
}

output "cluster_endpoint" {
  description = "The IP address of the Kubernetes API server endpoint. This is the primary connection point for kubectl and other Kubernetes API clients. In private clusters, this may only be accessible through authorized networks."
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The cluster's CA certificate in base64-encoded format. This certificate is required for kubectl and other tools to establish secure connections to the Kubernetes API server. Store and transmit securely."
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_master_version" {
  description = "The Kubernetes version running on the master nodes. Important for compatibility with kubectl versions and when planning upgrades. Format: 'X.Y.Z-gke.N' (e.g., '1.24.5-gke.1700')."
  value       = google_container_cluster.this.master_version
}

output "cluster_network" {
  description = "The VPC network used by the cluster. This identifies the private network containing the cluster and can be used when configuring network policies or integrating with other services."
  value       = google_container_cluster.this.network
}

output "cluster_subnetwork" {
  description = "The VPC subnetwork used by the cluster. This identifies the specific subnet where the nodes are provisioned and can be used when planning IP address allocation or network security rules."
  value       = google_container_cluster.this.subnetwork
}

output "cluster_self_link" {
  description = "The server-defined URL for the GKE cluster. This is the canonical reference to the cluster in GCP and can be used with gcloud commands or API calls requiring the cluster reference."
  value       = google_container_cluster.this.self_link
}

output "cluster_services_ipv4_cidr" {
  description = "The IP address range used for Kubernetes Services (in CIDR notation). This is the range from which ClusterIP service addresses are allocated. Useful for network planning and troubleshooting service connectivity."
  value       = google_container_cluster.this.services_ipv4_cidr
}

output "cluster_pod_ipv4_cidr" {
  description = "The IP address range used for Pods (in CIDR notation). This is the range from which Pod IP addresses are allocated. Important for network planning, especially when integrating with existing networks or other GKE clusters."
  value       = google_container_cluster.this.cluster_ipv4_cidr
}

#==============================================================================
# Node Pool Details
# Information about the Kubernetes worker nodes
#==============================================================================
output "default_node_pool" {
  description = "Detailed information about the default node pool if it was created. Includes node count, machine type, disk configuration, scaling parameters, and node metadata. Use this to verify node pool configuration or for scaling decisions."
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
  description = "Detailed information about all additional node pools created beyond the default pool. Organized as a map where keys are node pool names and values contain configuration details. Useful for managing multiple specialized node pools."
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

#==============================================================================
# Authentication Information
# Credentials for accessing the Kubernetes API
#==============================================================================
output "client_token" {
  description = "The OAuth access token for GCP. This short-lived token can be used for authenticating with the Kubernetes API server when using tools that support GCP authentication. Rotate regularly and handle securely."
  value       = data.google_client_config.current.access_token
  sensitive   = true
}

output "kubeconfig_path" {
  description = "The filesystem path to the generated kubeconfig file. This file contains the cluster credentials and configuration needed by kubectl and other Kubernetes tools. The path can be used with KUBECONFIG environment variable."
  value       = local_file.kubeconfig.filename
}

output "kubeconfig_raw" {
  description = "The raw content of the generated kubeconfig file in YAML format. Contains sensitive credentials for cluster access including certificates and tokens. Can be used to programmatically generate kubeconfig files."
  value       = local_file.kubeconfig.content
  sensitive   = true
}

#==============================================================================
# Features and Add-ons
# Status of enabled GKE features and components
#==============================================================================
output "release_channel" {
  description = "The release channel of the GKE cluster ('RAPID', 'REGULAR', 'STABLE', or 'UNSPECIFIED'). Determines how quickly the cluster receives Kubernetes version updates and feature releases. Important for planning maintenance windows."
  value       = try(google_container_cluster.this.release_channel[0].channel, null)
}

output "workload_identity_enabled" {
  description = "Whether Workload Identity is enabled for the cluster. When true, Kubernetes service accounts can act as Google IAM service accounts, enabling secure access to Google Cloud services without key files."
  value       = var.enable_workload_identity
}

output "workload_identity_pool" {
  description = "The Workload Identity Pool associated with the cluster in the format '{project_id}.svc.id.goog'. This is the resource that maps Kubernetes service accounts to Google IAM service accounts. Required when configuring Workload Identity IAM bindings."
  value       = var.enable_workload_identity ? "${var.project_id}.svc.id.goog" : null
}

output "network_policy_enabled" {
  description = "Whether Kubernetes NetworkPolicy enforcement is enabled in the cluster. When true, Pods can be isolated through network policies that restrict traffic between namespaces and applications based on labels."
  value       = var.enable_network_policy
}

output "horizontal_pod_autoscaling_enabled" {
  description = "Whether Horizontal Pod Autoscaling is enabled for the cluster. When true, the HPA controller can automatically scale Deployment replicas based on CPU utilization or custom metrics. Enables efficient resource utilization."
  value       = var.enable_horizontal_pod_autoscaling
}

output "vertical_pod_autoscaling_enabled" {
  description = "Whether Vertical Pod Autoscaling is enabled for the cluster. When true, the VPA controller can automatically adjust CPU and memory requests/limits for containers based on their usage patterns. Reduces the need for manual resource tuning."
  value       = var.enable_vertical_pod_autoscaling
}

#==============================================================================
# Private Cluster Configuration
# Settings related to private GKE clusters
#==============================================================================
output "private_cluster_enabled" {
  description = "Whether the cluster has private nodes (nodes without public IP addresses). When true, nodes only have internal IP addresses and cannot directly access the internet without NAT. Enhances security posture by reducing the attack surface."
  value       = var.enable_private_nodes
}

output "private_endpoint_enabled" {
  description = "Whether the cluster's master API endpoint is private (not exposed on the internet). When true, the Kubernetes API server can only be accessed from within the VPC or via authorized networks. Significantly improves security."
  value       = var.enable_private_endpoint
}

output "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation used for the master network in private clusters. This is the range used for communication between nodes and the control plane. Important for firewall configuration and network planning."
  value       = var.enable_private_nodes ? var.master_ipv4_cidr_block : null
}

#==============================================================================
# Monitoring and Logging
# Observability configuration for the GKE cluster
#==============================================================================
output "monitoring_enabled_components" {
  description = "GKE components being monitored in Cloud Monitoring. Typically includes 'SYSTEM_COMPONENTS' for control plane monitoring and 'WORKLOADS' for application monitoring. Affects which metrics are collected and billed."
  value       = var.monitoring_enabled_components
}

output "logging_enabled_components" {
  description = "GKE components sending logs to Cloud Logging. Typically includes 'SYSTEM_COMPONENTS' for control plane logs and 'WORKLOADS' for container logs. Affects which logs are collected and stored, impacting observability and billing."
  value       = var.logging_enabled_components
}

output "managed_prometheus_enabled" {
  description = "Whether Google Cloud Managed Service for Prometheus is enabled. When true, the cluster automatically collects Prometheus metrics and integrates with Cloud Monitoring. Provides scalable metrics storage without managing Prometheus servers."
  value       = var.enable_managed_prometheus
}

#==============================================================================
# Node Identity and Security
# Security configurations for GKE nodes
#==============================================================================
output "service_account" {
  description = "The Google Cloud IAM service account used by the node VMs. This account determines what Google Cloud resources nodes can access. Critical for security planning and managing least-privilege access for workloads."
  value       = var.service_account
}

output "node_oauth_scopes" {
  description = "The set of Google API scopes granted to node VMs. These determine which Google Cloud APIs the nodes can access. Important for security auditing and ensuring nodes have necessary but minimal permissions."
  value       = var.node_oauth_scopes
}

output "secure_boot_enabled" {
  description = "Whether Secure Boot is enabled for nodes. When true, nodes verify that boot components are signed by a trusted authority. Part of the Shielded Nodes feature set that helps prevent rootkits and bootkits from compromising nodes."
  value       = var.enable_secure_boot
}

output "integrity_monitoring_enabled" {
  description = "Whether integrity monitoring is enabled for nodes. When true, the system verifies that the node has not been modified from its known-good boot state. Provides runtime protection against persistent malware and rootkits."
  value       = var.enable_integrity_monitoring
}
