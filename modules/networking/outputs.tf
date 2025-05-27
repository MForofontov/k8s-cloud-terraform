# Cloud-Agnostic Networking Outputs

# Generic outputs with provider-specific implementations
output "vpc_id" {
  description = "ID of the VPC/VNet"
  value = local.is_aws ? aws_vpc.this[0].id : (
    local.is_azure ? azurerm_virtual_network.this[0].id : (
      local.is_gcp ? google_compute_network.this[0].id : null
    )
  )
}

output "vpc_name" {
  description = "Name of the VPC/VNet"
  value = local.is_aws ? aws_vpc.this[0].tags.Name : (
    local.is_azure ? azurerm_virtual_network.this[0].name : (
      local.is_gcp ? google_compute_network.this[0].name : null
    )
  )
}

output "vpc_cidr" {
  description = "CIDR block of the VPC/VNet"
  value = local.is_aws ? aws_vpc.this[0].cidr_block : (
    local.is_azure ? azurerm_virtual_network.this[0].address_space[0] : (
      local.is_gcp ? "N/A - GCP doesn't have a VPC CIDR" : null
    )
  )
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value = local.is_aws ? aws_subnet.this[*].id : (
    local.is_azure ? azurerm_subnet.this[*].id : (
      local.is_gcp ? google_compute_subnetwork.this[*].id : null
    )
  )
}

output "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  value = local.is_aws ? aws_subnet.this[*].cidr_block : (
    local.is_azure ? azurerm_subnet.this[*].address_prefixes[0] : (
      local.is_gcp ? google_compute_subnetwork.this[*].ip_cidr_range : null
    )
  )
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [
    for idx in var.public_subnet_indices : 
    local.is_aws ? aws_subnet.this[idx].id : (
      local.is_azure ? azurerm_subnet.this[idx].id : (
        local.is_gcp ? google_compute_subnetwork.this[idx].id : null
      )
    )
  ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [
    for idx in var.private_subnet_indices : 
    local.is_aws ? aws_subnet.this[idx].id : (
      local.is_azure ? azurerm_subnet.this[idx].id : (
        local.is_gcp ? google_compute_subnetwork.this[idx].id : null
      )
    )
  ]
}

# Provider-specific outputs
output "aws_vpc_id" {
  description = "ID of the AWS VPC (only for AWS)"
  value = local.is_aws ? aws_vpc.this[0].id : null
}

output "aws_internet_gateway_id" {
  description = "ID of the AWS Internet Gateway (only for AWS)"
  value = local.is_aws && var.create_internet_gateway ? aws_internet_gateway.this[0].id : null
}

output "aws_nat_gateway_id" {
  description = "ID of the AWS NAT Gateway (only for AWS)"
  value = local.is_aws && var.create_nat_gateway ? aws_nat_gateway.this[0].id : null
}

output "aws_security_group_id" {
  description = "ID of the AWS Security Group (only for AWS)"
  value = local.is_aws ? aws_security_group.this[0].id : null
}

output "azure_resource_group_name" {
  description = "Name of the Azure Resource Group (only for Azure)"
  value = local.is_azure ? azurerm_resource_group.this[0].name : null
}

output "azure_vnet_id" {
  description = "ID of the Azure VNet (only for Azure)"
  value = local.is_azure ? azurerm_virtual_network.this[0].id : null
}

output "azure_nat_gateway_id" {
  description = "ID of the Azure NAT Gateway (only for Azure)"
  value = local.is_azure && var.create_nat_gateway ? azurerm_nat_gateway.this[0].id : null
}

output "azure_network_security_group_id" {
  description = "ID of the Azure Network Security Group (only for Azure)"
  value = local.is_azure ? azurerm_network_security_group.this[0].id : null
}

output "gcp_network_id" {
  description = "ID of the GCP VPC (only for GCP)"
  value = local.is_gcp ? google_compute_network.this[0].id : null
}

output "gcp_network_name" {
  description = "Name of the GCP VPC (only for GCP)"
  value = local.is_gcp ? google_compute_network.this[0].name : null
}

output "gcp_router_nat_name" {
  description = "Name of the GCP Cloud NAT (only for GCP)"
  value = local.is_gcp && var.create_nat_gateway ? google_compute_router_nat.this[0].name : null
}