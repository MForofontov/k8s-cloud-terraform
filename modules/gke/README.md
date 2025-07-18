# GKE (Google Kubernetes Engine) Terraform Module

A comprehensive Terraform module to provision and manage Google Kubernetes Engine (GKE) clusters with advanced configurations for enterprise-grade Kubernetes deployments.

## Features

- **Cluster Flexibility**: Support for both regional (high availability) and zonal clusters
- **Advanced Networking**: VPC-native clusters with custom CIDR ranges, private clusters, and advanced datapath
- **Security Hardening**: Workload identity, shielded nodes, binary authorization, and network policies
- **Multi-tier Node Pools**: Create specialized node pools with different configurations for diverse workloads
- **Spot VM Support**: Cost optimization with preemptible Spot VMs for fault-tolerant workloads
- **Managed Add-ons**: Support for HTTP load balancing, HPA, VPA, DNS caching, and CSI drivers
- **Comprehensive Monitoring**: Cloud Monitoring, Cloud Logging, and managed Prometheus integration
- **Cost Management**: Resource usage export and namespace-level cost allocation
- **Maintenance Control**: Scheduled maintenance windows with recurrence rules

## Supported Features

| Feature | Regional | Zonal | Description |
|---------|:--------:|:-----:|-------------|
| **High Availability Control Plane** | ✅ | ❌ | Multi-zone control plane for enhanced resilience |
| **Auto Node Upgrades** | ✅ | ✅ | Automatic node version management |
| **Auto Node Repair** | ✅ | ✅ | Automatic remediation of unhealthy nodes |
| **Node Auto Provisioning** | ✅ | ✅ | Automatically create node pools based on workload demands |
| **Workload Identity** | ✅ | ✅ | Secure GCP service account integration for pods |
| **Private Cluster** | ✅ | ✅ | Nodes with only internal IP addresses |
| **VPC-native Networking** | ✅ | ✅ | Native VPC networking with alias IPs |
| **Network Policy** | ✅ | ✅ | Kubernetes NetworkPolicy enforcement with Calico |
| **GKE Dataplane V2** | ✅ | ✅ | Advanced datapath with eBPF for enhanced networking |
| **Cloud Monitoring** | ✅ | ✅ | Integrated metrics collection for cluster components |
| **Cloud Logging** | ✅ | ✅ | Integrated log collection for cluster components |
| **Managed Prometheus** | ✅ | ✅ | Managed metrics collection with Prometheus |
| **Shielded Nodes** | ✅ | ✅ | Enhanced security with secure boot and integrity monitoring |
| **Binary Authorization** | ✅ | ✅ | Enforcement of trusted container images |
| **Release Channels** | ✅ | ✅ | Managed Kubernetes version updates |
| **GPU Support** | ✅ | ✅ | Node pools with NVIDIA GPU acceleration |
| **Spot VM Support** | ✅ | ✅ | Low-cost preemptible VMs for fault-tolerant workloads |
| **Maintenance Windows** | ✅ | ✅ | Scheduled maintenance with customizable recurrence |
| **Cost Management** | ✅ | ✅ | Resource usage export and cost allocation |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| google | ~> 6.44.0 |
| google-beta | ~> 6.44.0 |
| kubernetes | ~> 2.37.1 |

## Usage

### Regional Cluster with Private Nodes

```hcl
module "gke" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/gke"

  # Required parameters
  project_id   = "my-gcp-project"
  cluster_name = "prod-cluster"
  region       = "us-central1"
  network      = "prod-vpc"
  subnetwork   = "prod-subnet"

  # Cluster configuration
  regional_cluster   = true
  node_locations     = ["us-central1-a", "us-central1-b", "us-central1-c"]
  kubernetes_version = "1.29"
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
  
  # Add-ons
  enable_http_load_balancing        = true
  enable_horizontal_pod_autoscaling = true
  enable_vertical_pod_autoscaling   = true
  enable_dns_cache                  = true
  enable_gce_persistent_disk_csi_driver = true
  
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

### Multi-tier Node Pool Configuration

```hcl
module "gke" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/gke"

  project_id   = "my-gcp-project"
  cluster_name = "multi-tier-cluster"
  region       = "us-west1"
  network      = "app-vpc"
  subnetwork   = "app-subnet"
  
  # Use minimal default node pool
  create_default_node_pool = true
  default_machine_type     = "e2-medium"
  default_node_count       = 1
  default_node_labels      = {
    "tier" = "system"
  }
  
  # Create specialized node pools for different workloads
  node_pools = {
    # General purpose apps
    app-pool = {
      machine_type = "e2-standard-4"
      node_count   = 2
      min_count    = 2
      max_count    = 10
      disk_size_gb = 100
      disk_type    = "pd-balanced"
      labels       = {
        "tier" = "application"
      }
    },
    
    # Memory-intensive workloads
    memory-pool = {
      machine_type = "e2-highmem-8"
      node_count   = 1
      min_count    = 0
      max_count    = 5
      disk_size_gb = 100
      labels       = {
        "tier" = "memory-optimized"
      }
    },
    
    # CPU-intensive workloads
    compute-pool = {
      machine_type = "e2-highcpu-16"
      node_count   = 1
      min_count    = 0
      max_count    = 5
      disk_size_gb = 100
      labels       = {
        "tier" = "compute-optimized"
      }
    },
    
    # GPU workloads
    gpu-pool = {
      machine_type = "n1-standard-8"
      node_count   = 0
      min_count    = 0
      max_count    = 3
      disk_size_gb = 200
      disk_type    = "pd-ssd"
      labels       = {
        "tier" = "gpu"
      }
      taints = [
        {
          key    = "nvidia.com/gpu"
          value  = "present"
          effect = "NO_SCHEDULE"
        }
      ]
    },
    
    # Cost-optimized pool for batch jobs
    spot-pool = {
      machine_type = "e2-medium"
      node_count   = 0
      min_count    = 0
      max_count    = 50
      spot         = true
      labels       = {
        "tier" = "spot"
      }
      taints = [
        {
          key    = "cloud.google.com/gke-spot"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
}
```

### Private GKE Cluster with VPC Service Controls

```hcl
module "gke" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/gke"

  project_id   = "secure-gcp-project"
  cluster_name = "secure-cluster"
  region       = "us-east1"
  network      = "secure-vpc"
  subnetwork   = "secure-subnet"
  
  # Private cluster configuration
  enable_private_nodes       = true
  enable_private_endpoint    = true
  master_ipv4_cidr_block     = "172.16.0.0/28"
  master_authorized_cidr_blocks = [
    {
      cidr_block   = "10.10.0.0/24"
      display_name = "bastion-subnet"
    }
  ]
  
  # Security configuration
  enable_workload_identity    = true
  enable_secure_boot          = true
  enable_integrity_monitoring = true
  enable_binary_authorization = true
  enable_network_policy       = true
  
  # Node configuration
  create_default_node_pool = true
  default_machine_type     = "e2-standard-4"
  default_disk_type        = "pd-ssd"
  default_node_count       = 3
  service_account          = "gke-sa@secure-gcp-project.iam.gserviceaccount.com"
}
```

## Input Variables

### Required Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The Google Cloud project ID where the GKE cluster will be created. This determines billing, permissions, and resource isolation. | `string` | n/a | yes |
| cluster_name | The name of the GKE cluster. This identifier will be used in logs, monitoring, and for accessing the cluster. Must be unique within the project and region. | `string` | n/a | yes |

### Location Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| region | The Google Cloud region where the GKE cluster will be created (e.g., 'us-central1'). For regional clusters, this determines the control plane location and default node locations. | `string` | n/a | yes |
| zone | The Google Cloud zone for zonal clusters (e.g., 'us-central1-a'). Only required when creating a zonal cluster (regional_cluster = false). Zonal clusters have a single control plane in one zone. | `string` | `null` | no |
| regional_cluster | Whether to create a regional cluster (true) or a zonal cluster (false). Regional clusters have control planes across multiple zones for higher availability but cost more. Recommended for production. | `bool` | `true` | no |
| node_locations | The list of zones within the region where worker nodes should be located (e.g., ['us-central1-a', 'us-central1-b']). Only applies to regional clusters. If empty, GKE will use the region's default zones. | `list(string)` | `[]` | no |

### Basic Cluster Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| description | Human-readable description of the GKE cluster. | `string` | `""` | no |
| kubernetes_version | The Kubernetes version for the cluster master. If not specified, the latest supported version is used. Format: '1.xx.y-gke.z'. | `string` | `null` | no |
| release_channel | The release channel for automatic Kubernetes version updates. Valid values: 'RAPID', 'REGULAR', 'STABLE', or 'UNSPECIFIED'. | `string` | `"REGULAR"` | no |
| deletion_protection | When true, the cluster cannot be deleted via Terraform. Set to false for easy cleanup in development environments. | `bool` | `true` | no |
| labels | Labels to be applied to the GKE cluster resource (key-value pairs). | `map(string)` | `{}` | no |

### Networking Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| network | The VPC network to host the cluster in. | `string` | n/a | yes |
| subnetwork | The subnetwork to host the cluster in. | `string` | n/a | yes |
| cluster_ipv4_cidr_block | The IP address range for Pod IPs in CIDR notation. If left blank, a range will be automatically chosen with the default size. | `string` | `null` | no |
| services_ipv4_cidr_block | The IP address range for Kubernetes Service IPs. If left blank, a range will be automatically chosen with the default size. | `string` | `null` | no |
| enable_private_nodes | When true, nodes only have internal IP addresses and communicate with the control plane via private networking. | `bool` | `false` | no |
| enable_private_endpoint | When true, the cluster's master API endpoint is only accessible via private IP addresses. | `bool` | `false` | no |
| master_ipv4_cidr_block | The IP range for the control plane network. Must be a /28 CIDR range. | `string` | `"172.16.0.0/28"` | no |
| master_authorized_cidr_blocks | List of CIDR blocks authorized to access the Kubernetes API server. Each block needs a display_name and cidr_block. | `list(object)` | `[]` | no |
| enable_network_policy | Enable Kubernetes NetworkPolicy enforcement with Calico. | `bool` | `true` | no |
| network_policy_provider | The network policy provider implementation. Currently, only 'CALICO' is supported. | `string` | `"CALICO"` | no |
| datapath_provider | The desired datapath provider for this cluster. Valid options: 'DATAPATH_PROVIDER_UNSPECIFIED', 'LEGACY_DATAPATH', or 'ADVANCED_DATAPATH'. | `string` | `"ADVANCED_DATAPATH"` | no |

### Default Node Pool Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_default_node_pool | Whether to create a default node pool. If false, you must create at least one node pool after cluster creation. | `bool` | `true` | no |
| default_node_count | The number of nodes in the default node pool. If auto-scaling is enabled, this represents the initial node count. | `number` | `1` | no |
| default_machine_type | The GCE machine type for nodes in the default pool. | `string` | `"e2-medium"` | no |
| default_disk_size_gb | The disk size (in GB) for each node in the default pool. | `number` | `100` | no |
| default_disk_type | The disk type for nodes in the default pool. Valid options: 'pd-standard', 'pd-balanced', or 'pd-ssd'. | `string` | `"pd-standard"` | no |
| default_node_labels | Kubernetes labels applied to nodes in the default pool. | `map(string)` | `{}` | no |
| default_node_taints | Kubernetes taints applied to nodes in the default pool. | `list(object)` | `[]` | no |
| default_node_tags | Network tags applied to the GCE instances in the default node pool. | `list(string)` | `[]` | no |
| default_local_ssd_count | The number of local SSD disks attached to each node in the default pool. | `number` | `0` | no |
| default_use_spot_instances | Whether to use Spot VMs for the default node pool. Spot VMs are preemptible and lower cost but can be reclaimed at any time. | `bool` | `false` | no |
| enable_node_auto_scaling | Whether to enable cluster autoscaler for node pools. | `bool` | `true` | no |
| default_min_node_count | Minimum number of nodes when autoscaling is enabled. | `number` | `1` | no |
| default_max_node_count | Maximum number of nodes when autoscaling is enabled. | `number` | `3` | no |

### Additional Node Pools

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| node_pools | Map of additional node pool configurations, where each key is the node pool name and the value is its configuration. | `map(object)` | `{}` | no |

### Node Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| image_type | The image type for all nodes. Valid options include: 'COS_CONTAINERD', 'UBUNTU_CONTAINERD'. | `string` | `"COS_CONTAINERD"` | no |
| service_account | The Google Cloud IAM service account to be used by node VMs. If not specified, the default compute service account will be used. | `string` | `null` | no |
| node_oauth_scopes | OAuth scopes granted to the node service account. | `list(string)` | `["https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring", "https://www.googleapis.com/auth/devstorage.read_only"]` | no |
| node_metadata | Metadata key/value pairs assigned to nodes. | `map(string)` | `{}` | no |

### Node Management

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| auto_repair | Whether nodes will be automatically repaired when they are found to be unhealthy. | `bool` | `true` | no |
| auto_upgrade | Whether nodes will be automatically upgraded when a new GKE version is available. | `bool` | `true` | no |
| max_surge | Maximum number of additional nodes that can be created during an upgrade. | `number` | `1` | no |
| max_unavailable | Maximum number of nodes that can be simultaneously unavailable during an upgrade. | `number` | `0` | no |
| node_location_policy | The location policy for the node pool autoscaler. Valid options: 'BALANCED' or 'ANY'. | `string` | `"BALANCED"` | no |

### Security Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_secure_boot | Enable Secure Boot for nodes. Secure Boot verifies the digital signature of all boot components. | `bool` | `true` | no |
| enable_integrity_monitoring | Enable integrity monitoring for nodes, which verifies the boot integrity of the node. | `bool` | `true` | no |
| enable_workload_identity | Enable Workload Identity to allow Kubernetes service accounts to act as specific Google IAM service accounts. | `bool` | `true` | no |
| enable_binary_authorization | Enable Binary Authorization to enforce deploy-time security controls. | `bool` | `false` | no |

### Features and Add-ons

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_http_load_balancing | Enable the HTTP (L7) load balancing controller add-on. | `bool` | `true` | no |
| enable_horizontal_pod_autoscaling | Enable the Horizontal Pod Autoscaler add-on. | `bool` | `true` | no |
| enable_vertical_pod_autoscaling | Enable Vertical Pod Autoscaling to automatically adjust Pod CPU and memory requests. | `bool` | `false` | no |
| enable_dns_cache | Enable NodeLocal DNSCache add-on to improve DNS performance. | `bool` | `false` | no |
| enable_filestore_csi_driver | Enable the Filestore CSI driver add-on to support Filestore PVs. | `bool` | `false` | no |
| enable_gce_persistent_disk_csi_driver | Enable the GCE Persistent Disk CSI driver add-on to support expanded storage features. | `bool` | `true` | no |
| enable_config_connector | Enable Config Connector add-on for managing Google Cloud resources through Kubernetes. | `bool` | `false` | no |

### Monitoring and Logging

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| logging_enabled_components | List of components to enable logging for. Valid options: 'SYSTEM_COMPONENTS', 'WORKLOADS'. | `list(string)` | `["SYSTEM_COMPONENTS", "WORKLOADS"]` | no |
| monitoring_enabled_components | List of components to enable monitoring for. Valid options: 'SYSTEM_COMPONENTS', 'WORKLOADS'. | `list(string)` | `["SYSTEM_COMPONENTS", "WORKLOADS"]` | no |
| enable_managed_prometheus | Enable Google Cloud Managed Service for Prometheus. | `bool` | `false` | no |
| enable_resource_usage_export | Enable resource consumption metering. | `bool` | `false` | no |
| enable_network_egress_metering | Enable network egress metering for the cluster. | `bool` | `false` | no |
| enable_resource_consumption_metering | Enable resource consumption metering. | `bool` | `false` | no |
| resource_usage_export_dataset_id | The ID of a BigQuery Dataset for resource usage export. Required if any resource usage export options are enabled. | `string` | `null` | no |
| enable_cost_allocation | Enable cost allocation to split resource usage by namespace. | `bool` | `false` | no |

### Maintenance Window

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| maintenance_start_time | Start time of the maintenance window (HH:MM format). | `string` | `null` | no |
| maintenance_end_time | End time of the maintenance window (HH:MM format). | `string` | `null` | no |
| maintenance_recurrence | Recurrence of the maintenance window in RRULE format (e.g., 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'). | `string` | `null` | no |

### Operation Timeouts

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_create_timeout | Timeout for creating the GKE cluster. | `string` | `"30m"` | no |
| cluster_update_timeout | Timeout for updating the GKE cluster. | `string` | `"30m"` | no |
| cluster_delete_timeout | Timeout for deleting the GKE cluster. | `string` | `"30m"` | no |
| node_pool_create_timeout | Timeout for creating a node pool. | `string` | `"30m"` | no |
| node_pool_update_timeout | Timeout for updating a node pool. | `string` | `"30m"` | no |
| node_pool_delete_timeout | Timeout for deleting a node pool. | `string` | `"30m"` | no |

## Output Variables

### Cluster Information

| Name | Description | Type |
|------|-------------|------|
| cluster_id | The fully-qualified ID of the GKE cluster. | `string` |
| cluster_name | The name of the GKE cluster. | `string` |
| cluster_location | The location of the GKE cluster (region or zone). | `string` |
| cluster_type | The type of the GKE cluster (regional or zonal). | `string` |
| cluster_endpoint | The IP address of the Kubernetes API server endpoint. | `string` |
| cluster_ca_certificate | The cluster's CA certificate in base64-encoded format. | `string` |
| cluster_master_version | The Kubernetes version running on the master nodes. | `string` |
| cluster_network | The VPC network used by the cluster. | `string` |
| cluster_subnetwork | The VPC subnetwork used by the cluster. | `string` |
| cluster_self_link | The server-defined URL for the GKE cluster. | `string` |
| cluster_services_ipv4_cidr | The IP address range of the Kubernetes services. | `string` |
| cluster_pod_ipv4_cidr | The IP address range of the pods. | `string` |

### Node Pool Information

| Name | Description | Type |
|------|-------------|------|
| default_node_pool | Details of the default node pool if created. | `object` |
| additional_node_pools | Details of the additional node pools. | `map(object)` |

### Authentication Information

| Name | Description | Type |
|------|-------------|------|
| client_token | The OAuth access token for GCP. | `string` |
| kubeconfig_path | The filesystem path to the generated kubeconfig file. | `string` |
| kubeconfig_raw | The raw content of the generated kubeconfig file. | `string` |

### Features and Add-ons

| Name | Description | Type |
|------|-------------|------|
| release_channel | The release channel of the GKE cluster. | `string` |
| workload_identity_enabled | Whether Workload Identity is enabled. | `bool` |
| workload_identity_pool | The Workload Identity Pool associated with the cluster. | `string` |
| network_policy_enabled | Whether Network Policy is enabled. | `bool` |
| horizontal_pod_autoscaling_enabled | Whether Horizontal Pod Autoscaling is enabled. | `bool` |
| vertical_pod_autoscaling_enabled | Whether Vertical Pod Autoscaling is enabled. | `bool` |

### Private Cluster Configuration

| Name | Description | Type |
|------|-------------|------|
| private_cluster_enabled | Whether the cluster has private nodes. | `bool` |
| private_endpoint_enabled | Whether the cluster's master API endpoint is private. | `bool` |
| master_ipv4_cidr_block | The IP range used for the master network. | `string` |

### Monitoring and Logging

| Name | Description | Type |
|------|-------------|------|
| monitoring_enabled_components | GKE components being monitored. | `list(string)` |
| logging_enabled_components | GKE components sending logs. | `list(string)` |
| managed_prometheus_enabled | Whether managed Prometheus is enabled. | `bool` |

### Node Identity and Security

| Name | Description | Type |
|------|-------------|------|
| service_account | The Google Cloud IAM service account used by nodes. | `string` |
| node_oauth_scopes | The set of Google API scopes granted to nodes. | `list(string)` |
| secure_boot_enabled | Whether Secure Boot is enabled for nodes. | `bool` |
| integrity_monitoring_enabled | Whether integrity monitoring is enabled. | `bool` |

## License

This module is released under the MIT License.
