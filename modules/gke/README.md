# GKE (Google Kubernetes Engine) Terraform Module

A comprehensive Terraform module to provision and manage Google Kubernetes Engine (GKE) clusters with advanced configurations.

## Features

- Google Kubernetes Engine cluster deployment with flexible configuration options
- Support for both regional and zonal clusters
- Multiple node pools with different configurations (machine types, disk sizes, taints)
- Private cluster support with master authorized networks
- Workload Identity for secure GCP service account integration
- VPC-native networking with custom CIDR ranges
- Advanced security features (shielded nodes, secure boot, binary authorization)
- Release channel management and version control
- Managed add-ons: HTTP load balancing, HPA, VPA, CSI drivers
- Monitoring and logging with Cloud Monitoring and Cloud Logging
- Cost management with resource usage export and cost allocation
- Maintenance window scheduling

## Usage

```hcl
module "gke" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/gke"

  # Required parameters
  project_id   = "my-gcp-project"
  cluster_name = "my-gke-cluster"
  region       = "us-central1"
  network      = "default"
  subnetwork   = "default"

  # Cluster configuration
  regional_cluster   = true
  node_locations     = ["us-central1-a", "us-central1-b", "us-central1-c"]
  kubernetes_version = "1.28"
  release_channel    = "REGULAR"

  # Networking
  enable_private_nodes       = true
  enable_private_endpoint    = false
  master_ipv4_cidr_block     = "172.16.0.0/28"
  cluster_ipv4_cidr_block    = "10.52.0.0/14"
  services_ipv4_cidr_block   = "10.208.0.0/20"
  enable_network_policy      = true
  datapath_provider          = "ADVANCED_DATAPATH"
  
  # Security
  enable_workload_identity = true
  enable_secure_boot       = true
  master_authorized_cidr_blocks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "internal-network"
    },
    {
      cidr_block   = "123.123.123.123/32"
      display_name = "my-office-ip"
    }
  ]
  
  # Default node pool
  create_default_node_pool = true
  default_machine_type     = "e2-standard-4"
  default_disk_size_gb     = 100
  default_disk_type        = "pd-standard"
  default_node_count       = 1
  enable_node_auto_scaling = true
  default_min_node_count   = 1
  default_max_node_count   = 5
  default_node_labels      = {
    "env" = "production"
    "app" = "default"
  }
  
  # Additional node pools
  node_pools = {
    gpu-pool = {
      machine_type = "n1-standard-8"
      node_count   = 1
      min_count    = 0
      max_count    = 3
      disk_size_gb = 200
      disk_type    = "pd-ssd"
      labels       = {
        "workload-type" = "gpu"
      }
      taints = [
        {
          key    = "nvidia.com/gpu"
          value  = "present"
          effect = "NO_SCHEDULE"
        }
      ]
    },
    spot-pool = {
      machine_type = "e2-medium"
      node_count   = 2
      min_count    = 1
      max_count    = 10
      spot         = true
      labels       = {
        "workload-type" = "spot"
      }
    }
  }
  
  # Add-ons
  enable_http_load_balancing        = true
  enable_horizontal_pod_autoscaling = true
  enable_vertical_pod_autoscaling   = true
  enable_dns_cache                  = true
  enable_gce_persistent_disk_csi_driver = true
  enable_filestore_csi_driver       = false
  
  # Monitoring and logging
  logging_enabled_components     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  monitoring_enabled_components  = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  enable_managed_prometheus      = true
  
  # Maintenance window
  maintenance_start_time  = "03:00"
  maintenance_end_time    = "08:00"
  maintenance_recurrence  = "FREQ=WEEKLY;BYDAY=SA,SU"
  
  # Labels
  labels = {
    environment = "production"
    managed-by  = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| google | ~> 5.20.0 |
| google-beta | ~> 5.20.0 |
| kubernetes | ~> 2.30.0 |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| project_id | The project ID to host the cluster in | `string` |
| cluster_name | The name of the cluster | `string` |
| region | The region to host the cluster in | `string` |
| network | The VPC network to host the cluster in | `string` |
| subnetwork | The subnetwork to host the cluster in | `string` |

### Optional Cluster Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| regional_cluster | Whether to create a regional or zonal cluster | `bool` | `true` |
| zone | The zone to host the cluster in (for zonal clusters) | `string` | `null` |
| node_locations | The list of zones in which the cluster's nodes should be located | `list(string)` | `[]` |
| kubernetes_version | The Kubernetes version of the masters | `string` | `null` |
| release_channel | The release channel of the cluster | `string` | `"REGULAR"` |
| description | Description of the cluster | `string` | `""` |
| deletion_protection | Whether to allow Terraform to destroy the cluster | `bool` | `true` |

### Networking

| Name | Description | Type | Default |
|------|-------------|------|---------|
| cluster_ipv4_cidr_block | The IP address range for pod IPs | `string` | `null` |
| services_ipv4_cidr_block | The IP address range for service IPs | `string` | `null` |
| enable_private_nodes | When true, nodes have internal IP addresses only | `bool` | `false` |
| enable_private_endpoint | When true, the cluster's private endpoint is used as primary | `bool` | `false` |
| master_ipv4_cidr_block | The IP range for the hosted master network | `string` | `"172.16.0.0/28"` |
| master_authorized_cidr_blocks | List of master authorized networks | `list(object)` | `[]` |
| enable_network_policy | Enable network policy addon | `bool` | `true` |
| datapath_provider | The desired datapath provider for this cluster | `string` | `"ADVANCED_DATAPATH"` |

### Node Pool Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| create_default_node_pool | Create a default node pool | `bool` | `true` |
| default_node_count | The number of nodes in the default node pool | `number` | `1` |
| default_machine_type | The machine type for the default node pool | `string` | `"e2-medium"` |
| default_disk_size_gb | The disk size (in GB) for the default node pool | `number` | `100` |
| default_disk_type | The disk type for the default node pool | `string` | `"pd-standard"` |
| default_node_labels | The Kubernetes labels to be applied to nodes in the default pool | `map(string)` | `{}` |
| default_node_taints | The Kubernetes taints to be applied to nodes in the default pool | `list(object)` | `[]` |
| default_local_ssd_count | The number of local SSD disks to be attached to each node | `number` | `0` |
| default_use_spot_instances | Whether to use spot instances for the default node pool | `bool` | `false` |
| enable_node_auto_scaling | Whether to enable node pool autoscaling | `bool` | `true` |
| default_min_node_count | Minimum number of nodes when autoscaling is enabled | `number` | `1` |
| default_max_node_count | Maximum number of nodes when autoscaling is enabled | `number` | `3` |
| node_pools | List of additional node pool configurations | `map(object)` | `{}` |

### Add-ons and Features

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_http_load_balancing | Enable HTTP load balancing add-on | `bool` | `true` |
| enable_horizontal_pod_autoscaling | Enable horizontal pod autoscaling add-on | `bool` | `true` |
| enable_vertical_pod_autoscaling | Enable vertical pod autoscaling | `bool` | `false` |
| enable_dns_cache | Enable NodeLocal DNSCache add-on | `bool` | `false` |
| enable_filestore_csi_driver | Enable Filestore CSI driver add-on | `bool` | `false` |
| enable_gce_persistent_disk_csi_driver | Enable GCE Persistent Disk CSI driver add-on | `bool` | `true` |
| enable_config_connector | Enable Config Connector add-on | `bool` | `false` |

### Security Options

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_secure_boot | Enable secure boot for nodes | `bool` | `true` |
| enable_integrity_monitoring | Enable integrity monitoring for nodes | `bool` | `true` |
| enable_workload_identity | Enable Workload Identity on the cluster | `bool` | `true` |
| enable_binary_authorization | Enable Binary Authorization on the cluster | `bool` | `false` |

### Monitoring and Logging

| Name | Description | Type | Default |
|------|-------------|------|---------|
| logging_enabled_components | List of components to enable logging | `list(string)` | `["SYSTEM_COMPONENTS", "WORKLOADS"]` |
| monitoring_enabled_components | List of components to enable monitoring | `list(string)` | `["SYSTEM_COMPONENTS", "WORKLOADS"]` |
| enable_managed_prometheus | Enable managed Prometheus | `bool` | `false` |
| enable_resource_usage_export | Enable resource consumption metering | `bool` | `false` |
| enable_network_egress_metering | Enable network egress metering | `bool` | `false` |
| enable_resource_consumption_metering | Enable resource consumption metering | `bool` | `false` |
| resource_usage_export_dataset_id | BigQuery Dataset ID for resource usage export | `string` | `null` |
| enable_cost_allocation | Enable cost allocation for namespaces | `bool` | `false` |

### Maintenance Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| maintenance_start_time | Start time of maintenance window | `string` | `null` |
| maintenance_end_time | End time of maintenance window | `string` | `null` |
| maintenance_recurrence | Recurrence of maintenance window in RRULE format | `string` | `null` |

### Timeouts

| Name | Description | Type | Default |
|------|-------------|------|---------|
| cluster_create_timeout | Timeout for creating the cluster | `string` | `"30m"` |
| cluster_update_timeout | Timeout for updating the cluster | `string` | `"30m"` |
| cluster_delete_timeout | Timeout for deleting the cluster | `string` | `"30m"` |
| node_pool_create_timeout | Timeout for creating a node pool | `string` | `"30m"` |
| node_pool_update_timeout | Timeout for updating a node pool | `string` | `"30m"` |
| node_pool_delete_timeout | Timeout for deleting a node pool | `string` | `"30m"` |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the GKE cluster |
| cluster_name | The name of the GKE cluster |
| cluster_location | The location of the GKE cluster |
| cluster_type | The type of the GKE cluster (regional or zonal) |
| cluster_endpoint | The IP address of the Kubernetes master endpoint |
| cluster_ca_certificate | The cluster CA certificate (base64 encoded) |
| cluster_master_version | The Kubernetes master version |
| cluster_network | The VPC network used by the cluster |
| cluster_subnetwork | The subnetwork used by the cluster |
| cluster_self_link | The server-defined URL for the GKE cluster |
| cluster_services_ipv4_cidr | The IP address range of the Kubernetes services |
| cluster_pod_ipv4_cidr | The IP address range of the pods |
| default_node_pool | Details of the default node pool if created |
| additional_node_pools | Details of the additional node pools |
| client_token | The bearer token for authentication |
| kubeconfig_path | Path to the generated kubeconfig file |
| kubeconfig_raw | Raw kubeconfig content |
| release_channel | The release channel of the GKE cluster |
| workload_identity_enabled | Whether Workload Identity is enabled |
| workload_identity_pool | The Workload Identity Pool associated with the cluster |
| private_cluster_enabled | Whether the cluster has private nodes |
| private_endpoint_enabled | Whether the cluster's master API endpoint is private |
| managed_prometheus_enabled | Whether managed Prometheus is enabled |

## License

This module is released under the MIT License.