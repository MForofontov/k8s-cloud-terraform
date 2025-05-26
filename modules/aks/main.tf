// AKS Cluster Terraform Module

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.48.0"
    }
  }
}

data "azurerm_resource_group" "aks" {
  name = var.resource_group_name
}

# Get the current tenant ID if not provided
data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "this" {
  name                    = var.cluster_name
  location                = data.azurerm_resource_group.aks.location
  resource_group_name     = data.azurerm_resource_group.aks.name
  dns_prefix              = var.dns_prefix != null ? var.dns_prefix : var.cluster_name
  kubernetes_version      = var.kubernetes_version
  node_resource_group     = var.node_resource_group_name
  sku_tier                = var.sku_tier
  private_cluster_enabled = var.enable_private_cluster

  default_node_pool {
    name                 = var.default_node_pool_name
    vm_size              = var.default_node_pool_vm_size
    vnet_subnet_id       = var.subnet_id
    zones                = var.availability_zones
    node_count           = var.enable_auto_scaling ? null : var.default_node_pool_node_count
    auto_scaling_enabled = var.enable_auto_scaling
    min_count            = var.enable_auto_scaling ? var.default_node_pool_min_count : null
    max_count            = var.enable_auto_scaling ? var.default_node_pool_max_count : null
    os_disk_size_gb      = var.os_disk_size_gb
    os_disk_type         = var.os_disk_type
    node_labels          = var.default_node_pool_labels
    tags                 = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  # Role-based access control
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = var.azure_rbac_enabled
    tenant_id              = var.tenant_id != null ? var.tenant_id : data.azurerm_client_config.current.tenant_id
  }

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr
    outbound_type     = var.outbound_type
    load_balancer_sku = "standard"
  }

  # API server access
  api_server_access_profile {
    authorized_ip_ranges   = var.api_server_authorized_ip_ranges
  }

  # Maintenance window
  maintenance_window {
    allowed {
      day   = var.maintenance_window_day
      hours = var.maintenance_window_hours
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to the node count, as this can be managed by the auto-scaler
      default_node_pool[0].node_count
    ]
  }
}

# Create Log Analytics workspace if enabled
resource "azurerm_log_analytics_workspace" "aks" {
  count               = var.enable_log_analytics_workspace ? 1 : 0
  name                = "${var.cluster_name}-logs"
  location            = data.azurerm_resource_group.aks.location
  resource_group_name = data.azurerm_resource_group.aks.name
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_retention_in_days
  tags                = var.tags
}

# Enable Azure Monitor for containers if Log Analytics workspace is enabled
resource "azurerm_monitor_diagnostic_setting" "aks" {
  count                      = var.enable_log_analytics_workspace ? 1 : 0
  name                       = "${var.cluster_name}-diagnostic-settings"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks[0].id

  log_analytics_destination_type = "Dedicated"
}

# Create Container Insights add-on if Log Analytics is enabled
resource "azurerm_monitor_diagnostic_setting" "container_insights" {
  count                      = var.enable_log_analytics_workspace ? 1 : 0
  name                       = "${var.cluster_name}-container-insights"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks[0].id
}

# Create additional node pools if specified
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each              = var.additional_node_pools
  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  node_count            = each.value.min_count != null ? null : each.value.node_count
  
  # Correct auto-scaling attribute name
  auto_scaling_enabled  = each.value.min_count != null ? true : false
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  vnet_subnet_id        = var.subnet_id
  zones                 = var.availability_zones
  node_labels           = each.value.node_labels
  mode                  = each.value.mode
  tags                  = var.tags
}

# Generate kubeconfig
resource "local_file" "kubeconfig" {
  content  = azurerm_kubernetes_cluster.this.kube_config_raw
  filename = "${path.module}/kubeconfig_${var.cluster_name}"
}