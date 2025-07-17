# AKS (Azure Kubernetes Service) Terraform Module

A comprehensive Terraform module to provision and manage Azure Kubernetes Service (AKS) clusters with advanced configurations for enterprise-grade Kubernetes deployments.

## Features

- **Cluster Flexibility**: Support for multiple node pools, availability zones, and private clusters
- **Advanced Networking**: VNet integration, custom subnets, network policies, and outbound control
- **Security Hardening**: Azure AD integration, RBAC, API server authorized IPs, and managed identities
- **Autoscaling**: Cluster and node pool autoscaling for dynamic workloads
- **Comprehensive Monitoring**: Azure Monitor and Log Analytics integration
- **Maintenance Control**: Customizable maintenance windows
- **Production Ready**: Implements Azure best practices for secure, scalable, and highly available clusters

## Supported Features

| Feature                        | Supported | Description |
|--------------------------------|:---------:|-------------|
| **Multiple Node Pools**        | ✅        | Default and additional node pools with custom config |
| **Availability Zones**         | ✅        | Distribute nodes across zones for HA |
| **Private Cluster**            | ✅        | API server with private endpoint only |
| **Azure AD Integration**       | ✅        | Native RBAC and authentication |
| **Autoscaling**                | ✅        | Node pool autoscaling (min/max nodes) |
| **Network Policy**             | ✅        | Azure, Calico, or Cilium network policies |
| **Custom VNet/Subnet**         | ✅        | Deploy nodes into user-supplied subnet |
| **API Server Authorized IPs**  | ✅        | Restrict API access to trusted CIDRs |
| **Managed Identity**           | ✅        | System-assigned identity for Azure access |
| **Log Analytics Monitoring**   | ✅        | Azure Monitor and Log Analytics integration |
| **Custom Maintenance Window**  | ✅        | Control when Azure can perform maintenance |

## Requirements

| Name       | Version     |
|------------|-------------|
| terraform  | >= 1.0.0    |
| azurerm    | ~> 4.45.0   |
| kubernetes | ~> 2.42.0   |
| azuread    | ~> 2.55.0   |

## Usage

```hcl
module "aks" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/aks"

  # Required
  resource_group_name      = "my-aks-rg"
  cluster_name             = "prod-aks"
  subnet_id                = azurerm_subnet.aks.id

  # Recommended/Optional
  node_resource_group_name = "my-aks-nodes"
  dns_prefix               = "prod-aks"
  kubernetes_version       = "1.28.3"
  sku_tier                 = "Paid"
  enable_private_cluster   = true
  api_server_authorized_ip_ranges = ["10.0.0.0/8", "203.0.113.0/24"]

  # Default node pool
  default_node_pool_name        = "default"
  default_node_pool_vm_size     = "Standard_D4s_v3"
  default_node_pool_node_count  = 3
  enable_auto_scaling           = true
  default_node_pool_min_count   = 2
  default_node_pool_max_count   = 6
  os_disk_size_gb               = 128
  os_disk_type                  = "Managed"
  availability_zones            = ["1", "2", "3"]
  default_node_pool_labels      = { environment = "prod" }

  # Additional node pools
  additional_node_pools = {
    gpu = {
      vm_size         = "Standard_NC6s_v3"
      min_count       = 0
      max_count       = 2
      os_disk_size_gb = 128
      node_labels     = { "workload-type" = "gpu" }
    }
  }

  # Azure AD integration
  admin_group_object_ids = ["<aad-group-object-id>"]
  azure_rbac_enabled     = true

  # Networking
  network_plugin         = "azure"
  network_policy         = "azure"
  service_cidr           = "10.0.0.0/16"
  dns_service_ip         = "10.0.0.10"
  outbound_type          = "loadBalancer"

  # Maintenance
  maintenance_window_day   = "Sunday"
  maintenance_window_hours = [0, 1, 2]

  # Monitoring
  enable_log_analytics_workspace = true
  log_analytics_workspace_sku    = "PerGB2018"
  log_retention_in_days          = 30

  # Tags
  tags = {
    environment = "production"
    owner       = "devops"
  }
}
```

## Input Variables

### Resource Group Configuration

| Name                    | Type   | Default | Description |
|-------------------------|--------|---------|-------------|
| resource_group_name     | string | n/a     | Resource group for AKS cluster |
| node_resource_group_name| string | null    | Resource group for node resources |

### Cluster Configuration

| Name              | Type   | Default | Description |
|-------------------|--------|---------|-------------|
| cluster_name      | string | n/a     | Name of the AKS cluster |
| dns_prefix        | string | null    | DNS prefix for API server FQDN |
| kubernetes_version| string | null    | Kubernetes version |
| sku_tier          | string | "Free"  | AKS SKU tier (Free/Paid) |

### Default Node Pool Configuration

| Name                         | Type           | Default         | Description |
|------------------------------|----------------|-----------------|-------------|
| default_node_pool_name       | string         | "default"       | Default node pool name |
| default_node_pool_vm_size    | string         | "Standard_D2s_v3" | VM size for default node pool |
| subnet_id                    | string         | n/a             | Subnet ID for default node pool |
| availability_zones           | list(string)   | null            | Availability zones |
| default_node_pool_node_count | number         | 1               | Initial node count |
| enable_auto_scaling          | bool           | false           | Enable autoscaling |
| default_node_pool_min_count  | number         | 1               | Min nodes for autoscaling |
| default_node_pool_max_count  | number         | 3               | Max nodes for autoscaling |
| os_disk_size_gb              | number         | 128             | OS disk size in GB |
| os_disk_type                 | string         | "Managed"       | OS disk type |
| default_node_pool_labels     | map(string)    | {}              | Node labels |

### Additional Node Pools

| Name                 | Type        | Default | Description |
|----------------------|-------------|---------|-------------|
| additional_node_pools| map(object) | {}      | Additional node pools |

### Azure AD Integration

| Name                  | Type         | Default | Description |
|-----------------------|--------------|---------|-------------|
| admin_group_object_ids| list(string) | []      | Azure AD admin group object IDs |
| azure_rbac_enabled    | bool         | false   | Enable Azure RBAC |
| tenant_id             | string       | null    | Azure AD tenant ID |

### Networking Configuration

| Name            | Type         | Default       | Description |
|-----------------|--------------|---------------|-------------|
| network_plugin  | string       | "azure"      | Network plugin |
| network_policy  | string       | "azure"      | Network policy |
| dns_service_ip  | string       | "10.0.0.10"  | DNS service IP |
| service_cidr    | string       | "10.0.0.0/16"| Service CIDR |
| outbound_type   | string       | "loadBalancer"| Outbound routing type |

### API Server Access

| Name                        | Type         | Default | Description |
|-----------------------------|--------------|---------|-------------|
| api_server_authorized_ip_ranges | list(string) | null    | API server authorized IPs |
| enable_private_cluster      | bool         | false   | Enable private cluster |

### Maintenance Window

| Name                   | Type         | Default     | Description |
|------------------------|--------------|-------------|-------------|
| maintenance_window_day | string       | "Sunday"    | Maintenance window day |
| maintenance_window_hours| list(number) | [0,1,2]     | Maintenance window hours |

### Monitoring and Logging

| Name                        | Type    | Default      | Description |
|-----------------------------|---------|--------------|-------------|
| enable_log_analytics_workspace | bool  | false        | Enable Log Analytics |
| log_analytics_workspace_sku  | string | "PerGB2018" | Log Analytics SKU |
| log_retention_in_days        | number | 30           | Log retention days |
| tags                         | map(string) | {}       | Resource tags |

---

## Outputs

### Core Cluster Information
| Name                | Description |
|---------------------|-------------|
| id                  | AKS cluster ID |
| name                | AKS cluster name |
| resource_group_name | Resource group name |
| location            | Azure region |
| kubernetes_version  | Kubernetes version |
| node_resource_group | Node resource group |

### Authentication and Access
| Name                  | Description |
|-----------------------|-------------|
| kube_config_raw       | Raw kubeconfig YAML |
| kube_admin_config_raw | Raw admin kubeconfig YAML |
| host                  | Kubernetes API server endpoint |
| client_certificate    | Base64 client certificate |
| client_key            | Base64 client key |
| cluster_ca_certificate| Base64 cluster CA certificate |

### Node Pool Information
| Name                 | Description |
|----------------------|-------------|
| default_node_pool    | Default node pool info |
| additional_node_pools| Additional node pools info |

### Network Configuration
| Name            | Description |
|-----------------|-------------|
| network_profile | Network configuration |
| fqdn            | Public FQDN for API server |
| private_fqdn    | Private FQDN for API server |

### Identity Information
| Name     | Description |
|----------|-------------|
| identity | Managed identity info |

### Monitoring Configuration
| Name                       | Description |
|----------------------------|-------------|
| log_analytics_workspace_id | Log Analytics workspace ID |
| log_analytics_workspace_name | Log Analytics workspace name |

### Local Configuration
| Name           | Description |
|----------------|-------------|
| kubeconfig_path| Path to generated kubeconfig file |

## License

This module is released under the MIT License.
