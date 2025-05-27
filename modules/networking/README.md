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

### Core Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloud_provider | Cloud provider to use (aws, azure, gcp) | string | n/a | yes |
| name_prefix | Prefix for all resource names | string | n/a | yes |
| vpc_cidr | CIDR block for the VPC/VNet | string | "10.0.0.0/16" | no |
| subnet_cidrs | List of CIDR blocks for subnets | list(string) | null | no |
| subnet_names | List of subnet names | list(string) | null | no |
| public_subnet_indices | List of subnet indices that should be treated as public | list(number) | [0, 1] | no |
| private_subnet_indices | List of subnet indices that should be treated as private | list(number) | [2, 3] | no |

### Networking Features

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_internet_gateway | Whether to create an internet gateway for public subnets | bool | true | no |
| create_nat_gateway | Whether to create NAT gateway(s) for private subnets | bool | true | no |
| single_nat_gateway | Whether to use a single NAT gateway for all private subnets | bool | true | no |
| enable_ipv6 | Whether to enable IPv6 support | bool | false | no |
| enable_flow_logs | Whether to enable VPC flow logs | bool | false | no |
| flow_logs_retention_days | Number of days to retain flow logs | number | 30 | no |
| enable_service_endpoints | Whether to enable service endpoints/PrivateLink | bool | false | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

### AWS-Specific Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region where resources will be created | string | "us-west-2" | no |
| availability_zones | List of availability zones to use | list(string) | [] | no |
| aws_flow_log_traffic_type | Type of traffic to capture in flow logs | string | "ALL" | no |
| aws_endpoint_services | List of AWS service endpoints to enable | list(string) | [] | no |

### Azure-Specific Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azure_location | Azure location where resources will be created | string | "eastus" | no |
| azure_enable_ddos_protection | Whether to enable DDoS protection for Azure VNet | bool | false | no |
| azure_service_endpoints | List of Azure service endpoints to enable | list(string) | ["Microsoft.Storage", "Microsoft.KeyVault"] | no |
| azure_log_analytics_workspace_id | Azure Log Analytics workspace ID for flow logs | string | null | no |

### GCP-Specific Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| gcp_project_id | GCP project ID where resources will be created | string | null | no |
| gcp_region | GCP region where resources will be created | string | "us-central1" | no |
| gcp_routing_mode | GCP network routing mode (REGIONAL or GLOBAL) | string | "REGIONAL" | no |
| gcp_enable_vpc_service_controls | Whether to enable VPC Service Controls | bool | false | no |
| gcp_access_policy_id | GCP Access Context Manager policy ID | string | null | no |
| gcp_restricted_services | List of GCP services to restrict in perimeter | list(string) | ["storage.googleapis.com"] | no |

## Output Variables

### Common Outputs

| Name | Description | Type |
|------|-------------|------|
| vpc_id | ID of the created VPC/VNet | string |
| vpc_name | Name of the created VPC/VNet | string |
| vpc_cidr | CIDR block of the VPC/VNet | string |
| subnet_ids | List of all subnet IDs | list(string) |
| subnet_cidrs | List of all subnet CIDR blocks | list(string) |
| subnet_names | List of all subnet names | list(string) |
| public_subnet_ids | List of public subnet IDs | list(string) |
| private_subnet_ids | List of private subnet IDs | list(string) |

### AWS-Specific Outputs

| Name | Description | Type |
|------|-------------|------|
| aws_vpc_id | ID of the AWS VPC | string |
| aws_internet_gateway_id | ID of the AWS Internet Gateway | string |
| aws_nat_gateway_ids | List of AWS NAT Gateway IDs | list(string) |
| aws_route_table_ids | List of AWS Route Table IDs | list(string) |
| aws_security_group_id | ID of the AWS Security Group | string |

### Azure-Specific Outputs

| Name | Description | Type |
|------|-------------|------|
| azure_vnet_id | ID of the Azure VNet | string |
| azure_subnet_ids | List of Azure Subnet IDs | list(string) |
| azure_nat_gateway_ids | List of Azure NAT Gateway IDs | list(string) |
| azure_route_table_ids | List of Azure Route Table IDs | list(string) |
| azure_network_security_group_id | ID of the Azure Network Security Group | string |
| azure_ddos_protection_plan_id | ID of the Azure DDoS Protection Plan (if enabled) | string |

### GCP-Specific Outputs

| Name | Description | Type |
|------|-------------|------|
| gcp_network_name | Name of the GCP VPC network | string |
| gcp_subnetwork_ids | IDs of the GCP subnetworks | list(string) |
| gcp_router_ids | IDs of the GCP Cloud Routers | list(string) |
| gcp_nat_ids | IDs of the GCP Cloud NAT gateways | list(string) |
| gcp_service_networking_connection_id | ID of the GCP Service Networking connection | string |
| gcp_vpc_service_controls_perimeter_name | Name of the GCP VPC Service Controls perimeter | string |

### Kubernetes Integration

| Name | Description | Type |
|------|-------------|------|
| k8s_network_config | Network configuration formatted for Kubernetes cluster creation | object({provider = string, vpc_id = string, subnet_ids = list(string), public_subnet_ids = list(string), private_subnet_ids = list(string)}) |

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