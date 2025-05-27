#==============================================================================
# Amazon EKS (Elastic Kubernetes Service) Module Outputs
#
# This file defines all output values provided by the EKS module. These outputs
# enable interaction with the provisioned cluster, integration with other AWS
# services, and access to important resource identifiers.
#
# Outputs are organized by resource type and include identifiers, endpoints,
# credentials, and status information that can be used for monitoring,
# automation, and application deployment.
#==============================================================================

#==============================================================================
# Core Cluster Information
# Basic details about the provisioned EKS cluster
#==============================================================================
output "cluster_id" {
  description = "The ID of the EKS cluster. Use this unique identifier when referencing the cluster in AWS CLI commands, API calls, or when integrating with other AWS services that require the cluster ID."
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the EKS cluster. This is the fully qualified ARN used for IAM policies, cross-account access, and when working with AWS APIs that require ARNs instead of names or IDs."
  value       = aws_eks_cluster.this.arn
}

output "cluster_name" {
  description = "The name of the EKS cluster. This is the human-readable identifier used in the AWS console, CloudWatch logs, and for tagging related resources. Use this when working with kubectl and other Kubernetes tools."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "The endpoint URL for the Kubernetes API server. This is the primary connection point for kubectl and other Kubernetes API clients. Required for configuring kubectl access and generating kubeconfig files."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "The certificate authority data for the Kubernetes API server in base64-encoded format. This certificate is required for secure communication with the cluster API and is used in kubeconfig files to verify the server's identity."
  value       = aws_eks_cluster.this.certificate_authority
}

output "cluster_version" {
  description = "The Kubernetes server version running on the cluster (e.g., '1.27'). Important for compatibility with kubectl versions, helm charts, and operators. Also useful for planning upgrades and ensuring application compatibility."
  value       = aws_eks_cluster.this.version
}

output "cluster_platform_version" {
  description = "The platform version for the EKS cluster (e.g., 'eks.23'). This represents the underlying platform capabilities and features available to the cluster. Different from the Kubernetes version and useful for tracking AWS-specific features."
  value       = aws_eks_cluster.this.platform_version
}

output "cluster_status" {
  description = "The current status of the EKS cluster (e.g., 'ACTIVE', 'CREATING', 'UPDATING', 'DELETING', 'FAILED'). Useful for monitoring during cluster operations and for ensuring the cluster is available before deploying applications."
  value       = aws_eks_cluster.this.status
}

#==============================================================================
# Security Configuration
# Security-related outputs for the EKS cluster
#==============================================================================
output "cluster_security_group_id" {
  description = "The ID of the security group automatically created and managed by EKS for the cluster. This security group controls communication between the control plane and worker nodes. Use when configuring additional security groups or network policies."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for encrypting Kubernetes secrets. This key is critical for the secure storage of sensitive information in the cluster. Either provided by the user or created by this module if encryption is enabled."
  value       = var.kms_key_arn != null ? var.kms_key_arn : try(aws_kms_key.eks[0].arn, null)
}

output "kms_key_id" {
  description = "The ID of the KMS key used for encryption (without the key ARN prefix). Some AWS services and APIs require the key ID rather than the full ARN. Extracted from the full ARN for convenience."
  value       = var.kms_key_arn != null ? element(split("/", var.kms_key_arn), 1) : try(aws_kms_key.eks[0].key_id, null)
}

#==============================================================================
# IAM Configuration
# Identity and access management details
#==============================================================================
output "cluster_role_arn" {
  description = "The ARN of the IAM role assumed by the EKS service to manage AWS resources for Kubernetes. This role defines what AWS resources the Kubernetes control plane can access. Used when creating IAM policies that reference this role."
  value       = var.cluster_role_arn != null ? var.cluster_role_arn : try(aws_iam_role.cluster[0].arn, null)
}

output "cluster_role_name" {
  description = "The name of the IAM role used by the EKS cluster. Useful when you need to attach additional policies to the cluster role or for auditing purposes. Either provided by the user or created by this module."
  value       = var.cluster_role_name != null ? var.cluster_role_name : try(aws_iam_role.cluster[0].name, null)
}

output "node_role_arn" {
  description = "The ARN of the IAM role used by all EKS node groups in this cluster. This role defines what AWS resources the worker nodes can access, such as ECR repositories and CloudWatch logs. Required when creating additional node groups."
  value       = var.node_role_arn != null ? var.node_role_arn : try(aws_iam_role.node[0].arn, null)
}

output "node_role_name" {
  description = "The name of the IAM role used by the EKS node groups. Useful when you need to attach additional policies to node instances or for auditing purposes. Either provided by the user or created by this module."
  value       = var.node_role_name != null ? var.node_role_name : try(aws_iam_role.node[0].name, null)
}

#==============================================================================
# OIDC Provider Information
# Details for IAM Roles for Service Accounts (IRSA)
#==============================================================================
output "oidc_provider_arn" {
  description = "The ARN of the IAM OIDC Provider created for the cluster. Required when setting up IAM Roles for Service Accounts (IRSA) to grant AWS permissions to Kubernetes service accounts. Only available when IRSA is enabled."
  value       = var.enable_irsa ? try(aws_iam_openid_connect_provider.eks[0].arn, null) : null
}

output "oidc_provider_url" {
  description = "The URL of the IAM OIDC Provider. Used in IAM role trust relationships when creating roles for service accounts. This URL uniquely identifies the Kubernetes service account issuer. Only available when IRSA is enabled."
  value       = var.enable_irsa ? try(aws_iam_openid_connect_provider.eks[0].url, null) : null
}

output "cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL of the EKS cluster (without the 'https://' prefix). This is the raw issuer URL from the cluster configuration, which may be needed for certain integrations. Used as the subject in OIDC token validation."
  value       = try(aws_eks_cluster.this.identity[0].oidc[0].issuer, null)
}

#==============================================================================
# Node Group Information
# Details about the Kubernetes worker nodes
#==============================================================================
output "default_node_group_id" {
  description = "The ID of the default EKS managed node group. Use this identifier when referencing the node group in automation scripts or when tracking node group operations. Only available if the default node group is created."
  value       = var.create_default_node_group ? try(aws_eks_node_group.default[0].id, null) : null
}

output "default_node_group_arn" {
  description = "The ARN of the default EKS managed node group. This is the fully qualified ARN used for IAM policies and when working with AWS APIs that require ARNs. Only available if the default node group is created."
  value       = var.create_default_node_group ? try(aws_eks_node_group.default[0].arn, null) : null
}

output "default_node_group_status" {
  description = "The current status of the default node group (e.g., 'ACTIVE', 'CREATING', 'UPDATING', 'DELETING'). Useful for monitoring during node group operations and ensuring nodes are available before deploying workloads."
  value       = var.create_default_node_group ? try(aws_eks_node_group.default[0].status, null) : null
}

output "node_groups" {
  description = "Map of all additional EKS node groups created beyond the default. Keys are node group names and values contain details like ID, ARN, status, and resources. Useful for tracking multiple specialized node groups and their current states."
  value       = {
    for k, v in aws_eks_node_group.additional : k => {
      id        = v.id
      arn       = v.arn
      status    = v.status
      resources = v.resources
    }
  }
}

#==============================================================================
# Fargate Profile Information
# Details about serverless compute for pods
#==============================================================================
output "fargate_profiles" {
  description = "Map of all EKS Fargate profiles created. Keys are profile names and values contain details like ID, ARN, and status. Use this to track which namespaces and workloads are configured to run on Fargate instead of EC2 nodes."
  value       = {
    for k, v in aws_eks_fargate_profile.this : k => {
      id     = v.id
      arn    = v.arn
      status = v.status
    }
  }
}

output "fargate_pod_execution_role_arn" {
  description = "The ARN of the IAM role used by Fargate to run pods. This role determines what AWS resources pods running on Fargate can access. Required when creating additional Fargate profiles or when setting up custom Fargate configurations."
  value       = var.create_fargate_pod_execution_role ? try(aws_iam_role.fargate_pod_execution[0].arn, null) : null
}

#==============================================================================
# EKS Add-ons Information
# Details about installed operational components
#==============================================================================
output "installed_addons" {
  description = "Map of all EKS add-ons installed on the cluster with their IDs and versions. Includes CoreDNS, kube-proxy, VPC CNI, and the EBS CSI driver if enabled. Useful for tracking which add-ons are active and their current versions for compatibility planning."
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

#==============================================================================
# Access Configuration
# Resources for accessing and interacting with the cluster
#==============================================================================
output "kubeconfig_path" {
  description = "File system path to the generated kubeconfig file. This file contains cluster credentials and configuration needed by kubectl and other Kubernetes tools. Set the KUBECONFIG environment variable to this path for easy cluster access."
  value       = "${path.module}/kubeconfig_${var.cluster_name}"
}

#==============================================================================
# Monitoring and Logging
# Observability resources for the EKS cluster
#==============================================================================
output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group where EKS control plane logs are sent. Use this to find logs in the CloudWatch console or when configuring log-based alerts and metrics. Only available if cluster logging is enabled."
  value       = length(var.enabled_cluster_log_types) > 0 ? try(aws_cloudwatch_log_group.eks[0].name, null) : null
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group for EKS control plane logs. Use this when setting up cross-account log sharing, creating custom metrics from logs, or configuring advanced log processing. Only available if cluster logging is enabled."
  value       = length(var.enabled_cluster_log_types) > 0 ? try(aws_cloudwatch_log_group.eks[0].arn, null) : null
}