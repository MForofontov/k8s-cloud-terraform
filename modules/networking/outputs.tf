#------------------------------------------------------------------------------
# Cloud-Agnostic Networking Module Outputs
#
# This file defines the output values of the Networking module, providing
# a consistent interface across AWS, Azure, and GCP.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Common Outputs
# These outputs are available regardless of cloud provider
#------------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC/VNet"
  value       = local.is_aws ? aws_vpc.this[0].id : (
                local.is_azure ? azurerm_virtual_network.this[0].id : (
                local.is_gcp ? google_compute_network.this[0].id : null
                ))
}

output "vpc_name" {
  description = "Name of the VPC/VNet"
  value       = local.vpc_name
}

output "vpc_cidr" {
  description = "CIDR block of the VPC/VNet"
  value       = local.vpc_cidr
}

output "subnet_ids" {
  description = "List of subnet IDs, in the same order as subnet_cidrs"
  value       = local.is_aws ? aws_subnet.this[*].id : (
                local.is_azure ? azurerm_subnet.this[*].id : (
                local.is_gcp ? google_compute_subnetwork.this[*].id : null
                ))
}

output "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  value       = local.subnet_cidrs
}

output "subnet_names" {
  description = "List of subnet names"
  value       = local.subnet_names
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for idx in local.public_subnet_indices :
                local.is_aws ? aws_subnet.this[idx].id : (
                local.is_azure ? azurerm_subnet.this[idx].id : (
                local.is_gcp ? google_compute_subnetwork.this[idx].id : null
                ))]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for idx in local.private_subnet_indices :
                local.is_aws ? aws_subnet.this[idx].id : (
                local.is_azure ? azurerm_subnet.this[idx].id : (
                local.is_gcp ? google_compute_subnetwork.this[idx].id : null
                ))]
}

output "nat_gateway_enabled" {
  description = "Whether NAT Gateway is enabled"
  value       = var.create_nat_gateway
}

output "ipv6_enabled" {
  description = "Whether IPv6 is enabled"
  value       = var.enable_ipv6
}

#------------------------------------------------------------------------------
# AWS Specific Outputs
#------------------------------------------------------------------------------
output "aws_vpc_id" {
  description = "ID of the AWS VPC"
  value       = local.is_aws ? aws_vpc.this[0].id : null
}

output "aws_vpc_ipv6_cidr" {
  description = "IPv6 CIDR block of the AWS VPC"
  value       = local.is_aws && var.enable_ipv6 ? aws_vpc.this[0].ipv6_cidr_block : null
}

output "aws_internet_gateway_id" {
  description = "ID of the AWS Internet Gateway"
  value       = local.is_aws && var.create_internet_gateway ? aws_internet_gateway.this[0].id : null
}

output "aws_nat_gateway_ids" {
  description = "IDs of the AWS NAT Gateways"
  value       = local.is_aws && var.create_nat_gateway ? aws_nat_gateway.this[*].id : null
}

output "aws_public_route_table_id" {
  description = "ID of the AWS public route table"
  value       = local.is_aws && var.create_internet_gateway ? aws_route_table.public[0].id : null
}

output "aws_private_route_table_ids" {
  description = "IDs of the AWS private route tables"
  value       = local.is_aws && var.create_nat_gateway ? aws_route_table.private[*].id : null
}

output "aws_security_group_id" {
  description = "ID of the AWS security group"
  value       = local.is_aws ? aws_security_group.this[0].id : null
}

output "aws_vpc_endpoint_ids" {
  description = "Map of AWS VPC endpoint IDs"
  value       = local.is_aws && var.enable_service_endpoints ? {
    for k, v in local.aws_vpc_endpoints : k => v.service_type == "Gateway" ?
      aws_vpc_endpoint.gateway[k].id : aws_vpc_endpoint.interface[k].id
  } : null
}

output "aws_flow_log_id" {
  description = "ID of the AWS VPC flow log"
  value       = local.is_aws && var.enable_flow_logs ? aws_flow_log.this[0].id : null
}

#------------------------------------------------------------------------------
# Azure Specific Outputs
#------------------------------------------------------------------------------
output "azure_resource_group_name" {
  description = "Name of the Azure resource group"
  value       = local.is_azure ? azurerm_resource_group.this[0].name : null
}

output "azure_vnet_id" {
  description = "ID of the Azure virtual network"
  value       = local.is_azure ? azurerm_virtual_network.this[0].id : null
}

output "azure_vnet_name" {
  description = "Name of the Azure virtual network"
  value       = local.is_azure ? azurerm_virtual_network.this[0].name : null
}

output "azure_nat_gateway_ids" {
  description = "IDs of the Azure NAT Gateways"
  value       = local.is_azure && var.create_nat_gateway ? azurerm_nat_gateway.this[*].id : null
}

output "azure_network_security_group_id" {
  description = "ID of the Azure network security group"
  value       = local.is_azure ? azurerm_network_security_group.this[0].id : null
}

output "azure_network_security_group_name" {
  description = "Name of the Azure network security group"
  value       = local.is_azure ? azurerm_network_security_group.this[0].name : null
}

output "azure_flow_log_id" {
  description = "ID of the Azure network watcher flow log"
  value       = local.is_azure && var.enable_flow_logs ? azurerm_network_watcher_flow_log.this[0].id : null
}

#------------------------------------------------------------------------------
# GCP Specific Outputs
#------------------------------------------------------------------------------
output "gcp_network_id" {
  description = "ID of the GCP VPC network"
  value       = local.is_gcp ? google_compute_network.this[0].id : null
}

output "gcp_network_name" {
  description = "Name of the GCP VPC network"
  value       = local.is_gcp ? google_compute_network.this[0].name : null
}

output "gcp_subnetwork_ids" {
  description = "IDs of the GCP subnetworks"
  value       = local.is_gcp ? google_compute_subnetwork.this[*].id : null
}

output "gcp_router_ids" {
  description = "IDs of the GCP Cloud Routers"
  value       = local.is_gcp && var.create_nat_gateway ? google_compute_router.this[*].id : null
}

output "gcp_nat_ids" {
  description = "IDs of the GCP Cloud NAT gateways"
  value       = local.is_gcp && var.create_nat_gateway ? google_compute_router_nat.this[*].id : null
}

output "gcp_service_networking_connection_id" {
  description = "ID of the GCP Service Networking connection for private services"
  value       = local.is_gcp && var.enable_service_endpoints ? google_service_networking_connection.private_vpc_connection[0].id : null
}

output "gcp_vpc_service_controls_perimeter_name" {
  description = "Name of the GCP VPC Service Controls perimeter"
  value       = local.is_gcp && var.gcp_enable_vpc_service_controls ? google_access_context_manager_service_perimeter.vpc_sc[0].name : null
}

#------------------------------------------------------------------------------
# Kubernetes Specific Outputs
# Formatted for direct use with Kubernetes clusters
#------------------------------------------------------------------------------
output "k8s_network_config" {
  description = "Network configuration for Kubernetes cluster creation"
  value = {
    vpc_id           = local.is_aws ? aws_vpc.this[0].id : (
                       local.is_azure ? azurerm_virtual_network.this[0].id : (
                       local.is_gcp ? google_compute_network.this[0].id : null
                       ))
    subnet_ids       = local.is_aws ? aws_subnet.this[*].id : (
                       local.is_azure ? azurerm_subnet.this[*].id : (
                       local.is_gcp ? google_compute_subnetwork.this[*].id : null
                       ))
    public_subnets   = [for idx in local.public_subnet_indices :
                       local.is_aws ? aws_subnet.this[idx].id : (
                       local.is_azure ? azurerm_subnet.this[idx].id : (
                       local.is_gcp ? google_compute_subnetwork.this[idx].id : null
                       ))]
    private_subnets  = [for idx in local.private_subnet_indices :
                       local.is_aws ? aws_subnet.this[idx].id : (
                       local.is_azure ? azurerm_subnet.this[idx].id : (
                       local.is_gcp ? google_compute_subnetwork.this[idx].id : null
                       ))]
    pod_cidr         = var.vpc_cidr != null ? cidrsubnet(var.vpc_cidr, 8, 16) : "10.0.16.0/20"
    service_cidr     = var.vpc_cidr != null ? cidrsubnet(var.vpc_cidr, 8, 17) : "10.0.17.0/24"
    cluster_endpoint_public_access = var.create_internet_gateway
    cluster_endpoint_private_access = true
    resource_group_name = local.is_azure ? azurerm_resource_group.this[0].name : null
    security_group_id   = local.is_aws ? aws_security_group.this[0].id : null
    network_security_group_id = local.is_azure ? azurerm_network_security_group.this[0].id : null
  }
}