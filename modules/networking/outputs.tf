#-----------------------------------------------------------------------------
# Cloud-Agnostic Networking Outputs
#
# This file defines the outputs from the networking module that can be used 
# by other modules or the root module. It provides both cloud-agnostic outputs
# (that work across all supported providers) and cloud-specific outputs for
# when you need provider-specific resource identifiers.
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# CLOUD-AGNOSTIC OUTPUTS
# These outputs provide a consistent interface regardless of which cloud
# provider is being used (AWS, Azure, or GCP).
#-----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC/VNet. This is the primary identifier for the network and can be used when creating resources that need to be placed in this network."
  value = local.is_aws ? aws_vpc.this[0].id : (
    local.is_azure ? azurerm_virtual_network.this[0].id : (
      local.is_gcp ? google_compute_network.this[0].id : null
    )
  )
}

output "vpc_name" {
  description = "Name of the VPC/VNet. Useful for display purposes and when resources require the network name rather than ID."
  value = local.is_aws ? aws_vpc.this[0].tags.Name : (
    local.is_azure ? azurerm_virtual_network.this[0].name : (
      local.is_gcp ? google_compute_network.this[0].name : null
    )
  )
}

output "vpc_cidr" {
  description = "CIDR block of the VPC/VNet, representing the IP address range for the entire network. Note: In GCP, VPCs don't have a single CIDR block like AWS and Azure."
  value = local.is_aws ? aws_vpc.this[0].cidr_block : (
    local.is_azure ? azurerm_virtual_network.this[0].address_space[0] : (
      local.is_gcp ? "N/A - GCP doesn't have a VPC CIDR" : null
    )
  )
}

output "subnet_ids" {
  description = "List of subnet IDs created in the network. These IDs are necessary when creating resources that must be placed in specific subnets."
  value = local.is_aws ? aws_subnet.this[*].id : (
    local.is_azure ? azurerm_subnet.this[*].id : (
      local.is_gcp ? google_compute_subnetwork.this[*].id : null
    )
  )
}

output "subnet_cidrs" {
  description = "List of subnet CIDR blocks showing the IP address ranges of each subnet. Useful for network planning and documentation."
  value = local.is_aws ? aws_subnet.this[*].cidr_block : (
    local.is_azure ? azurerm_subnet.this[*].address_prefixes[0] : (
      local.is_gcp ? google_compute_subnetwork.this[*].ip_cidr_range : null
    )
  )
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (subnets with direct internet access). Use these for resources that need to be publicly accessible, like load balancers."
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
  description = "List of private subnet IDs (subnets without direct internet access). Use these for resources that should not be directly accessible from the internet, like application servers and databases."
  value = [
    for idx in var.private_subnet_indices : 
    local.is_aws ? aws_subnet.this[idx].id : (
      local.is_azure ? azurerm_subnet.this[idx].id : (
        local.is_gcp ? google_compute_subnetwork.this[idx].id : null
      )
    )
  ]
}

#-----------------------------------------------------------------------------
# AWS-SPECIFIC OUTPUTS
# These outputs are only meaningful when deploying to AWS
#-----------------------------------------------------------------------------

output "aws_vpc_id" {
  description = "ID of the AWS VPC (only for AWS). Use this when you need to reference the VPC in AWS-specific resources or modules."
  value = local.is_aws ? aws_vpc.this[0].id : null
}

output "aws_internet_gateway_id" {
  description = "ID of the AWS Internet Gateway (only for AWS). The gateway that enables internet connectivity for public subnets."
  value = local.is_aws && var.create_internet_gateway ? aws_internet_gateway.this[0].id : null
}

output "aws_nat_gateway_id" {
  description = "ID of the AWS NAT Gateway (only for AWS). The gateway that allows instances in private subnets to access the internet."
  value = local.is_aws && var.create_nat_gateway ? aws_nat_gateway.this[0].id : null
}

output "aws_security_group_id" {
  description = "ID of the AWS Security Group (only for AWS). The base security group created for the VPC, which can be used as a default for resources."
  value = local.is_aws ? aws_security_group.this[0].id : null
}

#-----------------------------------------------------------------------------
# AZURE-SPECIFIC OUTPUTS
# These outputs are only meaningful when deploying to Azure
#-----------------------------------------------------------------------------

output "azure_resource_group_name" {
  description = "Name of the Azure Resource Group (only for Azure). The container for all Azure networking resources created by this module."
  value = local.is_azure ? azurerm_resource_group.this[0].name : null
}

output "azure_vnet_id" {
  description = "ID of the Azure VNet (only for Azure). Use this when you need to reference the VNet in Azure-specific resources or modules."
  value = local.is_azure ? azurerm_virtual_network.this[0].id : null
}

output "azure_nat_gateway_id" {
  description = "ID of the Azure NAT Gateway (only for Azure). The gateway that allows instances in private subnets to access the internet."
  value = local.is_azure && var.create_nat_gateway ? azurerm_nat_gateway.this[0].id : null
}

output "azure_network_security_group_id" {
  description = "ID of the Azure Network Security Group (only for Azure). The security group that controls inbound and outbound traffic for the network."
  value = local.is_azure ? azurerm_network_security_group.this[0].id : null
}

#-----------------------------------------------------------------------------
# GCP-SPECIFIC OUTPUTS
# These outputs are only meaningful when deploying to Google Cloud Platform
#-----------------------------------------------------------------------------

output "gcp_network_id" {
  description = "ID of the GCP VPC (only for GCP). Use this when you need to reference the VPC in GCP-specific resources or modules."
  value = local.is_gcp ? google_compute_network.this[0].id : null
}

output "gcp_network_name" {
  description = "Name of the GCP VPC (only for GCP). In GCP, many resources reference the network by name rather than ID."
  value = local.is_gcp ? google_compute_network.this[0].name : null
}

output "gcp_router_nat_name" {
  description = "Name of the GCP Cloud NAT (only for GCP). The NAT service that allows instances in private subnets to access the internet."
  value = local.is_gcp && var.create_nat_gateway ? google_compute_router_nat.this[0].name : null
}