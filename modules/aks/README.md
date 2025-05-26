# Azure Kubernetes Service (AKS) Terraform Module

A comprehensive Terraform module to provision and manage Azure Kubernetes Service (AKS) clusters with advanced configuration options.

## Features

- Managed Azure Kubernetes Service (AKS) cluster deployment
- Default node pool with auto-scaling capabilities
- Support for additional node pools with customizable configurations
- Azure Active Directory integration with RBAC
- Advanced networking configuration with support for Azure CNI
- Private cluster deployment options
- API server access controls
- Scheduled maintenance windows
- Integration with Azure Monitor and Log Analytics
- Automated kubeconfig generation

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| azurerm | ~> 3.90.0 |
| kubernetes | ~> 2.30.0 |
| azuread | ~> 2.48.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.90.0 |
| azuread | ~> 2.48.0 |
| local | >= 2.1.0 |

## Usage

```hcl
module "aks" {
  source = "github.com/your-org/k8s-cloud-terraform//modules/aks"

  # Required parameters
  cluster_name        = "my-aks-cluster"
  resource_group_name = "my-resource-group"
  subnet_id           = azurerm_subnet.aks.id

  # Optional cluster configuration
  kubernetes_version      = "1.27.7"
  sku_tier                = "Free"
  enable_private_cluster  = false
  
  # Default node pool configuration
  default_node_pool_name      = "system"
  default_node_pool_vm_size   = "Standard_D2s_v3"
  default_node_pool_node_count = 3
  enable_auto_scaling         = true
  default_node_pool_min_count = 1
  default_node_pool_max_count = 5
  os_disk_size_gb             = 128
  os_disk_type                = "Managed"
  
  # Azure AD integration
  admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"]
  azure_rbac_enabled     = true
  
  # Network configuration
  network_plugin    = "azure"
  network_policy    = "azure"
  service_cidr      = "10.0.0.0/16"
  dns_service_ip    = "10.0.0.10"
  outbound_type     = "loadBalancer"
  
  # API server access
  api_server_authorized_ip_ranges = ["203.0.113.0/24"]
  
  # Maintenance window
  maintenance_window_day   = "Sunday"
  maintenance_window_hours = [0, 1, 2]
  
  # Monitoring
  enable_log_analytics_workspace = true
  log_analytics_workspace_sku    = "PerGB2018"
  log_retention_in_days          = 30
  
  # Additional node pools
  additional_node_pools = {
    workload = {
      vm_size         = "Standard_D4s_v3"
      node_count      = 2
      min_count       = 1
      max_count       = 5
      os_disk_size_gb = 128
      os_disk_type    = "Managed"
      node_labels     = { "workload-type" = "general" }
      mode            = "User"
    }
  }
  
  tags = {
    Environment = "Production"
    Department  = "IT"
  }
}

## Required Inputs

| Name | Description | Type |
|------|-------------|------|
| cluster_name | The name of the AKS cluster | string |
| resource_group_name | The name of the resource group in which to create the AKS cluster | string |
| subnet_id | The ID of the subnet where the default node pool should be deployed | string |

## Optional Inputs

### Cluster Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| dns_prefix | DNS prefix specified when creating the managed cluster | string | null (uses cluster_name) |
| kubernetes_version | Kubernetes version to use for the AKS cluster | string | null (latest version) |
| node_resource_group_name | The name of the resource group in which to create the AKS cluster resources | string | null (auto-generated) |
| sku_tier | The SKU tier for the AKS cluster (Free or Paid) | string | "Free" |
| enable_private_cluster | Enable private cluster for the AKS cluster | bool | false |

### Default Node Pool

| Name | Description | Type | Default |
|------|-------------|------|---------|
| default_node_pool_name | The name of the default node pool | string | "default" |
| default_node_pool_vm_size | The size of the VMs in the default node pool | string | "Standard_D2s_v3" |
| availability_zones | A list of availability zones to use for the default node pool | list(string) | null |
| default_node_pool_node_count | The initial number of nodes in the default node pool | number | 1 |
| enable_auto_scaling | Enable auto-scaling for the default node pool | bool | false |
| default_node_pool_min_count | The minimum number of nodes when auto-scaling is enabled | number | 1 |
| default_node_pool_max_count | The maximum number of nodes when auto-scaling is enabled | number | 3 |
| os_disk_size_gb | The size of the OS disk in GB for each node | number | 128 |
| os_disk_type | The type of OS disk for each node | string | "Managed" |
| default_node_pool_labels | A map of Kubernetes labels to apply to nodes | map(string) | {} |

### Network Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| network_plugin | The network plugin to use (azure or kubenet) | string | "azure" |
| network_policy | The network policy to use (azure, calico) | string | "azure" |
| dns_service_ip | IP address for Kubernetes DNS service | string | "10.0.0.10" |
| service_cidr | The CIDR block for Kubernetes services | string | "10.0.0.0/16" |
| outbound_type | The outbound routing method | string | "loadBalancer" |
| api_server_authorized_ip_ranges | List of IP ranges authorized to access the API server | list(string) | null |

### Azure AD Integration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| admin_group_object_ids | A list of Azure AD group object IDs that will have admin role | list(string) | [] |
| azure_rbac_enabled | Enable Azure RBAC for Kubernetes authorization | bool | false |
| tenant_id | The tenant ID for Azure Active Directory | string | null (current tenant) |

### Monitoring

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_log_analytics_workspace | Enable Log Analytics workspace | bool | false |
| log_analytics_workspace_sku | The SKU of the Log Analytics workspace | string | "PerGB2018" |
| log_retention_in_days | The retention period for logs in days | number | 30 |

### Additional Node Pools

The `additional_node_pools` variable is a map of objects with the following schema:

```hcl
variable "additional_node_pools" {
  type = map(object({
    vm_size         = string
    node_count      = optional(number)
    min_count       = optional(number)
    max_count       = optional(number)
    os_disk_size_gb = optional(number)
    os_disk_type    = optional(string)
    node_labels     = optional(map(string))
    mode            = optional(string, "User")
  }))
  default = {}
}

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the AKS cluster |
| name | The name of the AKS cluster |
| resource_group_name | The resource group name where the AKS cluster is located |
| kubernetes_version | The Kubernetes version of the AKS cluster |
| node_resource_group | The auto-generated resource group for AKS resources |
| kube_config_raw | Raw Kubernetes config for kubectl (sensitive) |
| kube_admin_config_raw | Raw Kubernetes admin config (sensitive) |
| host | The Kubernetes cluster server host (sensitive) |
| client_certificate | Base64 encoded public certificate for client authentication (sensitive) |
| client_key | Base64 encoded private key for client authentication (sensitive) |
| cluster_ca_certificate | Base64 encoded public CA certificate (sensitive) |
| kubeconfig_path | Path to the generated kubeconfig file |
| fqdn | The FQDN of the AKS cluster |
| private_fqdn | The private FQDN of the AKS cluster |
| network_profile | Network configuration of the AKS cluster |
| identity | Identity information for the AKS cluster |
| default_node_pool | Information about the default node pool |
| additional_node_pools | Information about any additional node pools |
| log_analytics_workspace_id | The ID of the Log Analytics workspace (if enabled) |
| log_analytics_workspace_name | The name of the Log Analytics workspace (if enabled) |

## License

MIT