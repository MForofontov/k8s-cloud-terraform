# Cloud-Agnostic Networking Terraform Module

A comprehensive Terraform module to provision networking infrastructure across multiple cloud providers (AWS, Azure, and GCP) using a consistent interface. This module enables you to deploy similar networking topologies on different cloud platforms with minimal configuration changes.

## Features

- **Multi-cloud support**: Deploy to AWS, Azure, or GCP using the same module
- **VPC/VNet creation**: Provision the fundamental networking container for your cloud resources
- **Subnet configuration**: Create multiple subnets with customizable CIDR ranges
- **Public/private subnet support**: Designate which subnets should have direct internet access
- **Internet connectivity**: Configure internet gateways for public subnet access
- **NAT gateways**: Enable outbound internet access for private subnets
- **Security groups/firewall rules**: Basic security configuration for network traffic
- **Sensible defaults**: Automatic CIDR calculation if not explicitly provided
- **Custom naming**: Flexible resource naming with defaults

## Usage

### AWS Example

```hcl
module "network" {
  source = "github.com/your-organization/k8s-cloud-terraform//networking"

  cloud_provider = "aws"
  name_prefix    = "prod"
  vpc_cidr       = "10.0.0.0/16"
  
  availability_zones     = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  create_nat_gateway     = true
  create_internet_gateway = true
  
  tags = {
    Environment = "Production"
    Terraform   = "true"
  }
}
```

### Azure Example

```hcl
module "network" {
  source = "github.com/your-organization/k8s-cloud-terraform//networking"

  cloud_provider = "azure"
  name_prefix    = "prod"
  vpc_cidr       = "10.0.0.0/16"
  azure_location = "eastus2"
  
  # Optional: provide explicit subnet definitions
  subnet_cidrs = [
    "10.0.0.0/24",
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
  
  subnet_names = [
    "prod-public-1",
    "prod-public-2",
    "prod-private-1",
    "prod-private-2"
  ]
  
  tags = {
    Environment = "Production"
    Terraform   = "true"
  }
}
```

### GCP Example

```hcl
module "network" {
  source = "github.com/your-organization/k8s-cloud-terraform//networking"

  cloud_provider = "gcp"
  name_prefix    = "prod"
  vpc_cidr       = "10.0.0.0/16"
  
  gcp_project_id = "my-gcp-project"
  gcp_region     = "us-central1"
  
  tags = {
    environment = "production"
    terraform   = "true"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | ~> 5.50.0 |
| azurerm | ~> 3.95.0 |
| google | ~> 5.20.0 |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| cloud_provider | The cloud provider to deploy to (aws, azure, gcp) | `string` |

### Common Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| name_prefix | Prefix to use for naming resources | `string` | `"k8s"` |
| vpc_name | Name of the VPC/VNet (defaults to `{name_prefix}-vpc`) | `string` | `null` |
| vpc_cidr | CIDR block for the VPC/VNet | `string` | `"10.0.0.0/16"` |
| subnet_cidrs | List of CIDR blocks for subnets | `list(string)` | `null` (auto-calculated) |
| subnet_names | List of names for subnets | `list(string)` | `null` (auto-generated) |
| public_subnet_indices | List of indices that should be public subnets | `list(number)` | `[0, 1]` |
| private_subnet_indices | List of indices that should be private subnets | `list(number)` | `[2, 3]` |
| create_internet_gateway | Whether to create an Internet Gateway | `bool` | `true` |
| create_nat_gateway | Whether to create a NAT Gateway | `bool` | `true` |
| tags | Tags to apply to all resources | `map(string)` | `{}` |

### AWS Specific Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| availability_zones | List of availability zones to use for AWS subnets | `list(string)` | `[]` |

### Azure Specific Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| azure_location | Azure region to deploy resources to | `string` | `"eastus"` |

### GCP Specific Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| gcp_project_id | GCP project ID | `string` | `null` |
| gcp_region | GCP region to deploy resources to | `string` | `"us-central1"` |

## Outputs

### Common Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC/VNet |
| vpc_name | Name of the VPC/VNet |
| vpc_cidr | CIDR block of the VPC/VNet |
| subnet_ids | List of subnet IDs |
| subnet_cidrs | List of subnet CIDR blocks |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |

### AWS Specific Outputs

| Name | Description |
|------|-------------|
| aws_vpc_id | ID of the AWS VPC |
| aws_internet_gateway_id | ID of the AWS Internet Gateway |
| aws_nat_gateway_id | ID of the AWS NAT Gateway |
| aws_security_group_id | ID of the AWS Security Group |

### Azure Specific Outputs

| Name | Description |
|------|-------------|
| azure_resource_group_name | Name of the Azure Resource Group |
| azure_vnet_id | ID of the Azure VNet |
| azure_nat_gateway_id | ID of the Azure NAT Gateway |
| azure_network_security_group_id | ID of the Azure Network Security Group |

### GCP Specific Outputs

| Name | Description |
|------|-------------|
| gcp_network_id | ID of the GCP VPC |
| gcp_network_name | Name of the GCP VPC |
| gcp_router_nat_name | Name of the GCP Cloud NAT |

## Architecture

This module creates the following resources based on the cloud provider:

### AWS
- VPC with DNS support and hostnames
- Public and private subnets across availability zones
- Internet Gateway for public internet access
- NAT Gateway for private subnet outbound traffic
- Route tables for both public and private subnets
- Security group with basic egress rules

### Azure
- Resource Group to contain all networking resources
- Virtual Network with custom address space
- Multiple subnets with configurable address prefixes
- NAT Gateway for private subnet outbound traffic
- Network Security Group with basic outbound rules

### GCP
- VPC Network with custom subnetworks mode
- Multiple subnetworks with custom IP ranges
- Cloud Router for dynamic routing
- Cloud NAT for private subnet outbound traffic
- Firewall rules for basic egress traffic

## License

MIT