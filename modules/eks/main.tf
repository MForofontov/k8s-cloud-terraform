#==============================================================================
# Amazon EKS (Elastic Kubernetes Service) Module
#
# This module provisions a production-ready EKS cluster with customizable
# configurations for networking, node groups, security, and operations.
# It supports both managed node groups and Fargate profiles to accommodate
# different application requirements and cost considerations.
#
# The module implements AWS best practices for cluster configuration:
# - IAM roles with least privilege principles
# - Private/public endpoint access controls
# - Managed add-ons for core components
# - IRSA (IAM Roles for Service Accounts) for fine-grained permissions
# - Encryption for sensitive data using KMS
#==============================================================================

#==============================================================================
# Provider Configuration
# Specifies the required providers and versions for this module
#==============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.98.0" # Latest stable AWS provider at time of creation
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.1" # For potential future Kubernetes resource management
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1.0" # Used for OIDC provider certificate handling
    }
  }
  required_version = ">= 1.0.0"
}

#==============================================================================
# Data Sources
# References to existing AWS resources and metadata
#==============================================================================
# Current AWS region information for region-specific configurations and ARNs
data "aws_region" "current" {}

#==============================================================================
# EKS Cluster
# The primary resource that defines the Kubernetes control plane
#==============================================================================
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name                                                                  # Human-readable identifier for the cluster
  role_arn = var.cluster_role_arn != null ? var.cluster_role_arn : aws_iam_role.cluster[0].arn # IAM role for the EKS service
  version  = var.kubernetes_version                                                            # Kubernetes version to deploy (or latest if null)

  #--------------------------------------------------------------
  # VPC Configuration
  # Networking settings for the EKS cluster
  #--------------------------------------------------------------
  vpc_config {
    subnet_ids              = var.subnet_ids              # Subnets must span at least two AZs
    endpoint_private_access = var.endpoint_private_access # Allow access from within VPC
    endpoint_public_access  = var.endpoint_public_access  # Allow access from internet
    security_group_ids      = var.security_group_ids      # Additional security groups
    public_access_cidrs     = var.public_access_cidrs     # IP ranges that can access API server
  }

  #--------------------------------------------------------------
  # Logging Configuration
  # Controls which EKS components send logs to CloudWatch
  #--------------------------------------------------------------
  enabled_cluster_log_types = var.enabled_cluster_log_types # api, audit, authenticator, etc.

  #--------------------------------------------------------------
  # Encryption Configuration
  # Encrypts Kubernetes secrets using KMS
  #--------------------------------------------------------------
  encryption_config {
    resources = ["secrets"] # Only secrets are encrypted currently
    provider {
      key_arn = var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.eks[0].arn # KMS key for encryption
    }
  }

  #--------------------------------------------------------------
  # Resource Tags
  # AWS-level tags for organization and billing
  #--------------------------------------------------------------
  tags = merge(
    var.tags,
    {
      "Name" = var.cluster_name
    }
  )

  #--------------------------------------------------------------
  # Dependencies
  # Ensures proper order of resource creation
  #--------------------------------------------------------------
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,         # Ensure policy is attached
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController, # before creating cluster
  ]

  #--------------------------------------------------------------
  # Lifecycle Management
  # Controls how Terraform handles resource changes
  #--------------------------------------------------------------
  lifecycle {
    create_before_destroy = true # Prevents dependency issues during updates
  }
}

#==============================================================================
# KMS Key for Secrets Encryption
# Provides encryption for Kubernetes secrets
#==============================================================================
resource "aws_kms_key" "eks" {
  count                   = var.kms_key_arn == null ? 1 : 0 # Only create if not provided
  description             = "KMS key for EKS cluster ${var.cluster_name} secrets encryption"
  deletion_window_in_days = 7    # Waiting period before actual deletion
  enable_key_rotation     = true # Best practice for security
  tags                    = var.tags
}

resource "aws_kms_alias" "eks" {
  count         = var.kms_key_arn == null ? 1 : 0
  name          = "alias/${var.cluster_name}-eks-secrets" # Human-readable alias
  target_key_id = aws_kms_key.eks[0].key_id               # References the created KMS key
}

#==============================================================================
# Default Node Group
# Primary managed node group for general workloads
#==============================================================================
resource "aws_eks_node_group" "default" {
  count = var.create_default_node_group ? 1 : 0 # Optional creation

  cluster_name    = aws_eks_cluster.this.name                                                # References the EKS cluster
  node_group_name = "${var.cluster_name}-default"                                            # Standard naming convention
  node_role_arn   = var.node_role_arn != null ? var.node_role_arn : aws_iam_role.node[0].arn # IAM role for nodes
  subnet_ids      = var.subnet_ids                                                           # Must be in private subnets for production

  #--------------------------------------------------------------
  # Scaling Configuration
  # Controls the number of nodes in the group
  #--------------------------------------------------------------
  scaling_config {
    desired_size = var.node_desired_size # Initial/target number of nodes
    max_size     = var.node_max_size     # Upper limit for autoscaling
    min_size     = var.node_min_size     # Lower limit for autoscaling
  }

  #--------------------------------------------------------------
  # Node Configuration
  # Settings for the EC2 instances in the node group
  #--------------------------------------------------------------
  instance_types = var.node_instance_types # List of instance types to use
  capacity_type  = var.node_capacity_type  # ON_DEMAND or SPOT
  disk_size      = var.node_disk_size      # Root EBS volume size in GB
  labels         = var.node_labels         # Kubernetes labels for nodes

  #--------------------------------------------------------------
  # Taints
  # Controls pod scheduling restrictions
  #--------------------------------------------------------------
  dynamic "taint" {
    for_each = var.node_taints # Apply taints if specified
    content {
      key    = taint.value.key    # Taint identifier
      value  = taint.value.value  # Taint value
      effect = taint.value.effect # NoSchedule, PreferNoSchedule, or NoExecute
    }
  }

  #--------------------------------------------------------------
  # Resource Tags
  # AWS-level tags for the node group
  #--------------------------------------------------------------
  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-default-node-group"
    }
  )

  #--------------------------------------------------------------
  # Dependencies
  # Ensures IAM permissions are in place before nodes
  #--------------------------------------------------------------
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]

  #--------------------------------------------------------------
  # Lifecycle Management
  # Handles autoscaling-driven changes
  #--------------------------------------------------------------
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size] # Allows autoscaler to manage
  }
}

#==============================================================================
# Additional Node Groups
# Specialized node groups for different workload types
#==============================================================================
resource "aws_eks_node_group" "additional" {
  for_each = var.node_groups # Create multiple from map input

  cluster_name    = aws_eks_cluster.this.name # References the EKS cluster
  node_group_name = each.key                  # Use the map key as node group name
  node_role_arn   = var.node_role_arn != null ? var.node_role_arn : aws_iam_role.node[0].arn
  subnet_ids      = each.value.subnet_ids != null ? each.value.subnet_ids : var.subnet_ids

  #--------------------------------------------------------------
  # Scaling Configuration
  # Each group can have unique scaling parameters
  #--------------------------------------------------------------
  scaling_config {
    desired_size = each.value.desired_size # Initial node count
    max_size     = each.value.max_size     # Maximum node count
    min_size     = each.value.min_size     # Minimum node count
  }

  #--------------------------------------------------------------
  # Node Configuration
  # Customized settings for specialized workloads
  #--------------------------------------------------------------
  instance_types = each.value.instance_types # Specific instance types for workload
  capacity_type  = each.value.capacity_type  # ON_DEMAND for critical, SPOT for batch
  disk_size      = each.value.disk_size      # Size based on workload requirements
  labels         = each.value.labels         # Labels for node selection

  #--------------------------------------------------------------
  # Taints
  # Used for workload isolation
  #--------------------------------------------------------------
  dynamic "taint" {
    for_each = each.value.taints != null ? each.value.taints : []
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  #--------------------------------------------------------------
  # Resource Tags
  # Combines default and node-group specific tags
  #--------------------------------------------------------------
  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-${each.key}-node-group"
    },
    each.value.tags != null ? each.value.tags : {}
  )

  #--------------------------------------------------------------
  # Dependencies
  # Ensures IAM permissions are in place
  #--------------------------------------------------------------
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]

  #--------------------------------------------------------------
  # Lifecycle Management
  # Allows external scaling without Terraform conflicts
  #--------------------------------------------------------------
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size] # Ignore autoscaling changes
  }
}

#==============================================================================
# Fargate Profiles
# Serverless compute for specific workloads
#==============================================================================
resource "aws_eks_fargate_profile" "this" {
  for_each = var.fargate_profiles # Create multiple from map input

  cluster_name           = aws_eks_cluster.this.name # References the EKS cluster
  fargate_profile_name   = each.key                  # Use the map key as profile name
  pod_execution_role_arn = var.create_fargate_pod_execution_role ? aws_iam_role.fargate_pod_execution[0].arn : each.value.pod_execution_role_arn
  subnet_ids             = each.value.subnet_ids != null ? each.value.subnet_ids : var.subnet_ids # Must be private subnets

  #--------------------------------------------------------------
  # Selectors
  # Define which pods run on Fargate
  #--------------------------------------------------------------
  dynamic "selector" {
    for_each = each.value.selectors
    content {
      namespace = selector.value.namespace               # Kubernetes namespace to match
      labels    = lookup(selector.value, "labels", null) # Pod labels to match
    }
  }

  #--------------------------------------------------------------
  # Resource Tags
  # Combines default and profile-specific tags
  #--------------------------------------------------------------
  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-${each.key}-fargate-profile"
    },
    each.value.tags != null ? each.value.tags : {}
  )
}

#==============================================================================
# Fargate Pod Execution Role
# IAM role for pods running on Fargate
#==============================================================================
resource "aws_iam_role" "fargate_pod_execution" {
  count = var.create_fargate_pod_execution_role ? 1 : 0

  name = "${var.cluster_name}-fargate-pod-execution-role"

  #--------------------------------------------------------------
  # Trust Relationship
  # Allows Fargate to assume this role
  #--------------------------------------------------------------
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
  count      = var.create_fargate_pod_execution_role ? 1 : 0
  role       = aws_iam_role.fargate_pod_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy" # AWS-managed policy
}

#==============================================================================
# OIDC Provider for IRSA
# Enables IAM Roles for Service Accounts
#==============================================================================
# Get the TLS certificate for the OIDC provider
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]                                       # Authorized client for token exchange
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint] # Certificate validation
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer             # OIDC issuer URL

  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-eks-irsa"
    }
  )
}

#==============================================================================
# EKS Add-ons
# Managed operational components
#==============================================================================
#--------------------------------------------------------------
# CoreDNS
# Provides DNS services within the cluster
#--------------------------------------------------------------
resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "coredns"
  addon_version = var.coredns_version # Specific version or null for default
  preserve      = var.addon_preserve  # Whether to keep resources on delete

  tags = var.tags
}

#--------------------------------------------------------------
# kube-proxy
# Handles cluster networking and service discovery
#--------------------------------------------------------------
resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_kube_proxy ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "kube-proxy"
  addon_version = var.kube_proxy_version
  preserve      = var.addon_preserve

  tags = var.tags
}

#--------------------------------------------------------------
# VPC CNI
# Handles pod networking and IP allocation
#--------------------------------------------------------------
resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "vpc-cni"
  addon_version = var.vpc_cni_version
  preserve      = var.addon_preserve

  # Use IRSA if enabled for fine-grained permissions
  service_account_role_arn = var.enable_irsa && var.create_vpc_cni_service_account_role ? aws_iam_role.vpc_cni[0].arn : null

  tags = var.tags
}

#--------------------------------------------------------------
# VPC CNI IAM Role for Service Account
# Allows CNI to manage ENIs and IPs
#--------------------------------------------------------------
resource "aws_iam_role" "vpc_cni" {
  count = var.enable_irsa && var.create_vpc_cni_service_account_role ? 1 : 0

  name = "${var.cluster_name}-vpc-cni-irsa"

  #--------------------------------------------------------------
  # Trust Relationship
  # Allows specific service account to assume this role
  #--------------------------------------------------------------
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks[0].arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks[0].url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-node"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  count      = var.enable_irsa && var.create_vpc_cni_service_account_role ? 1 : 0
  role       = aws_iam_role.vpc_cni[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy" # AWS-managed policy
}

#--------------------------------------------------------------
# EBS CSI Driver
# Enables dynamic provisioning of EBS volumes
#--------------------------------------------------------------
resource "aws_eks_addon" "aws_ebs_csi_driver" {
  count = var.enable_aws_ebs_csi_driver ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = var.aws_ebs_csi_driver_version
  preserve      = var.addon_preserve

  # Use IRSA if enabled for fine-grained permissions
  service_account_role_arn = var.enable_irsa && var.create_ebs_csi_driver_service_account_role ? aws_iam_role.ebs_csi_driver[0].arn : null

  tags = var.tags
}

#--------------------------------------------------------------
# EBS CSI Driver IAM Role for Service Account
# Allows driver to create and attach EBS volumes
#--------------------------------------------------------------
resource "aws_iam_role" "ebs_csi_driver" {
  count = var.enable_irsa && var.create_ebs_csi_driver_service_account_role ? 1 : 0

  name = "${var.cluster_name}-ebs-csi-driver-irsa"

  #--------------------------------------------------------------
  # Trust Relationship
  # Allows specific service account to assume this role
  #--------------------------------------------------------------
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks[0].arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks[0].url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  count      = var.enable_irsa && var.create_ebs_csi_driver_service_account_role ? 1 : 0
  role       = aws_iam_role.ebs_csi_driver[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" # AWS-managed policy
}

#==============================================================================
# CloudWatch Logs Integration
# Captures control plane logs for troubleshooting
#==============================================================================
resource "aws_cloudwatch_log_group" "eks" {
  count = length(var.enabled_cluster_log_types) > 0 ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster" # Standard log group naming
  retention_in_days = var.cloudwatch_log_retention_days      # How long to keep logs
  kms_key_id        = var.cloudwatch_log_kms_key_id          # Optional encryption

  tags = var.tags
}

#==============================================================================
# IAM Roles
# Identity and access management for cluster components
#==============================================================================
#--------------------------------------------------------------
# Cluster IAM Role
# Allows EKS to manage AWS resources
#--------------------------------------------------------------
resource "aws_iam_role" "cluster" {
  count = var.create_iam_roles && var.cluster_role_arn == null ? 1 : 0

  name               = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json # Trust policy

  tags = var.tags
}

#--------------------------------------------------------------
# Node IAM Role
# Allows worker nodes to access AWS resources
#--------------------------------------------------------------
resource "aws_iam_role" "node" {
  count = var.create_iam_roles && var.node_role_arn == null ? 1 : 0

  name               = "${var.cluster_name}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json # Trust policy

  tags = var.tags
}

#--------------------------------------------------------------
# Cluster IAM Policies
# Required permissions for EKS control plane
#--------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = var.create_iam_roles && var.cluster_role_arn == null ? aws_iam_role.cluster[0].name : var.cluster_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" # Core EKS permissions
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  role       = var.create_iam_roles && var.cluster_role_arn == null ? aws_iam_role.cluster[0].name : var.cluster_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController" # For managing ENIs
}

#--------------------------------------------------------------
# Node IAM Policies
# Required permissions for worker nodes
#--------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = var.create_iam_roles && var.node_role_arn == null ? aws_iam_role.node[0].name : var.node_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" # For node registration
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = var.create_iam_roles && var.node_role_arn == null ? aws_iam_role.node[0].name : var.node_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy" # For pod networking
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = var.create_iam_roles && var.node_role_arn == null ? aws_iam_role.node[0].name : var.node_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" # For pulling images
}

#==============================================================================
# IAM Policy Documents
# Trust relationships for IAM roles
#==============================================================================
data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"] # Allow EKS service to assume role
    }
  }
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"] # Allow EC2 service to assume role
    }
  }
}

#==============================================================================
# Kubeconfig Generation
# Creates a local configuration file for kubectl
#==============================================================================
resource "null_resource" "generate_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region ${data.aws_region.current.name} --kubeconfig ${path.module}/kubeconfig_${var.cluster_name}"
  }

  depends_on = [aws_eks_cluster.this] # Only generate after cluster exists
}
