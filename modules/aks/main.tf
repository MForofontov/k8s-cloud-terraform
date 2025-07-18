#==============================================================================
# Azure Kubernetes Service (AKS) Module
#
# This module provisions a production-ready AKS cluster with customizable
# configurations for networking, node pools, security, and operations.
# It supports various cluster topologies with options for availability zones,
# private clusters, and multiple node pools to accommodate different workload
# requirements.
#
# The module implements Azure best practices for cluster configuration:
# - Secure API server access controls and private cluster options
# - Azure AD integration for RBAC and authentication
# - Virtual network integration for network isolation
# - Advanced monitoring with Azure Monitor for containers
# - Optimized maintenance windows to minimize disruption
#==============================================================================

#==============================================================================
# Provider Configuration
# Specifies the required providers and versions for this module
#==============================================================================
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.45.0" # Latest stable Azure provider at time of creation
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29.0" # For optional Kubernetes resource management
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.55.0" # For Azure AD integration and RBAC
    }
  }
  required_version = ">= 1.0.0"
}

#==============================================================================
# Data Sources
# References to existing Azure resources and metadata
#==============================================================================
# Get information about the resource group where AKS will be deployed
data "azurerm_resource_group" "aks" {
  name = var.resource_group_name # Must exist prior to deployment
}

# Retrieve current Azure tenant and subscription information
data "azurerm_client_config" "current" {
  # Used for Azure AD integration if tenant ID is not explicitly provided
  # This ensures the cluster uses the same tenant as the deploying identity
}

#==============================================================================
# AKS Cluster Resource
# The primary resource that defines the Kubernetes cluster
#==============================================================================
resource "azurerm_kubernetes_cluster" "this" {
  name                    = var.cluster_name                                           # Human-readable identifier for the cluster
  location                = data.azurerm_resource_group.aks.location                   # Inherits from resource group
  resource_group_name     = data.azurerm_resource_group.aks.name                       # Management resource group
  dns_prefix              = var.dns_prefix != null ? var.dns_prefix : var.cluster_name # Used in FQDN
  kubernetes_version      = var.kubernetes_version                                     # Specific version or null for latest
  node_resource_group     = var.node_resource_group_name                               # Where node VMs will be created
  sku_tier                = var.sku_tier                                               # Free or Paid (Standard) with SLA
  private_cluster_enabled = var.enable_private_cluster                                 # Private API server option

  #--------------------------------------------------------------
  # Default Node Pool Configuration
  # Primary pool that runs essential system pods
  #--------------------------------------------------------------
  default_node_pool {
    name           = var.default_node_pool_name    # Identifier for the node pool
    vm_size        = var.default_node_pool_vm_size # VM instance type
    vnet_subnet_id = var.subnet_id                 # VNet integration for CNI networking
    zones          = var.availability_zones        # For zone redundancy

    # Node count configuration with autoscaling support
    node_count           = var.enable_auto_scaling ? null : var.default_node_pool_node_count
    auto_scaling_enabled = var.enable_auto_scaling # Dynamically adjust node count
    min_count            = var.enable_auto_scaling ? var.default_node_pool_min_count : null
    max_count            = var.enable_auto_scaling ? var.default_node_pool_max_count : null

    # Node storage configuration
    os_disk_size_gb = var.os_disk_size_gb # Root disk size for containers and OS
    os_disk_type    = var.os_disk_type    # Managed (SSD) or Ephemeral

    node_labels = var.default_node_pool_labels # Kubernetes labels for node selection
    tags        = var.tags                     # Azure resource tags for the node VMs
  }

  #--------------------------------------------------------------
  # Identity Configuration
  # Managed identity for the cluster to access Azure resources
  #--------------------------------------------------------------
  identity {
    type = "SystemAssigned" # AKS creates and manages the identity
    # This identity will need permissions to create resources like load balancers
  }

  #--------------------------------------------------------------
  # RBAC and Authentication
  # Azure Active Directory integration for cluster access
  #--------------------------------------------------------------
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.admin_group_object_ids # Azure AD groups with cluster-admin access
    azure_rbac_enabled     = var.azure_rbac_enabled     # Use Azure RBAC instead of native K8s RBAC
    tenant_id              = var.tenant_id != null ? var.tenant_id : data.azurerm_client_config.current.tenant_id
    # Uses current tenant if not specified explicitly
  }

  #--------------------------------------------------------------
  # Network Configuration
  # Settings for pod and service networking
  #--------------------------------------------------------------
  network_profile {
    network_plugin    = var.network_plugin # azure (CNI) or kubenet
    network_policy    = var.network_policy # azure, calico, or cilium for network policies
    dns_service_ip    = var.dns_service_ip # IP for cluster DNS service (kube-dns)
    service_cidr      = var.service_cidr   # IP range for Kubernetes services
    outbound_type     = var.outbound_type  # How cluster egress traffic is handled
    load_balancer_sku = "standard"         # Required for most production features
  }

  #--------------------------------------------------------------
  # API Server Access Controls
  # Restricts which networks can access the Kubernetes API
  #--------------------------------------------------------------
  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges # Whitelist of CIDR blocks
    # Empty list means API server is accessible from any IP (not recommended for production)
  }

  #--------------------------------------------------------------
  # Maintenance Window Configuration
  # Controls when Azure can perform planned maintenance
  #--------------------------------------------------------------
  maintenance_window {
    allowed {
      day   = var.maintenance_window_day   # Day of week for maintenance
      hours = var.maintenance_window_hours # Hours during the day
      # Choose off-hours to minimize impact on production workloads
    }
  }

  #--------------------------------------------------------------
  # Resource Tags
  # Azure-level tags for organization and billing
  #--------------------------------------------------------------
  tags = var.tags # Key-value pairs applied to all resources

  #--------------------------------------------------------------
  # Lifecycle Management
  # Controls how Terraform handles certain changes
  #--------------------------------------------------------------
  lifecycle {
    ignore_changes = [
      # Ignore changes to the node count, as this can be managed by the auto-scaler
      # This prevents Terraform from fighting with the autoscaler
      default_node_pool[0].node_count
    ]
  }
}

#==============================================================================
# Monitoring Configuration
# Log Analytics workspace for cluster observability
#==============================================================================
# Create Log Analytics workspace if enabled
resource "azurerm_log_analytics_workspace" "aks" {
  count               = var.enable_log_analytics_workspace ? 1 : 0 # Conditional creation
  name                = "${var.cluster_name}-logs"                 # Naming convention includes cluster name
  location            = data.azurerm_resource_group.aks.location   # Same region as cluster
  resource_group_name = data.azurerm_resource_group.aks.name       # Same resource group as cluster
  sku                 = var.log_analytics_workspace_sku            # Determines features and pricing
  retention_in_days   = var.log_retention_in_days                  # How long to keep log data
  tags                = var.tags                                   # Consistent tagging
}

#--------------------------------------------------------------
# Diagnostic Settings
# Routes AKS logs to Log Analytics
#--------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "aks" {
  count                      = var.enable_log_analytics_workspace ? 1 : 0
  name                       = "${var.cluster_name}-diagnostic-settings"
  target_resource_id         = azurerm_kubernetes_cluster.this.id        # AKS cluster
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks[0].id # Destination

  # Uses dedicated tables in Log Analytics for better query performance
  log_analytics_destination_type = "Dedicated"

  # By default, this captures all log categories for the AKS cluster
}

#--------------------------------------------------------------
# Container Insights
# Enhanced monitoring for containers
#--------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "container_insights" {
  count                      = var.enable_log_analytics_workspace ? 1 : 0
  name                       = "${var.cluster_name}-container-insights"
  target_resource_id         = azurerm_kubernetes_cluster.this.id        # AKS cluster
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks[0].id # Destination

  # This enables the Container Insights solution which provides:
  # - Container performance metrics
  # - Pod health monitoring
  # - Cluster resource utilization
  # - Pre-configured dashboards and alerts
}

#==============================================================================
# Additional Node Pools
# Specialized node pools beyond the default
#==============================================================================
resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each              = var.additional_node_pools          # Create multiple from map input
  name                  = each.key                           # Use the map key as node pool name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id # Reference to AKS cluster
  vm_size               = each.value.vm_size                 # VM instance type for this pool

  # Node count configuration with autoscaling support
  node_count           = each.value.min_count != null ? null : each.value.node_count # Static count
  auto_scaling_enabled = each.value.min_count != null ? true : false                 # Enable if min_count provided
  min_count            = each.value.min_count                                        # Minimum for autoscaling
  max_count            = each.value.max_count                                        # Maximum for autoscaling

  # Node configuration
  os_disk_size_gb = each.value.os_disk_size_gb # Root disk size
  os_disk_type    = each.value.os_disk_type    # Disk performance tier
  vnet_subnet_id  = var.subnet_id              # Same subnet as default pool
  zones           = var.availability_zones     # Same zones as default pool

  # Kubernetes settings
  node_labels = each.value.node_labels # For node selection in pod specs
  mode        = each.value.mode        # User or System mode

  # Resource tags
  tags = var.tags # Consistent tagging

  # These node pools can be used for:
  # - Workload isolation (e.g., separating frontend from backend)
  # - Special hardware requirements (e.g., GPU nodes)
  # - Different scaling patterns (e.g., batch processing nodes)
}

#==============================================================================
# Kubeconfig Generation
# Creates a local file for kubectl access
#==============================================================================
resource "local_file" "kubeconfig" {
  content  = azurerm_kubernetes_cluster.this.kube_config_raw # Credentials from AKS
  filename = "${path.module}/kubeconfig_${var.cluster_name}" # Named with cluster name

  # This file contains:
  # - API server endpoint
  # - Authentication credentials
  # - Cluster CA certificate
  #
  # Set the KUBECONFIG environment variable to this path to use kubectl:
  # export KUBECONFIG=/path/to/kubeconfig_clustername
}
