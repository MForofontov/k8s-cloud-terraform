// EKS Cluster Outputs

# Cluster Outputs
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "The certificate authority data for the Kubernetes API server"
  value       = aws_eks_cluster.this.certificate_authority
}

output "cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_platform_version" {
  description = "The platform version for the cluster"
  value       = aws_eks_cluster.this.platform_version
}

output "cluster_status" {
  description = "The status of the EKS cluster"
  value       = aws_eks_cluster.this.status
}

# Security Outputs
output "cluster_security_group_id" {
  description = "The security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for encryption"
  value       = var.kms_key_arn != null ? var.kms_key_arn : try(aws_kms_key.eks[0].arn, null)
}

output "kms_key_id" {
  description = "The ID of the KMS key used for encryption"
  value       = var.kms_key_arn != null ? element(split("/", var.kms_key_arn), 1) : try(aws_kms_key.eks[0].key_id, null)
}

# IAM Outputs
output "cluster_role_arn" {
  description = "The ARN of the IAM role used by the EKS cluster"
  value       = var.cluster_role_arn != null ? var.cluster_role_arn : try(aws_iam_role.cluster[0].arn, null)
}

output "cluster_role_name" {
  description = "The name of the IAM role used by the EKS cluster"
  value       = var.cluster_role_name != null ? var.cluster_role_name : try(aws_iam_role.cluster[0].name, null)
}

output "node_role_arn" {
  description = "The ARN of the IAM role used by the EKS node groups"
  value       = var.node_role_arn != null ? var.node_role_arn : try(aws_iam_role.node[0].arn, null)
}

output "node_role_name" {
  description = "The name of the IAM role used by the EKS node groups"
  value       = var.node_role_name != null ? var.node_role_name : try(aws_iam_role.node[0].name, null)
}

# OIDC Provider Outputs
output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enabled"
  value       = var.enable_irsa ? try(aws_iam_openid_connect_provider.eks[0].arn, null) : null
}

output "oidc_provider_url" {
  description = "The URL of the OIDC Provider if enabled"
  value       = var.enable_irsa ? try(aws_iam_openid_connect_provider.eks[0].url, null) : null
}

output "cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL of the EKS cluster"
  value       = try(aws_eks_cluster.this.identity[0].oidc[0].issuer, null)
}

# Node Groups Outputs
output "default_node_group_id" {
  description = "The ID of the default EKS node group"
  value       = var.create_default_node_group ? try(aws_eks_node_group.default[0].id, null) : null
}

output "default_node_group_arn" {
  description = "The ARN of the default EKS node group"
  value       = var.create_default_node_group ? try(aws_eks_node_group.default[0].arn, null) : null
}

output "default_node_group_status" {
  description = "The status of the default EKS node group"
  value       = var.create_default_node_group ? try(aws_eks_node_group.default[0].status, null) : null
}

output "node_groups" {
  description = "Map of all the EKS node groups created"
  value       = {
    for k, v in aws_eks_node_group.additional : k => {
      id        = v.id
      arn       = v.arn
      status    = v.status
      resources = v.resources
    }
  }
}

# Fargate Profiles Outputs
output "fargate_profiles" {
  description = "Map of all the EKS Fargate profiles created"
  value       = {
    for k, v in aws_eks_fargate_profile.this : k => {
      id     = v.id
      arn    = v.arn
      status = v.status
    }
  }
}

output "fargate_pod_execution_role_arn" {
  description = "The ARN of the Fargate pod execution role"
  value       = var.create_fargate_pod_execution_role ? try(aws_iam_role.fargate_pod_execution[0].arn, null) : null
}

# Add-ons Outputs
output "installed_addons" {
  description = "Map of all the EKS add-ons installed"
  value       = {
    coredns = var.enable_coredns ? {
      id      = try(aws_eks_addon.coredns[0].id, null)
      version = try(aws_eks_addon.coredns[0].addon_version, null)
    } : null
    kube_proxy = var.enable_kube_proxy ? {
      id      = try(aws_eks_addon.kube_proxy[0].id, null)
      version = try(aws_eks_addon.kube_proxy[0].addon_version, null)
    } : null
    vpc_cni = var.enable_vpc_cni ? {
      id      = try(aws_eks_addon.vpc_cni[0].id, null)
      version = try(aws_eks_addon.vpc_cni[0].addon_version, null)
    } : null
    aws_ebs_csi_driver = var.enable_aws_ebs_csi_driver ? {
      id      = try(aws_eks_addon.aws_ebs_csi_driver[0].id, null)
      version = try(aws_eks_addon.aws_ebs_csi_driver[0].addon_version, null)
    } : null
  }
}

# Kubeconfig Output
output "kubeconfig_path" {
  description = "Path to the generated kubeconfig file"
  value       = "${path.module}/kubeconfig_${var.cluster_name}"
}

# CloudWatch Logs Output
output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for EKS cluster logs"
  value       = length(var.enabled_cluster_log_types) > 0 ? try(aws_cloudwatch_log_group.eks[0].name, null) : null
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group for EKS cluster logs"
  value       = length(var.enabled_cluster_log_types) > 0 ? try(aws_cloudwatch_log_group.eks[0].arn, null) : null
}