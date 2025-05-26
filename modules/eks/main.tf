// EKS Cluster Terraform Module

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.0"
    }
  }
}

data "aws_region" "current" {}

# Create EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn != null ? var.cluster_role_arn : aws_iam_role.cluster[0].arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids      = var.security_group_ids
    public_access_cidrs     = var.public_access_cidrs
  }

  # Enable EKS cluster logging
  enabled_cluster_log_types = var.enabled_cluster_log_types

  # Enable encryption for secrets
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.eks[0].arn
    }
  }

  tags = merge(
    var.tags,
    {
      "Name" = var.cluster_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups
  lifecycle {
    create_before_destroy = true
  }
}

# Create KMS key if not provided
resource "aws_kms_key" "eks" {
  count                   = var.kms_key_arn == null ? 1 : 0
  description             = "KMS key for EKS cluster ${var.cluster_name} secrets encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "eks" {
  count         = var.kms_key_arn == null ? 1 : 0
  name          = "alias/${var.cluster_name}-eks-secrets"
  target_key_id = aws_kms_key.eks[0].key_id
}

# Default node group if specified
resource "aws_eks_node_group" "default" {
  count = var.create_default_node_group ? 1 : 0

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-default"
  node_role_arn   = var.node_role_arn != null ? var.node_role_arn : aws_iam_role.node[0].arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.node_instance_types
  capacity_type  = var.node_capacity_type
  disk_size      = var.node_disk_size
  labels         = var.node_labels
  
  dynamic "taint" {
    for_each = var.node_taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-default-node-group"
    }
  )

  # Ensure IAM role has proper policies
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# Additional node groups
resource "aws_eks_node_group" "additional" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = var.node_role_arn != null ? var.node_role_arn : aws_iam_role.node[0].arn
  subnet_ids      = each.value.subnet_ids != null ? each.value.subnet_ids : var.subnet_ids

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size
  labels         = each.value.labels
  
  dynamic "taint" {
    for_each = each.value.taints != null ? each.value.taints : []
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-${each.key}-node-group"
    },
    each.value.tags != null ? each.value.tags : {}
  )

  # Ensure IAM role has proper policies
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# Fargate Profiles
resource "aws_eks_fargate_profile" "this" {
  for_each = var.fargate_profiles

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = each.key
  pod_execution_role_arn = var.create_fargate_pod_execution_role ? aws_iam_role.fargate_pod_execution[0].arn : each.value.pod_execution_role_arn
  subnet_ids             = each.value.subnet_ids != null ? each.value.subnet_ids : var.subnet_ids

  dynamic "selector" {
    for_each = each.value.selectors
    content {
      namespace = selector.value.namespace
      labels    = lookup(selector.value, "labels", null)
    }
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-${each.key}-fargate-profile"
    },
    each.value.tags != null ? each.value.tags : {}
  )
}

# Fargate Pod Execution Role
resource "aws_iam_role" "fargate_pod_execution" {
  count = var.create_fargate_pod_execution_role ? 1 : 0
  
  name = "${var.cluster_name}-fargate-pod-execution-role"
  
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
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# OIDC Provider for Service Account IAM Roles
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  count = var.enable_irsa ? 1 : 0
  
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  
  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-eks-irsa"
    }
  )
}

# Add core EKS add-ons
resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns ? 1 : 0
  
  cluster_name      = aws_eks_cluster.this.name
  addon_name        = "coredns"
  addon_version     = var.coredns_version
  preserve          = var.addon_preserve
  
  tags = var.tags
}

resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_kube_proxy ? 1 : 0
  
  cluster_name      = aws_eks_cluster.this.name
  addon_name        = "kube-proxy"
  addon_version     = var.kube_proxy_version
  preserve          = var.addon_preserve
  
  tags = var.tags
}

resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni ? 1 : 0
  
  cluster_name      = aws_eks_cluster.this.name
  addon_name        = "vpc-cni"
  addon_version     = var.vpc_cni_version
  preserve          = var.addon_preserve
  
  # Set service account role ARN if IRSA is enabled and CNI IAM role is provided
  service_account_role_arn = var.enable_irsa && var.create_vpc_cni_service_account_role ? aws_iam_role.vpc_cni[0].arn : null
  
  tags = var.tags
}

# VPC CNI IAM Role for Service Account
resource "aws_iam_role" "vpc_cni" {
  count = var.enable_irsa && var.create_vpc_cni_service_account_role ? 1 : 0
  
  name = "${var.cluster_name}-vpc-cni-irsa"
  
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
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Observability Add-ons
resource "aws_eks_addon" "aws_ebs_csi_driver" {
  count = var.enable_aws_ebs_csi_driver ? 1 : 0
  
  cluster_name      = aws_eks_cluster.this.name
  addon_name        = "aws-ebs-csi-driver"
  addon_version     = var.aws_ebs_csi_driver_version
  preserve          = var.addon_preserve
  
  # Set service account role ARN if IRSA is enabled
  service_account_role_arn = var.enable_irsa && var.create_ebs_csi_driver_service_account_role ? aws_iam_role.ebs_csi_driver[0].arn : null
  
  tags = var.tags
}

# EBS CSI Driver IAM Role for Service Account
resource "aws_iam_role" "ebs_csi_driver" {
  count = var.enable_irsa && var.create_ebs_csi_driver_service_account_role ? 1 : 0
  
  name = "${var.cluster_name}-ebs-csi-driver-irsa"
  
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
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# CloudWatch Logs Integration
resource "aws_cloudwatch_log_group" "eks" {
  count = length(var.enabled_cluster_log_types) > 0 ? 1 : 0
  
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.cloudwatch_log_kms_key_id
  
  tags = var.tags
}

# Create IAM roles if requested
resource "aws_iam_role" "cluster" {
  count = var.create_iam_roles && var.cluster_role_arn == null ? 1 : 0
  
  name               = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
  
  tags = var.tags
}

resource "aws_iam_role" "node" {
  count = var.create_iam_roles && var.node_role_arn == null ? 1 : 0
  
  name               = "${var.cluster_name}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
  
  tags = var.tags
}

# IAM role policies for the cluster
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = var.create_iam_roles && var.cluster_role_arn == null ? aws_iam_role.cluster[0].name : var.cluster_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  role       = var.create_iam_roles && var.cluster_role_arn == null ? aws_iam_role.cluster[0].name : var.cluster_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# IAM role policies for the nodes
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = var.create_iam_roles && var.node_role_arn == null ? aws_iam_role.node[0].name : var.node_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = var.create_iam_roles && var.node_role_arn == null ? aws_iam_role.node[0].name : var.node_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = var.create_iam_roles && var.node_role_arn == null ? aws_iam_role.node[0].name : var.node_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM policy documents
data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Correct way to generate kubeconfig
resource "null_resource" "generate_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region ${data.aws_region.current.name} --kubeconfig ${path.module}/kubeconfig_${var.cluster_name}"
  }

  depends_on = [aws_eks_cluster.this]
}