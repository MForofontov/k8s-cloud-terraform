# EKS (Elastic Kubernetes Service) Terraform Module

A comprehensive Terraform module to provision and manage production-ready Amazon EKS clusters with advanced configurations for networking, security, scalability, and operations.

## Features

- **Cluster Flexibility**: Configure both regional and multi-AZ clusters with customizable node groups
- **Advanced Networking**: VPC-native configuration with private/public endpoint control and security group management
- **Security Hardening**: KMS encryption for secrets, OIDC identity provider, and fine-grained IAM controls
- **Multi-tier Node Groups**: Create specialized node pools with different configurations for diverse workloads
- **Spot Instance Support**: Cost optimization with Spot instances for fault-tolerant workloads
- **Serverless Kubernetes**: Support for Fargate profiles to run pods without managing EC2 instances
- **Managed Add-ons**: Simplified deployment of core operational components (CoreDNS, kube-proxy, VPC CNI, EBS CSI driver)
- **IAM Integration**: Support for IAM Roles for Service Accounts (IRSA) for fine-grained pod permissions
- **Comprehensive Monitoring**: CloudWatch logs integration with customizable retention policies
- **Production Ready**: Implements AWS best practices for enterprise Kubernetes deployments

## Supported Features

| Feature | Support | Description |
|---------|:-------:|-------------|
| **Managed Node Groups** | ✅ | EC2-based worker nodes with automatic lifecycle management |
| **Fargate Profiles** | ✅ | Serverless compute for selected workloads based on namespace/labels |
| **Private Cluster** | ✅ | Control plane with private endpoint access only |
| **Hybrid Access** | ✅ | Control plane with both private and restricted public access |
| **KMS Encryption** | ✅ | Envelope encryption for Kubernetes secrets with customer-managed keys |
| **CloudWatch Logging** | ✅ | Control plane logging with configurable log types and retention |
| **IAM Roles for Service Accounts** | ✅ | Fine-grained AWS permissions for Kubernetes service accounts |
| **EKS Add-ons** | ✅ | Managed operational components with simplified lifecycle |
| **Custom IAM Roles** | ✅ | Support for both module-created and externally managed IAM roles |
| **Mixed Instance Types** | ✅ | Node groups with multiple instance type options for cost/performance balance |
| **Spot Instances** | ✅ | Support for lower-cost Spot instances for fault-tolerant workloads |
| **Node Labels & Taints** | ✅ | Kubernetes node organization with custom labels and scheduling controls |
| **Auto-scaling** | ✅ | Dynamic node count based on workload demands |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | ~> 5.104.0 |
| kubernetes | ~> 2.42.0 |
| tls | ~> 4.2.0 |

## Usage

### Basic Cluster with Default Node Group

```hcl
module "eks" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/eks"

  # Required parameters
  cluster_name = "production-cluster"
  subnet_ids   = ["subnet-abcdef123", "subnet-xyz789456"]

  # Cluster configuration
  kubernetes_version = "1.27"
  
  # Default node group
  create_default_node_group = true
  node_desired_size = 2
  node_max_size     = 4
  node_min_size     = 1
  node_instance_types = ["t3.large"]
  
  # Enable CloudWatch logging
  enabled_cluster_log_types = ["api", "audit", "authenticator"]
  
  # Add tags
  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

### Multi-tier Node Groups with Spot Instances

```hcl
module "eks" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/eks"

  cluster_name = "multi-tier-cluster"
  subnet_ids   = ["subnet-abcdef123", "subnet-xyz789456"]
  
  # Default system node group (on-demand for stability)
  create_default_node_group = true
  node_desired_size = 2
  node_instance_types = ["t3.medium"]
  node_labels = {
    "node.kubernetes.io/purpose" = "system"
  }
  
  # Additional specialized node groups
  node_groups = {
    # Application workloads - using on-demand instances
    apps = {
      instance_types = ["m5.large"]
      desired_size   = 3
      min_size       = 2
      max_size       = 6
      labels = {
        "node.kubernetes.io/purpose" = "application"
      }
    },
    
    # Batch processing workloads - using spot instances for cost savings
    batch = {
      instance_types = ["c5.large", "c5a.large", "c6i.large"]
      desired_size   = 0
      min_size       = 0
      max_size       = 10
      capacity_type  = "SPOT"
      labels = {
        "node.kubernetes.io/purpose" = "batch"
      }
      taints = [{
        key    = "workload"
        value  = "batch"
        effect = "NoSchedule"
      }]
    }
  }
  
  # Enable IRSA for fine-grained permissions
  enable_irsa = true
  
  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

### Private Cluster with Fargate Profiles

```hcl
module "eks" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/eks"

  cluster_name = "private-fargate-cluster"
  subnet_ids   = ["subnet-private1", "subnet-private2"]
  
  # Private cluster configuration
  endpoint_private_access = true
  endpoint_public_access  = false
  
  # Encryption for Kubernetes secrets
  # kms_key_arn = "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  
  # Disable default node group - use Fargate only
  create_default_node_group = false
  
  # Fargate profiles
  fargate_profiles = {
    system = {
      selectors = [
        {
          namespace = "kube-system"
        },
        {
          namespace = "kubernetes-dashboard"
        }
      ]
    },
    applications = {
      selectors = [
        {
          namespace = "default"
        },
        {
          namespace = "production"
          labels = {
            "fargate" = "true"
          }
        }
      ]
    }
  }
  
  # Enable all default add-ons
  enable_coredns = true
  enable_kube_proxy = true
  enable_vpc_cni = true
  
  # Enable CloudWatch logging with 30-day retention
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_retention_days = 30
  
  tags = {
    Environment = "production"
    Terraform   = "true"
    Network     = "private"
  }
}
```

## Input Variables

### Required Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cluster_name` | Name of the EKS cluster | `string` | n/a | yes |
| `subnet_ids` | List of subnet IDs for the EKS cluster | `list(string)` | n/a | yes |

### IAM Role Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `create_iam_roles` | Whether to create IAM roles | `bool` | `true` | no |
| `cluster_role_arn` | ARN of IAM role for EKS cluster | `string` | `null` | no |
| `cluster_role_name` | Name of existing IAM role for EKS cluster | `string` | `null` | no |
| `node_role_arn` | ARN of IAM role for EKS node groups | `string` | `null` | no |
| `node_role_name` | Name of existing IAM role for EKS node groups | `string` | `null` | no |

### Cluster Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `kubernetes_version` | Kubernetes version for the cluster | `string` | `null` | no |
| `endpoint_private_access` | Whether to enable private API server endpoint | `bool` | `true` | no |
| `endpoint_public_access` | Whether to enable public API server endpoint | `bool` | `true` | no |
| `public_access_cidrs` | CIDR blocks that can access the public endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| `security_group_ids` | Security group IDs for the control plane ENIs | `list(string)` | `[]` | no |
| `enabled_cluster_log_types` | Control plane logging to enable | `list(string)` | `["api", "audit"]` | no |
| `kms_key_arn` | KMS key ARN for secrets encryption | `string` | `null` | no |

### Default Node Group Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `create_default_node_group` | Whether to create default node group | `bool` | `true` | no |
| `node_desired_size` | Desired node count in default group | `number` | `2` | no |
| `node_max_size` | Maximum node count in default group | `number` | `3` | no |
| `node_min_size` | Minimum node count in default group | `number` | `1` | no |
| `node_instance_types` | EC2 instance types for default group | `list(string)` | `["t3.medium"]` | no |
| `node_capacity_type` | Capacity type (ON_DEMAND or SPOT) | `string` | `"ON_DEMAND"` | no |
| `node_disk_size` | Node disk size in GiB | `number` | `50` | no |
| `node_labels` | Kubernetes labels for default nodes | `map(string)` | `{}` | no |
| `node_taints` | Kubernetes taints for default nodes | `list(object)` | `[]` | no |

### Additional Node Groups

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `node_groups` | Map of node group configurations | `map(object)` | `{}` | no |

### Fargate Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `fargate_profiles` | Map of Fargate profile configurations | `map(object)` | `{}` | no |
| `create_fargate_pod_execution_role` | Whether to create Fargate pod execution role | `bool` | `true` | no |

### Add-ons Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `addon_preserve` | Whether to preserve add-on resources on deletion | `bool` | `false` | no |
| `enable_coredns` | Whether to install CoreDNS add-on | `bool` | `true` | no |
| `coredns_version` | Version of CoreDNS add-on | `string` | `null` | no |
| `enable_kube_proxy` | Whether to install kube-proxy add-on | `bool` | `true` | no |
| `kube_proxy_version` | Version of kube-proxy add-on | `string` | `null` | no |
| `enable_vpc_cni` | Whether to install VPC CNI add-on | `bool` | `true` | no |
| `vpc_cni_version` | Version of VPC CNI add-on | `string` | `null` | no |
| `enable_aws_ebs_csi_driver` | Whether to install EBS CSI driver add-on | `bool` | `false` | no |
| `aws_ebs_csi_driver_version` | Version of EBS CSI driver add-on | `string` | `null` | no |

### IRSA Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `enable_irsa` | Whether to enable IAM Roles for Service Accounts | `bool` | `true` | no |
| `create_vpc_cni_service_account_role` | Whether to create IRSA role for VPC CNI | `bool` | `false` | no |
| `create_ebs_csi_driver_service_account_role` | Whether to create IRSA role for EBS CSI driver | `bool` | `false` | no |

### CloudWatch Logs Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cloudwatch_log_retention_days` | Number of days to retain CloudWatch logs | `number` | `90` | no |
| `cloudwatch_log_kms_key_id` | KMS key ID for CloudWatch logs encryption | `string` | `null` | no |

### Resource Tagging

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `tags` | Map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

### Core Cluster Information

| Name | Description |
|------|-------------|
| `cluster_id` | The ID of the EKS cluster |
| `cluster_arn` | The Amazon Resource Name (ARN) of the cluster |
| `cluster_name` | The name of the EKS cluster |
| `cluster_endpoint` | The endpoint URL for the Kubernetes API server |
| `cluster_certificate_authority` | The certificate authority data for the cluster |
| `cluster_version` | The Kubernetes version running on the cluster |
| `cluster_platform_version` | The platform version for the EKS cluster |
| `cluster_status` | The current status of the EKS cluster |

### Security Configuration

| Name | Description |
|------|-------------|
| `cluster_security_group_id` | The ID of the EKS cluster security group |
| `kms_key_arn` | The ARN of the KMS key used for encrypting Kubernetes secrets |
| `kms_key_id` | The ID of the KMS key used for encryption |

### IAM Configuration

| Name | Description |
|------|-------------|
| `cluster_role_arn` | The ARN of the IAM role used by the EKS service |
| `cluster_role_name` | The name of the IAM role used by the EKS cluster |
| `node_role_arn` | The ARN of the IAM role used by EKS node groups |
| `node_role_name` | The name of the IAM role used by the EKS node groups |

### OIDC Provider Information

| Name | Description |
|------|-------------|
| `oidc_provider_arn` | The ARN of the OIDC Provider for IRSA |
| `oidc_provider_url` | The URL of the OIDC Provider |
| `cluster_oidc_issuer_url` | The OIDC issuer URL of the cluster |

### Node Group Information

| Name | Description |
|------|-------------|
| `default_node_group_id` | The ID of the default EKS node group |
| `default_node_group_arn` | The ARN of the default EKS node group |
| `default_node_group_status` | The status of the default node group |
| `node_groups` | Map of all additional EKS node groups |

### Fargate Profile Information

| Name | Description |
|------|-------------|
| `fargate_profiles` | Map of all Fargate profiles with details |
| `fargate_pod_execution_role_arn` | The ARN of the pod execution role for Fargate |

### EKS Add-ons Information

| Name | Description |
|------|-------------|
| `installed_addons` | Map of all EKS add-ons with their IDs and versions |

### Access Configuration

| Name | Description |
|------|-------------|
| `kubeconfig_path` | Path to the generated kubeconfig file |

### Monitoring and Logging

| Name | Description |
|------|-------------|
| `cloudwatch_log_group_name` | The name of the CloudWatch log group |
| `cloudwatch_log_group_arn` | The ARN of the CloudWatch log group |

## License

This module is released under the MIT License.
