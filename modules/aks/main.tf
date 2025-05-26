# Azure Kubernetes Service (AKS) Terraform Module

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0.0"
    }
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  
  default_node_pool {
    name                = var.default_node_pool_name
    vm_size             = var.default_node_pool_vm_size
    node_count          = var.default_node_pool_node_count
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.min_node_count : null
    max_count           = var.enable_auto_scaling ? var.max_node_count : null
    vnet_subnet_id      = var.vnet_subnet_id
    zones               = var.availability_zones
    os_disk_size_gb     = var.os_disk_size_gb
    os_disk_type        = var.os_disk_type
    max_pods            = var.max_pods
    node_labels         = var.node_labels
    node_taints         = var.node_taints
    tags                = var.tags
  }

  identity {
    type = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" ? var.user_assigned_identity_ids : null
  }

  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    load_balancer_sku  = "standard"
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr
    outbound_type      = var.outbound_type
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_active_directory ? [1] : []
    content {
      managed                = true
      admin_group_object_ids = var.admin_group_object_ids
      azure_rbac_enabled     = var.azure_rbac_enabled
    }
  }

  dynamic "microsoft_defender" {
    for_each = var.enable_microsoft_defender ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  dynamic "oms_agent" {
    for_each = var.enable_log_analytics ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_key_vault_secrets_provider ? [1] : []
    content {
      secret_rotation_enabled  = var.secret_rotation_enabled
      secret_rotation_interval = var.secret_rotation_interval
    }
  }

  dynamic "aci_connector_linux" {
    for_each = var.enable_aci_connector_linux ? [1] : []
    content {
      subnet_name = var.aci_connector_linux_subnet_name
    }
  }

  dynamic "ingress_application_gateway" {
    for_each = var.enable_app_gateway ? [1] : []
    content {
      gateway_id   = var.app_gateway_id
      gateway_name = var.app_gateway_name
      subnet_id    = var.app_gateway_subnet_id
      subnet_cidr  = var.app_gateway_subnet_cidr
    }
  }

  azure_policy_enabled = var.enable_azure_policy
  http_application_routing_enabled = var.enable_http_application_routing
  
  auto_scaler_profile {
    balance_similar_node_groups      = var.balance_similar_node_groups
    max_graceful_termination_sec     = var.max_graceful_termination_sec
    scale_down_delay_after_add       = var.scale_down_delay_after_add
    scale_down_delay_after_delete    = var.scale_down_delay_after_delete
    scale_down_delay_after_failure   = var.scale_down_delay_after_failure
    scan_interval                    = var.scan_interval
    scale_down_unneeded              = var.scale_down_unneeded
    scale_down_unready               = var.scale_down_unready
    scale_down_utilization_threshold = var.scale_down_utilization_threshold
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      kubernetes_version,
      default_node_pool[0].node_count
    ]
  }
}

# Additional node pools
resource "azurerm_kubernetes_cluster_node_pool" "additional_pools" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  enable_auto_scaling   = each.value.enable_auto_scaling
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  vnet_subnet_id        = each.value.vnet_subnet_id != null ? each.value.vnet_subnet_id : var.vnet_subnet_id
  zones                 = each.value.zones
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  max_pods              = each.value.max_pods
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  mode                  = each.value.mode
  priority              = each.value.priority
  eviction_policy       = each.value.priority == "Spot" ? each.value.eviction_policy : null
  spot_max_price        = each.value.priority == "Spot" ? each.value.spot_max_price : null
  os_type               = each.value.os_type
  tags                  = merge(var.tags, each.value.tags)
}

# Role assignments for AKS managed identity
resource "azurerm_role_assignment" "network_contributor" {
  count                = var.assign_network_contributor_role ? 1 : 0
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

# Log Analytics solution for containers
resource "azurerm_log_analytics_solution" "container_insights" {
  count                 = var.create_log_analytics_solution ? 1 : 0
  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = var.log_analytics_workspace_id
  workspace_name        = var.log_analytics_workspace_name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}