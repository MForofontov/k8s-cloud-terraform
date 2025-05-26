# Cloud-Agnostic Networking Module

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

# Local variables for provider-specific configurations
locals {
  is_aws    = var.cloud_provider == "aws"
  is_azure  = var.cloud_provider == "azure"
  is_gcp    = var.cloud_provider == "gcp"
  
  # Default CIDRs if not provided
  vpc_cidr = var.vpc_cidr != null ? var.vpc_cidr : "10.0.0.0/16"
  
  # Generate subnet CIDRs based on the VPC CIDR if not provided
  subnet_cidrs = var.subnet_cidrs != null ? var.subnet_cidrs : [
    cidrsubnet(local.vpc_cidr, 4, 0),  # 10.0.0.0/20
    cidrsubnet(local.vpc_cidr, 4, 1),  # 10.0.16.0/20
    cidrsubnet(local.vpc_cidr, 4, 2),  # 10.0.32.0/20
    cidrsubnet(local.vpc_cidr, 4, 3),  # 10.0.48.0/20
  ]
  
  # Default names
  vpc_name = var.vpc_name != null ? var.vpc_name : "${var.name_prefix}-vpc"
  subnet_names = var.subnet_names != null ? var.subnet_names : [
    for i in range(length(local.subnet_cidrs)) : 
    "${var.name_prefix}-subnet-${i + 1}"
  ]
}

# AWS Resources
resource "aws_vpc" "this" {
  count                = local.is_aws ? 1 : 0
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = merge({
    Name = local.vpc_name
  }, var.tags)
}

resource "aws_subnet" "this" {
  count             = local.is_aws ? length(local.subnet_cidrs) : 0
  vpc_id            = aws_vpc.this[0].id
  cidr_block        = local.subnet_cidrs[count.index]
  availability_zone = length(var.availability_zones) > count.index ? var.availability_zones[count.index] : null
  
  tags = merge({
    Name = local.subnet_names[count.index]
  }, var.tags)
}

resource "aws_internet_gateway" "this" {
  count  = local.is_aws && var.create_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  
  tags = merge({
    Name = "${var.name_prefix}-igw"
  }, var.tags)
}

resource "aws_route_table" "public" {
  count  = local.is_aws && var.create_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  
  tags = merge({
    Name = "${var.name_prefix}-public-rt"
  }, var.tags)
}

resource "aws_route" "internet_gateway" {
  count                  = local.is_aws && var.create_internet_gateway ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count          = local.is_aws && var.create_internet_gateway ? length(var.public_subnet_indices) : 0
  subnet_id      = aws_subnet.this[var.public_subnet_indices[count.index]].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_eip" "nat" {
  count  = local.is_aws && var.create_nat_gateway ? 1 : 0
  domain = "vpc"
  
  tags = merge({
    Name = "${var.name_prefix}-nat-eip"
  }, var.tags)
}

resource "aws_nat_gateway" "this" {
  count         = local.is_aws && var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.this[var.public_subnet_indices[0]].id
  
  tags = merge({
    Name = "${var.name_prefix}-nat"
  }, var.tags)
  
  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  count  = local.is_aws && var.create_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  
  tags = merge({
    Name = "${var.name_prefix}-private-rt"
  }, var.tags)
}

resource "aws_route" "nat_gateway" {
  count                  = local.is_aws && var.create_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count          = local.is_aws && var.create_nat_gateway ? length(var.private_subnet_indices) : 0
  subnet_id      = aws_subnet.this[var.private_subnet_indices[count.index]].id
  route_table_id = aws_route_table.private[0].id
}

# Azure Resources
resource "azurerm_resource_group" "this" {
  count    = local.is_azure ? 1 : 0
  name     = "${var.name_prefix}-rg"
  location = var.azure_location
  
  tags = var.tags
}

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

resource "azurerm_public_ip" "nat" {
  count               = local.is_azure && var.create_nat_gateway ? 1 : 0
  name                = "${var.name_prefix}-nat-ip"
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name
  allocation_method   = "Static"
  sku                 = "Standard"
  
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

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count                = local.is_azure && var.create_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  count          = local.is_azure && var.create_nat_gateway ? length(var.private_subnet_indices) : 0
  subnet_id      = azurerm_subnet.this[var.private_subnet_indices[count.index]].id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}

# GCP Resources
resource "google_compute_network" "this" {
  count                   = local.is_gcp ? 1 : 0
  name                    = local.vpc_name
  auto_create_subnetworks = false
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
  private_ip_google_access = contains(var.private_subnet_indices, count.index) ? true : false
}

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
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  project                            = var.gcp_project_id
  
  dynamic "subnetwork" {
    for_each = var.private_subnet_indices
    content {
      name                    = google_compute_subnetwork.this[subnetwork.value].id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
}

# Firewall/Security Group rules for basic connectivity
resource "aws_security_group" "this" {
  count  = local.is_aws ? 1 : 0
  name   = "${var.name_prefix}-sg"
  vpc_id = aws_vpc.this[0].id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge({
    Name = "${var.name_prefix}-sg"
  }, var.tags)
}

resource "azurerm_network_security_group" "this" {
  count               = local.is_azure ? 1 : 0
  name                = "${var.name_prefix}-nsg"
  location            = azurerm_resource_group.this[0].location
  resource_group_name = azurerm_resource_group.this[0].name
  
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

resource "azurerm_subnet_network_security_group_association" "this" {
  count                     = local.is_azure ? length(local.subnet_cidrs) : 0
  subnet_id                 = azurerm_subnet.this[count.index].id
  network_security_group_id = azurerm_network_security_group.this[0].id
}

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