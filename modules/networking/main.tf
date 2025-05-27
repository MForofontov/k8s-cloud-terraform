#------------------------------------------------------------------------------
# Cloud-Agnostic Networking Module
#
# This module creates foundational networking infrastructure across AWS, Azure,
# and GCP using a consistent interface. It provisions VPCs/VNets, subnets,
# internet connectivity, and basic security rules with cloud-specific 
# implementations behind a unified API.
#------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.95.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.20.0"
    }
  }
}

#------------------------------------------------------------------------------
# Local Variables
# These variables handle provider detection and default configurations
#------------------------------------------------------------------------------
locals {
  # Provider detection flags - used to conditionally create resources
  is_aws    = var.cloud_provider == "aws"
  is_azure  = var.cloud_provider == "azure"
  is_gcp    = var.cloud_provider == "gcp"
  
  # Network CIDR handling - use provided CIDR or fall back to default
  # This defines the IP address space for the entire VPC/VNet
  vpc_cidr = var.vpc_cidr != null ? var.vpc_cidr : "10.0.0.0/16"
  
  # Subnet CIDR calculation - either use provided CIDRs or auto-generate
  # We create 4 subnets by default, dividing the VPC CIDR into /20 blocks
  subnet_cidrs = var.subnet_cidrs != null ? var.subnet_cidrs : [
    cidrsubnet(local.vpc_cidr, 4, 0),  # 10.0.0.0/20 - First quarter of address space
    cidrsubnet(local.vpc_cidr, 4, 1),  # 10.0.16.0/20 - Second quarter
    cidrsubnet(local.vpc_cidr, 4, 2),  # 10.0.32.0/20 - Third quarter
    cidrsubnet(local.vpc_cidr, 4, 3),  # 10.0.48.0/20 - Fourth quarter
  ]
  
  # Resource naming logic - use provided names or generate with prefix
  vpc_name = var.vpc_name != null ? var.vpc_name : "${var.name_prefix}-vpc"
  subnet_names = var.subnet_names != null ? var.subnet_names : [
    for i in range(length(local.subnet_cidrs)) : 
    "${var.name_prefix}-subnet-${i + 1}"
  ]
}

#==============================================================================
# AWS RESOURCES
#==============================================================================

#------------------------------------------------------------------------------
# AWS VPC and Subnets
#------------------------------------------------------------------------------
resource "aws_vpc" "this" {
  count                = local.is_aws ? 1 : 0
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true     # Enables DNS resolution in the VPC
  enable_dns_hostnames = true     # Enables DNS hostnames for EC2 instances
  
  tags = merge({
    Name = local.vpc_name
  }, var.tags)
}

resource "aws_subnet" "this" {
  count             = local.is_aws ? length(local.subnet_cidrs) : 0
  vpc_id            = aws_vpc.this[0].id
  cidr_block        = local.subnet_cidrs[count.index]
  # Assign availability zone if provided, otherwise AWS will choose one
  availability_zone = length(var.availability_zones) > count.index ? var.availability_zones[count.index] : null
  
  tags = merge({
    Name = local.subnet_names[count.index]
  }, var.tags)
}

#------------------------------------------------------------------------------
# AWS Internet Connectivity (Internet Gateway for public subnets)
#------------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  count  = local.is_aws && var.create_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  
  tags = merge({
    Name = "${var.name_prefix}-igw"
  }, var.tags)
}

# Route table for public subnets - routes traffic to the internet gateway
resource "aws_route_table" "public" {
  count  = local.is_aws && var.create_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  
  tags = merge({
    Name = "${var.name_prefix}-public-rt"
  }, var.tags)
}

# Default route to the internet via the internet gateway
resource "aws_route" "internet_gateway" {
  count                  = local.is_aws && var.create_internet_gateway ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"     # All traffic destined for the internet
  gateway_id             = aws_internet_gateway.this[0].id
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = local.is_aws && var.create_internet_gateway ? length(var.public_subnet_indices) : 0
  subnet_id      = aws_subnet.this[var.public_subnet_indices[count.index]].id
  route_table_id = aws_route_table.public[0].id
}

#------------------------------------------------------------------------------
# AWS NAT Gateway (outbound internet access for private subnets)
#------------------------------------------------------------------------------
# Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  count  = local.is_aws && var.create_nat_gateway ? 1 : 0
  domain = "vpc"     # EIP is used in a VPC
  
  tags = merge({
    Name = "${var.name_prefix}-nat-eip"
  }, var.tags)
}

# NAT Gateway placed in the first public subnet
resource "aws_nat_gateway" "this" {
  count         = local.is_aws && var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.this[var.public_subnet_indices[0]].id
  
  tags = merge({
    Name = "${var.name_prefix}-nat"
  }, var.tags)
  
  # Ensure the internet gateway is created first
  depends_on = [aws_internet_gateway.this]
}

# Route table for private subnets - routes traffic through the NAT gateway
resource "aws_route_table" "private" {
  count  = local.is_aws && var.create_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  
  tags = merge({
    Name = "${var.name_prefix}-private-rt"
  }, var.tags)
}

# Default route to the internet via the NAT gateway
resource "aws_route" "nat_gateway" {
  count                  = local.is_aws && var.create_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"     # All outbound traffic
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private" {
  count          = local.is_aws && var.create_nat_gateway ? length(var.private_subnet_indices) : 0
  subnet_id      = aws_subnet.this[var.private_subnet_indices[count.index]].id
  route_table_id = aws_route_table.private[0].id
}

#------------------------------------------------------------------------------
# AWS Security Groups (basic network security)
#------------------------------------------------------------------------------
resource "aws_security_group" "this" {
  count  = local.is_aws ? 1 : 0
  name   = "${var.name_prefix}-sg"
  vpc_id = aws_vpc.this[0].id
  
  # Allow all outbound traffic by default
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"     # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge({
    Name = "${var.name_prefix}-sg"
  }, var.tags)
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
  
  tags = var.tags
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
  
  tags = var.tags
}

resource "azurerm_subnet" "this" {
  count                = local.is_azure ? length(local.subnet_cidrs) : 0
  name                 = local.subnet_names[count.index]
  resource_group_name  = azurerm_resource_group.this[0].name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [local.subnet_cidrs[count.index]]
}

#------------------------------------------------------------------------------
# Azure NAT Gateway (outbound internet access for private subnets)
#------------------------------------------------------------------------------
resource "azurerm_public_ip" "nat" {
  count               = local.is_azure && var.create_nat_gateway ? 1 : 0
  name                = "${var.name_prefix}-nat-ip"
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name
  allocation_method   = "Static"    # Static IP is required for NAT Gateway
  sku                 = "Standard"  # Standard SKU is required for NAT Gateway
  
  tags = var.tags
}

resource "azurerm_nat_gateway" "this" {
  count               = local.is_azure && var.create_nat_gateway ? 1 : 0
  name                = "${var.name_prefix}-nat"
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name
  sku_name            = "Standard"
  
  tags = var.tags
}

# Associate the public IP with the NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "this" {
  count                = local.is_azure && var.create_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

# Associate private subnets with the NAT Gateway
resource "azurerm_subnet_nat_gateway_association" "this" {
  count          = local.is_azure && var.create_nat_gateway ? length(var.private_subnet_indices) : 0
  subnet_id      = azurerm_subnet.this[var.private_subnet_indices[count.index]].id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
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
  
  tags = var.tags
}

# Associate the NSG with all subnets
resource "azurerm_subnet_network_security_group_association" "this" {
  count                     = local.is_azure ? length(local.subnet_cidrs) : 0
  subnet_id                 = azurerm_subnet.this[count.index].id
  network_security_group_id = azurerm_network_security_group.this[0].id
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
  auto_create_subnetworks = false    # Don't auto-create subnets; we'll define them explicitly
  project                 = var.gcp_project_id
}

resource "google_compute_subnetwork" "this" {
  count          = local.is_gcp ? length(local.subnet_cidrs) : 0
  name           = local.subnet_names[count.index]
  ip_cidr_range  = local.subnet_cidrs[count.index]
  region         = var.gcp_region
  network        = google_compute_network.this[0].id
  project        = var.gcp_project_id
  
  # Enable private Google access for private subnets
  # This allows resources without external IPs to access Google APIs
  private_ip_google_access = contains(var.private_subnet_indices, count.index) ? true : false
}

#------------------------------------------------------------------------------
# GCP Cloud Router and NAT (outbound internet access for private subnets)
#------------------------------------------------------------------------------
resource "google_compute_router" "this" {
  count   = local.is_gcp && var.create_nat_gateway ? 1 : 0
  name    = "${var.name_prefix}-router"
  region  = var.gcp_region
  network = google_compute_network.this[0].id
  project = var.gcp_project_id
}

resource "google_compute_router_nat" "this" {
  count                              = local.is_gcp && var.create_nat_gateway ? 1 : 0
  name                               = "${var.name_prefix}-nat"
  router                             = google_compute_router.this[0].name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"    # Automatically allocate IPs for NAT
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"  # Only NAT specific subnets
  project                            = var.gcp_project_id
  
  # Apply NAT to each private subnet
  dynamic "subnetwork" {
    for_each = var.private_subnet_indices
    content {
      name                    = google_compute_subnetwork.this[subnetwork.value].id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]  # NAT all IPs in the subnet
    }
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
  
  direction = "EGRESS"  # Outbound traffic
  allow {
    protocol = "all"    # Allow all protocols
  }
  
  destination_ranges = ["0.0.0.0/0"]  # Allow traffic to all destinations
}