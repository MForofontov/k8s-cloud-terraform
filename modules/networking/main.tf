#------------------------------------------------------------------------------
# Multi-Cloud Networking Module
#
# This enterprise-grade module creates cloud provider networking infrastructure
# with consistent interfaces for AWS, Azure, and GCP. It implements networking
# best practices for Kubernetes deployments with:
#
# - VPC/VNet with public and private subnets
# - Secure outbound internet access via NAT gateways
# - Service endpoints for private cloud service access
# - Network flow logging and monitoring
# - IPv6 support (optional)
# - Consistent security baselines
#------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.98.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.95.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.37.0"
    }
  }
}

#------------------------------------------------------------------------------
# Local Variables - Provider Detection and Smart Defaults
#------------------------------------------------------------------------------
locals {
  # Provider detection flags
  is_aws    = var.cloud_provider == "aws"
  is_azure  = var.cloud_provider == "azure"
  is_gcp    = var.cloud_provider == "gcp"

  # Network CIDR handling
  vpc_cidr = coalesce(var.vpc_cidr, "10.0.0.0/16")

  # IPv6 configuration
  enable_ipv6 = var.enable_ipv6 == true

  # Automated subnet CIDR calculation for both IPv4 and IPv6
  # Divides VPC CIDR into equal subnets based on subnet count
  subnet_count = length(var.subnet_names) > 0 ? length(var.subnet_names) : 4
  subnet_newbits = ceil(log(local.subnet_count, 2))

  # Calculate subnet CIDRs if not explicitly provided
  subnet_cidrs = var.subnet_cidrs != null ? var.subnet_cidrs : [
    for i in range(local.subnet_count) : cidrsubnet(local.vpc_cidr, local.subnet_newbits, i)
  ]

  # Resource naming
  vpc_name = coalesce(var.vpc_name, "${var.name_prefix}-vpc")
  subnet_names = var.subnet_names != null ? var.subnet_names : [
    for i in range(local.subnet_count) :
    "${var.name_prefix}-subnet-${i + 1}"
  ]

  # Default subnet indices
  public_subnet_indices = length(var.public_subnet_indices) > 0 ? var.public_subnet_indices : [0, 1]
  private_subnet_indices = length(var.private_subnet_indices) > 0 ? var.private_subnet_indices : [2, 3]

  # Enhanced tagging with standard keys
  common_tags = merge({
    "Environment"     = var.environment
    "ManagedBy"       = "terraform"
    "Module"          = "networking"
    "CloudProvider"   = var.cloud_provider
  }, var.tags)

  # Service endpoint configurations
  aws_vpc_endpoints = var.enable_service_endpoints && local.is_aws ? {
    "s3"       = { service = "s3", service_type = "Gateway" }
    "dynamodb" = { service = "dynamodb", service_type = "Gateway" }
    "ecr-api"  = { service = "ecr.api", service_type = "Interface" }
    "ecr-dkr"  = { service = "ecr.dkr", service_type = "Interface" }
    "ec2"      = { service = "ec2", service_type = "Interface" }
    "logs"     = { service = "logs", service_type = "Interface" }
  } : {}
}

#==============================================================================
# AWS RESOURCES
#==============================================================================

#------------------------------------------------------------------------------
# AWS VPC and Subnets
#------------------------------------------------------------------------------
resource "aws_vpc" "this" {
  count                            = local.is_aws ? 1 : 0
  cidr_block                       = local.vpc_cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = local.enable_ipv6

  tags = merge(local.common_tags, {
    Name = local.vpc_name
  })
}

resource "aws_subnet" "this" {
  count                           = local.is_aws ? length(local.subnet_cidrs) : 0
  vpc_id                          = aws_vpc.this[0].id
  cidr_block                      = local.subnet_cidrs[count.index]
  availability_zone               = length(var.availability_zones) > count.index ? var.availability_zones[count.index] : null
  map_public_ip_on_launch         = contains(local.public_subnet_indices, count.index) ? true : false

  # Configure IPv6 if enabled
  ipv6_cidr_block                 = local.enable_ipv6 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, count.index) : null
  assign_ipv6_address_on_creation = local.enable_ipv6 && contains(local.public_subnet_indices, count.index) ? true : false

  tags = merge(local.common_tags, {
    Name = local.subnet_names[count.index]
    "kubernetes.io/role/internal-elb" = contains(local.private_subnet_indices, count.index) ? "1" : "0"
    "kubernetes.io/role/elb"          = contains(local.public_subnet_indices, count.index) ? "1" : "0"
    "Tier" = contains(local.public_subnet_indices, count.index) ? "public" : "private"
  })
}

#------------------------------------------------------------------------------
# AWS Internet Connectivity (Internet Gateway for public subnets)
#------------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  count  = local.is_aws && var.create_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# Egress-only internet gateway for IPv6 private subnet outbound connectivity
resource "aws_egress_only_internet_gateway" "this" {
  count  = local.is_aws && local.enable_ipv6 ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-eigw"
  })
}

# Route table for public subnets - routes traffic to the internet gateway
resource "aws_route_table" "public" {
  count  = local.is_aws && var.create_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-public-rt"
    Tier = "public"
  })
}

# Default route to the internet via the internet gateway (IPv4)
resource "aws_route" "internet_gateway_ipv4" {
  count                  = local.is_aws && var.create_internet_gateway ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

# Default route to the internet via the internet gateway (IPv6)
resource "aws_route" "internet_gateway_ipv6" {
  count                       = local.is_aws && var.create_internet_gateway && local.enable_ipv6 ? 1 : 0
  route_table_id              = aws_route_table.public[0].id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.this[0].id
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = local.is_aws && var.create_internet_gateway ? length(local.public_subnet_indices) : 0
  subnet_id      = aws_subnet.this[local.public_subnet_indices[count.index]].id
  route_table_id = aws_route_table.public[0].id
}

#------------------------------------------------------------------------------
# AWS NAT Gateway (outbound internet access for private subnets)
#------------------------------------------------------------------------------
# Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  count  = local.is_aws && var.create_nat_gateway ? var.single_nat_gateway ? 1 : length(local.public_subnet_indices) : 0
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = var.single_nat_gateway ? "${var.name_prefix}-nat-eip" : "${var.name_prefix}-nat-eip-${count.index + 1}"
  })
}

# NAT Gateway placed in public subnet(s)
resource "aws_nat_gateway" "this" {
  count         = local.is_aws && var.create_nat_gateway ? var.single_nat_gateway ? 1 : length(local.public_subnet_indices) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.this[local.public_subnet_indices[count.index]].id

  tags = merge(local.common_tags, {
    Name = var.single_nat_gateway ? "${var.name_prefix}-nat" : "${var.name_prefix}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

# Route table for private subnets - routes traffic through the NAT gateway
resource "aws_route_table" "private" {
  count  = local.is_aws && var.create_nat_gateway ? var.single_nat_gateway ? 1 : length(local.private_subnet_indices) : 0
  vpc_id = aws_vpc.this[0].id

  tags = merge(local.common_tags, {
    Name = var.single_nat_gateway ? "${var.name_prefix}-private-rt" : "${var.name_prefix}-private-rt-${count.index + 1}"
    Tier = "private"
  })
}

# Default route to the internet via the NAT gateway (IPv4)
resource "aws_route" "nat_gateway_ipv4" {
  count                  = local.is_aws && var.create_nat_gateway ? var.single_nat_gateway ? 1 : length(local.private_subnet_indices) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
}

# Default route to the internet via the egress-only internet gateway (IPv6)
resource "aws_route" "egress_only_ipv6" {
  count                       = local.is_aws && local.enable_ipv6 ? var.single_nat_gateway ? 1 : length(local.private_subnet_indices) : 0
  route_table_id              = aws_route_table.private[count.index].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.this[0].id
}

# Associate private subnets with the private route table(s)
resource "aws_route_table_association" "private" {
  count          = local.is_aws && var.create_nat_gateway ? length(local.private_subnet_indices) : 0
  subnet_id      = aws_subnet.this[local.private_subnet_indices[count.index]].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}

#------------------------------------------------------------------------------
# AWS VPC Endpoints (PrivateLink)
#------------------------------------------------------------------------------
# Gateway endpoints (S3, DynamoDB) - don't require elastic network interfaces
resource "aws_vpc_endpoint" "gateway" {
  for_each = { for k, v in local.aws_vpc_endpoints : k => v if v.service_type == "Gateway" }

  vpc_id            = aws_vpc.this[0].id
  service_name      = "com.amazonaws.${var.aws_region}.${each.value.service}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.single_nat_gateway ? [aws_route_table.private[0].id] : aws_route_table.private[*].id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}-endpoint"
  })
}

# Interface endpoints (ECR, EC2, etc.) - require elastic network interfaces in subnets
resource "aws_vpc_endpoint" "interface" {
  for_each = { for k, v in local.aws_vpc_endpoints : k => v if v.service_type == "Interface" }

  vpc_id              = aws_vpc.this[0].id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value.service}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for idx in local.private_subnet_indices : aws_subnet.this[idx].id]
  security_group_ids  = [aws_security_group.endpoints[0].id]

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}-endpoint"
  })
}

# Security group for VPC endpoints
resource "aws_security_group" "endpoints" {
  count  = local.is_aws && var.enable_service_endpoints ? 1 : 0
  name   = "${var.name_prefix}-endpoint-sg"
  vpc_id = aws_vpc.this[0].id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
    description = "Allow HTTPS from VPC CIDR"
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-endpoint-sg"
  })
}

#------------------------------------------------------------------------------
# AWS Security Groups (baseline network security)
#------------------------------------------------------------------------------
resource "aws_security_group" "this" {
  count  = local.is_aws ? 1 : 0
  name   = "${var.name_prefix}-sg"
  vpc_id = aws_vpc.this[0].id

  # Allow all outbound traffic by default
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  # IPv6 egress if enabled
  dynamic "egress" {
    for_each = local.enable_ipv6 ? [1] : []
    content {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      ipv6_cidr_blocks = ["::/0"]
      description      = "Allow all IPv6 outbound traffic"
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-sg"
  })
}

#------------------------------------------------------------------------------
# AWS Flow Logs (network traffic logging)
#------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "flow_log" {
  count             = local.is_aws && var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc-flow-logs/${local.vpc_name}"
  retention_in_days = var.flow_logs_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-flow-logs"
  })
}

resource "aws_iam_role" "flow_log_role" {
  count = local.is_aws && var.enable_flow_logs ? 1 : 0
  name  = "${var.name_prefix}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_log_policy" {
  count = local.is_aws && var.enable_flow_logs ? 1 : 0
  name  = "${var.name_prefix}-flow-log-policy"
  role  = aws_iam_role.flow_log_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count                = local.is_aws && var.enable_flow_logs ? 1 : 0
  iam_role_arn         = aws_iam_role.flow_log_role[0].arn
  log_destination      = aws_cloudwatch_log_group.flow_log[0].arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this[0].id
  log_destination_type = "cloud-watch-logs"

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-vpc-flow-log"
  })
}

#==============================================================================
# AZURE RESOURCES
#==============================================================================

#------------------------------------------------------------------------------
# Azure Resource Group (container for all resources)
#------------------------------------------------------------------------------
resource "azurerm_resource_group" "this" {
  count    = local.is_azure ? 1 : 0
  name     = "${var.name_prefix}-rg"
  location = var.azure_location

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Azure Virtual Network and Subnets
#------------------------------------------------------------------------------
resource "azurerm_virtual_network" "this" {
  count               = local.is_azure ? 1 : 0
  name                = local.vpc_name
  resource_group_name = azurerm_resource_group.this[0].name
  location            = azurerm_resource_group.this[0].location
  address_space       = [local.vpc_cidr]

  # Add IPv6 address space if enabled
  dynamic "ddos_protection_plan" {
    for_each = var.azure_enable_ddos_protection ? [1] : []
    content {
      id     = azurerm_network_ddos_protection_plan.this[0].id
      enable = true
    }
  }

  tags = local.common_tags
}

# Create DDoS protection plan if enabled
resource "azurerm_network_ddos_protection_plan" "this" {
  count               = local.is_azure && var.azure_enable_ddos_protection ? 1 : 0
  name                = "${var.name_prefix}-ddos-plan"
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name

  tags = local.common_tags
}

resource "azurerm_subnet" "this" {
  count                = local.is_azure ? length(local.subnet_cidrs) : 0
  name                 = local.subnet_names[count.index]
  resource_group_name  = azurerm_resource_group.this[0].name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [local.subnet_cidrs[count.index]]

  # Enable service endpoints for private subnets
  dynamic "service_endpoints" {
    for_each = var.enable_service_endpoints && contains(local.private_subnet_indices, count.index) ? var.azure_service_endpoints : []
    content {
      service = service_endpoints.value
    }
  }

  # Delegation for specific Azure services if required
  dynamic "delegation" {
    for_each = contains(local.private_subnet_indices, count.index) && var.azure_subnet_delegations != null ? var.azure_subnet_delegations : {}
    content {
      name = delegation.key

      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

#------------------------------------------------------------------------------
# Azure NAT Gateway (outbound internet access for private subnets)
#------------------------------------------------------------------------------
resource "azurerm_public_ip" "nat" {
  count               = local.is_azure && var.create_nat_gateway ? var.single_nat_gateway ? 1 : length(local.private_subnet_indices) : 0
  name                = var.single_nat_gateway ? "${var.name_prefix}-nat-ip" : "${var.name_prefix}-nat-ip-${count.index + 1}"
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.azure_enable_zones ? ["1", "2", "3"] : null

  tags = local.common_tags
}

resource "azurerm_nat_gateway" "this" {
  count                   = local.is_azure && var.create_nat_gateway ? var.single_nat_gateway ? 1 : length(local.private_subnet_indices) : 0
  name                    = var.single_nat_gateway ? "${var.name_prefix}-nat" : "${var.name_prefix}-nat-${count.index + 1}"
  location                = azurerm_resource_group.this[0].location
  resource_group_name     = azurerm_resource_group.this[0].name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = var.azure_enable_zones ? ["1", "2", "3"] : null

  tags = local.common_tags
}

# Associate the public IPs with the NAT Gateways
resource "azurerm_nat_gateway_public_ip_association" "this" {
  count                = local.is_azure && var.create_nat_gateway ? var.single_nat_gateway ? 1 : length(local.private_subnet_indices) : 0
  nat_gateway_id       = azurerm_nat_gateway.this[count.index].id
  public_ip_address_id = azurerm_public_ip.nat[count.index].id
}

# Associate private subnets with the NAT Gateway(s)
resource "azurerm_subnet_nat_gateway_association" "this" {
  count          = local.is_azure && var.create_nat_gateway ? length(local.private_subnet_indices) : 0
  subnet_id      = azurerm_subnet.this[local.private_subnet_indices[count.index]].id
  nat_gateway_id = azurerm_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
}

#------------------------------------------------------------------------------
# Azure Network Security Group (basic network security)
#------------------------------------------------------------------------------
resource "azurerm_network_security_group" "this" {
  count               = local.is_azure ? 1 : 0
  name                = "${var.name_prefix}-nsg"
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name

  # Allow all outbound traffic by default
  security_rule {
    name                       = "AllowOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Deny all inbound traffic by default (explicit deny)
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Associate the NSG with all subnets
resource "azurerm_subnet_network_security_group_association" "this" {
  count                     = local.is_azure ? length(local.subnet_cidrs) : 0
  subnet_id                 = azurerm_subnet.this[count.index].id
  network_security_group_id = azurerm_network_security_group.this[0].id
}

#------------------------------------------------------------------------------
# Azure Network Watcher Flow Logs
#------------------------------------------------------------------------------
resource "azurerm_network_watcher" "this" {
  count               = local.is_azure && var.enable_flow_logs ? 1 : 0
  name                = "${var.name_prefix}-network-watcher"
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name

  tags = local.common_tags
}

resource "azurerm_storage_account" "flow_logs" {
  count                    = local.is_azure && var.enable_flow_logs ? 1 : 0
  name                     = lower(replace("${var.name_prefix}flowlogs", "-", ""))
  resource_group_name      = azurerm_resource_group.this[0].name
  location                 = azurerm_resource_group.this[0].location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = local.common_tags
}

resource "azurerm_network_watcher_flow_log" "this" {
  count                = local.is_azure && var.enable_flow_logs ? 1 : 0
  network_watcher_name = azurerm_network_watcher.this[0].name
  resource_group_name  = azurerm_resource_group.this[0].name
  name                 = "${var.name_prefix}-flow-log"

  target_resource_id   = azurerm_network_security_group.this[0].id
  storage_account_id        = azurerm_storage_account.flow_logs[0].id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = var.flow_logs_retention_days
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = var.azure_log_analytics_workspace_id
    workspace_region      = azurerm_resource_group.this[0].location
    workspace_resource_id = var.azure_log_analytics_workspace_resource_id
    interval_in_minutes   = 10
  }
}

#==============================================================================
# GCP RESOURCES
#==============================================================================

#------------------------------------------------------------------------------
# GCP VPC Network and Subnets
#------------------------------------------------------------------------------
resource "google_compute_network" "this" {
  count                   = local.is_gcp ? 1 : 0
  name                    = local.vpc_name
  auto_create_subnetworks = false
  project                 = var.gcp_project_id

  # Enable global routing if specified
  routing_mode            = var.gcp_routing_mode

  # Enable dual-stack IPv6 if specified
  dynamic "ipv6_access_type" {
    for_each = local.enable_ipv6 ? ["EXTERNAL"] : []
    content {
      enable_ipv6 = true
      type        = ipv6_access_type.value
    }
  }
}

resource "google_compute_subnetwork" "this" {
  count          = local.is_gcp ? length(local.subnet_cidrs) : 0
  name           = local.subnet_names[count.index]
  ip_cidr_range  = local.subnet_cidrs[count.index]
  region         = var.gcp_region
  network        = google_compute_network.this[0].id
  project        = var.gcp_project_id

  # Enable private Google access for private subnets
  private_ip_google_access = contains(local.private_subnet_indices, count.index) ? true : false

  # Enable flow logs if requested
  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }

  # Configure IPv6 if enabled and this is a public subnet
  dynamic "ipv6_access_type" {
    for_each = local.enable_ipv6 && contains(local.public_subnet_indices, count.index) ? ["EXTERNAL"] : []
    content {
      enable_ipv6 = true
      type        = ipv6_access_type.value
    }
  }
}

#------------------------------------------------------------------------------
# GCP Cloud Router and NAT (outbound internet access for private subnets)
#------------------------------------------------------------------------------
resource "google_compute_router" "this" {
  count   = local.is_gcp && var.create_nat_gateway ? var.single_nat_gateway ? 1 : length(local.private_subnet_indices) : 0
  name    = var.single_nat_gateway ? "${var.name_prefix}-router" : "${var.name_prefix}-router-${count.index + 1}"
  region  = var.gcp_region
  network = google_compute_network.this[0].id
  project = var.gcp_project_id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "this" {
  count                              = local.is_gcp && var.create_nat_gateway ? var.single_nat_gateway ? 1 : length(local.private_subnet_indices) : 0
  name                               = var.single_nat_gateway ? "${var.name_prefix}-nat" : "${var.name_prefix}-nat-${count.index + 1}"
  router                             = google_compute_router.this[count.index].name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = var.single_nat_gateway ? "ALL_SUBNETWORKS_ALL_IP_RANGES" : "LIST_OF_SUBNETWORKS"
  project                            = var.gcp_project_id

  # Apply NAT to each private subnet if using multiple NAT gateways
  dynamic "subnetwork" {
    for_each = var.single_nat_gateway ? [] : [local.private_subnet_indices[count.index]]
    content {
      name                    = google_compute_subnetwork.this[subnetwork.value].id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }

  # Enable logging
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

#------------------------------------------------------------------------------
# GCP Firewall Rules (basic network security)
#------------------------------------------------------------------------------
resource "google_compute_firewall" "egress" {
  count   = local.is_gcp ? 1 : 0
  name    = "${var.name_prefix}-allow-egress"
  network = google_compute_network.this[0].id
  project = var.gcp_project_id

  direction = "EGRESS"
  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

# Deny all ingress by default
resource "google_compute_firewall" "deny_ingress" {
  count   = local.is_gcp ? 1 : 0
  name    = "${var.name_prefix}-deny-ingress"
  network = google_compute_network.this[0].id
  project = var.gcp_project_id

  direction     = "INGRESS"
  priority      = 65534  # Just before the default allow
  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }
}

#------------------------------------------------------------------------------
# GCP Service Networking Connection (for private services access)
#------------------------------------------------------------------------------
resource "google_compute_global_address" "private_services" {
  count         = local.is_gcp && var.enable_service_endpoints ? 1 : 0
  name          = "${var.name_prefix}-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.this[0].id
  project       = var.gcp_project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = local.is_gcp && var.enable_service_endpoints ? 1 : 0
  network                 = google_compute_network.this[0].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services[0].name]
}

#------------------------------------------------------------------------------
# GCP Access Context Manager (VPC Service Controls) - Enterprise Only
#------------------------------------------------------------------------------
resource "google_access_context_manager_service_perimeter" "vpc_sc" {
  count          = local.is_gcp && var.gcp_enable_vpc_service_controls && var.gcp_access_policy_id != null ? 1 : 0
  parent         = "accessPolicies/${var.gcp_access_policy_id}"
  name           = "accessPolicies/${var.gcp_access_policy_id}/servicePerimeters/${var.name_prefix}-perimeter"
  title          = "${var.name_prefix} Perimeter"
  perimeter_type = "PERIMETER_TYPE_REGULAR"

  status {
    resources = ["projects/${var.gcp_project_number}"]

    restricted_services = var.gcp_restricted_services

    vpc_accessible_services {
      enable_restriction = true
      allowed_services   = var.gcp_allowed_services
    }

    ingress_policies {
      ingress_from {
        identities = var.gcp_allowed_identities
      }
      ingress_to {
        resources = ["projects/${var.gcp_project_number}"]
        operations {
          service_name = "*"
        }
      }
    }
  }
}