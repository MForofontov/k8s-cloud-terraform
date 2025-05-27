# Enterprise Multi-Cloud Networking Module

This Terraform module creates enterprise-grade networking infrastructure across AWS, Azure, and GCP with a consistent interface. It provides the foundation for Kubernetes deployments while maintaining a uniform API for multi-cloud environments.

## Features

- Cross-Cloud Compatible: Works with AWS, Azure, and GCP through a unified interface
- Kubernetes-Optimized: Network architecture designed for Kubernetes workloads
- Production-Ready: Secure, scalable network foundation with intelligent defaults
- Public/Private Subnets: Proper isolation of workloads with controlled internet access
- Smart CIDR Management: Automatic subnet calculation or explicit configuration
- Advanced Security: Defense-in-depth approach with multiple security controls
- High Availability: Support for multi-AZ deployments and redundant components

## Supported Features

| Feature | AWS | Azure | GCP | Description |
|---------|-----|-------|-----|-------------|
| **VPC/VNet** | ✅ | ✅ | ✅ | Core virtual network with custom CIDR blocks |
| **Subnets** | ✅ | ✅ | ✅ | Public and private subnet architecture |
| **NAT Gateway** | ✅ | ✅ | ✅ | Outbound internet access for private subnets |
| **Internet Gateway** | ✅ | ✅ | ✅ | Inbound/outbound internet access for public subnets |
| **Security Groups** | ✅ | ✅ | ✅ | Network traffic filtering with least-privilege rules |
| **Flow Log** | ✅ | ✅ | ✅ | Network traffic analysis and troubleshooting |
| **Service Endpoints** | ✅ | ✅ | ✅ | Private access to cloud provider services |
| **IPv6 Support** | ✅ | ✅ | ✅ | Dual-stack networking capabilities |
| **DDoS Protection** | ❌ | ✅ | ❌ | Azure DDoS Protection Plan integration |
| **VPC Service Controls** | ❌ | ❌ | ✅ | GCP enterprise security boundary enforcement |

## Usage

```hcl
module "network" {
  source         = "github.com/your-organization/k8s-cloud-terraform//modules/networking"
  cloud_provider = "aws"
  name_prefix    = "prod"
  vpc_cidr       = "10.0.0.0/16"
  
  # High-availability configuration
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  single_nat_gateway = false  # Create a NAT gateway in each AZ for high availability
  
  # Enable security and compliance features
  enable_flow_logs        = true
  enable_service_endpoints = true
  
  tags = {
    Environment  = "Production"
    Terraform    = "true"
    CostCenter   = "Platform"
    BusinessUnit = "Engineering"
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

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloud_provider | Cloud provider to use (aws, azure, gcp) | string | n/a | yes |
| name_prefix | Prefix for all resource names | string | n/a | yes |
| vpc_cidr | CIDR block for the VPC/VNet | string | "10.0.0.0/16" | no |
| enable_flow_logs | Enable network flow logs | bool | false | no |
| flow_logs_retention_days | Days to retain flow logs | number | 30 | no |
| enable_service_endpoints | Enable private service endpoints | bool | false | no |
| enable_ipv6 | Enable IPv6 support | bool | false | no |
| single_nat_gateway | Use single NAT instead of per-AZ NATs | bool | true | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Output Variables

| Name | Description |
|------|-------------|
| vpc_id | ID of the created VPC/VNet |
| vpc_cidr | CIDR block of the VPC/VNet |
| subnet_ids | List of all subnet IDs |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| nat_gateway_ids | List of NAT Gateway IDs |
| security_group_id | ID of the main security group |

## Example

### AWS Example

```hcl
module "network" {
  source         = "github.com/your-organization/k8s-cloud-terraform//modules/networking"
  cloud_provider = "aws"
  name_prefix    = "prod"
  vpc_cidr       = "10.0.0.0/16"
  
  # High-availability configuration
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  single_nat_gateway = false  # Create a NAT gateway in each AZ for high availability
  
  # Enable security and compliance features
  enable_flow_logs        = true
  enable_service_endpoints = true
  
  tags = {
    Environment  = "Production"
    Terraform    = "true"
    CostCenter   = "Platform"
    BusinessUnit = "Engineering"
  }
}
```

### Azure Example

```hcl
module "network" {
  source         = "github.com/your-organization/k8s-cloud-terraform//modules/networking"
  cloud_provider = "azure"
  name_prefix    = "prod"
  vpc_cidr       = "10.0.0.0/16"
  azure_location = "eastus2"
  
  # Enable IPv6 support
  enable_ipv6 = true
  
  # Enable enterprise security features
  azure_enable_ddos_protection = true
  enable_flow_logs = true
  flow_logs_retention_days = 90
  
  # Configure Azure service endpoints for enhanced security
  enable_service_endpoints = true
  azure_service_endpoints = [
    "Microsoft.Storage", 
    "Microsoft.KeyVault", 
    "Microsoft.ContainerRegistry",
    "Microsoft.AzureCosmosDB",
    "Microsoft.Sql"
  ]
  
  # Optional: provide explicit subnet definitions
  subnet_cidrs = [
    "10.0.0.0/24",  # Public subnet 1
    "10.0.1.0/24",  # Public subnet 2
    "10.0.2.0/24",  # Private subnet 1
    "10.0.3.0/24",  # Private subnet 2
    "10.0.4.0/24",  # Private subnet 3 (for database workloads)
  ]
  
  subnet_names = [
    "prod-public-1",
    "prod-public-2",
    "prod-private-app-1",
    "prod-private-app-2",
    "prod-private-data"
  ]
  
  tags = {
    Environment  = "Production"
    Terraform    = "true"
    CostCenter   = "Platform"
  }
}
```

### GCP Example

```hcl
module "network" {
  source         = "github.com/your-organization/k8s-cloud-terraform//modules/networking"
  cloud_provider = "gcp"
  name_prefix    = "prod"
  vpc_cidr       = "10.0.0.0/16"
  
  # GCP project configuration
  gcp_project_id     = "my-enterprise-project"
  gcp_project_number = "123456789012"
  gcp_region         = "us-central1"
  
  # Global routing enables cross-region networking
  gcp_routing_mode   = "GLOBAL"
  
  # Enable VPC Service Controls for enterprise security
  gcp_enable_vpc_service_controls = true
  gcp_access_policy_id = "access-policy-id"
  gcp_restricted_services = [
    "storage.googleapis.com", 
    "bigquery.googleapis.com",
    "container.googleapis.com"
  ]
  
  # Enable private service access
  enable_service_endpoints = true
  
  # Enable flow logging
  enable_flow_logs = true
  
  tags = {
    environment = "production"
    terraform   = "true"
    team        = "platform"
    application = "kubernetes"
  }
}
```

## License

This module is released under the MIT License.