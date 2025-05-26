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

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = data.azurerm_resource_group.aks.location
  resource_group_name = data.azurerm_resource_group.aks.name
  dns_prefix          = var.dns_prefix != null ? var.dns_prefix : var.cluster_name
  kubernetes_version  = var.kubernetes_version
  node_resource_group = var.node_resource_group_name
  sku_tier            = var.sku_tier

  default_node_pool {
    name                = var.default_node_pool_name
    vm_size             = var.default_node_pool_vm_size
    vnet_subnet_id      = var.subnet_id
    zones               = var.availability_zones
    node_count          = var.default_node_pool_node_count
    min_count           = var.enable_auto_scaling ? var.default_node_pool_min_count : null
    max_count           = var.enable_auto_scaling ? var.default_node_pool_max_count : null
    enable_auto_scaling = var.enable_auto_scaling
    os_disk_size_gb     = var.os_disk_size_gb
    os_disk_type        = var.os_disk_type
    node_labels         = var.default_node_pool_labels
    node_taints         = var.default_node_pool_taints
    tags                = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = var.azure_rbac_enabled
  }

  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    dns_service_ip     = var.dns_service_ip
    service_cidr       = var.service_cidr
    docker_bridge_cidr = var.docker_bridge_cidr
    outbound_type      = var.outbound_type
    load_balancer_sku  = "standard"
  }

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
    enable_private_cluster = var.enable_private_cluster
  }

  addon_profile {
    dynamic "azure_policy" {
      for_each = var.enable_azure_policy ? [1] : []
      content {
        enabled = true
      }
    }

    dynamic "oms_agent" {
      for_each = var.enable_log_analytics_workspace ? [1] : []
      content {
        enabled                    = true
        log_analytics_workspace_id = azurerm_log_analytics_workspace.aks[0].id
      }
    }

    dynamic "azure_keyvault_secrets_provider" {
      for_each = var.enable_key_vault_secrets_provider ? [1] : []
      content {
        enabled                  = true
        secret_rotation_enabled  = var.secret_rotation_enabled
        secret_rotation_interval = var.secret_rotation_interval
      }
    }
  }

  maintenance_window {
    allowed {
      day   = var.maintenance_window_day
      hours = var.maintenance_window_hours
    }
  }

  auto_upgrade_profile {
    upgrade_channel = var.upgrade_channel
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to the node count, as this can be managed by the auto-scaler
      default_node_pool[0].node_count
    ]
  }
}

resource "azurerm_log_analytics_workspace" "aks" {
  count               = var.enable_log_analytics_workspace ? 1 : 0
  name                = "${var.cluster_name}-logs"
  location            = data.azurerm_resource_group.aks.location
  resource_group_name = data.azurerm_resource_group.aks.name
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_retention_in_days
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each              = var.additional_node_pools
  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  enable_auto_scaling   = each.value.enable_auto_scaling
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  vnet_subnet_id        = var.subnet_id
  zones                 = var.availability_zones
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  mode                  = each.value.mode
  tags                  = var.tags
}

# Generate kubeconfig
resource "local_file" "kubeconfig" {
  content  = azurerm_kubernetes_cluster.this.kube_config_raw
  filename = "${path.module}/kubeconfig_${var.cluster_name}"
}