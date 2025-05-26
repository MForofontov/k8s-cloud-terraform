# AWS EKS (Elastic Kubernetes Service) Terraform Module

A comprehensive Terraform module to provision and manage Amazon EKS clusters with advanced configurations.

## Features

- Amazon EKS cluster deployment with flexible configuration options
- Support for both managed node groups and Fargate profiles
- Multiple node groups with different configurations (instance types, capacity types, taints)
- IAM Roles for Service Accounts (IRSA) support via OIDC provider
- Integration with AWS KMS for secrets encryption
- CloudWatch logging for control plane components
- Managed add-ons: CoreDNS, kube-proxy, VPC CNI, and EBS CSI Driver
- Automated kubeconfig generation

## Usage

```hcl
module "eks" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/eks"

  # Required parameters
  cluster_name = "my-eks-cluster"
  subnet_ids   = ["subnet-abcdef1", "subnet-abcdef2", "subnet-abcdef3"]

  # Optional cluster configuration
  kubernetes_version      = "1.28"
  endpoint_private_access = true
  endpoint_public_access  = true
  
  # Logging and monitoring
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  # Default node group
  create_default_node_group = true
  node_instance_types       = ["t3.medium"]
  node_capacity_type        = "ON_DEMAND"
  node_desired_size         = 2
  node_min_size             = 1
  node_max_size             = 4
  
  # Additional node groups
  node_groups = {
    spot-workers = {
      instance_types = ["t3.large", "t3a.large"]
      desired_size   = 2
      min_size       = 1
      max_size       = 10
      capacity_type  = "SPOT"
      labels = {
        workload-type = "spot"
      }
    },
    gpu-workers = {
      instance_types = ["g4dn.xlarge"]
      desired_size   = 1
      min_size       = 0
      max_size       = 3
      labels = {
        workload-type = "gpu"
      }
      taints = [{
        key    = "gpu"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }
  
  # Fargate profiles
  fargate_profiles = {
    serverless = {
      selectors = [
        {
          namespace = "serverless"
        },
        {
          namespace = "kube-system"
          labels = {
            "fargate" = "true"
          }
        }
      ]
    }
  }
  
  # Add-ons
  enable_coredns          = true
  enable_kube_proxy       = true
  enable_vpc_cni          = true
  enable_aws_ebs_csi_driver = true
  
  # IRSA configuration
  enable_irsa = true
  create_vpc_cni_service_account_role = true
  create_ebs_csi_driver_service_account_role = true
  
  tags = {
    Environment = "Production"
    Terraform   = "true"
  }
}

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | ~> 5.50.0 |
| kubernetes | ~> 2.30.0 |
| tls | ~> 4.0.0 |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| cluster_name | Name of the EKS cluster | `string` |
| subnet_ids | List of subnet IDs for the EKS cluster | `list(string)` |

### Optional Cluster Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| kubernetes_version | Kubernetes version to use for the EKS cluster | `string` | `null` (latest) |
| endpoint_private_access | Whether the Amazon EKS private API server endpoint is enabled | `bool` | `true` |
| endpoint_public_access | Whether the Amazon EKS public API server endpoint is enabled | `bool` | `true` |
| public_access_cidrs | List of CIDR blocks that can access the public API server endpoint | `list(string)` | `["0.0.0.0/0"]` |
| security_group_ids | List of security group IDs for cross-account elastic network interfaces | `list(string)` | `[]` |
| enabled_cluster_log_types | List of control plane components to enable logging for | `list(string)` | `["api", "audit"]` |
| kms_key_arn | ARN of the KMS key used to encrypt secrets | `string` | `null` |

### IAM Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| create_iam_roles | Whether IAM roles should be created | `bool` | `true` |
| cluster_role_arn | ARN of the IAM role for the EKS cluster | `string` | `null` |
| cluster_role_name | Name of existing IAM role for the EKS cluster | `string` | `null` |
| node_role_arn | ARN of the IAM role for the EKS node groups | `string` | `null` |
| node_role_name | Name of existing IAM role for the EKS node groups | `string` | `null` |

### Default Node Group Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| create_default_node_group | Whether a default node group should be created | `bool` | `true` |
| node_desired_size | Desired number of nodes in the default node group | `number` | `2` |
| node_max_size | Maximum number of nodes in the default node group | `number` | `3` |
| node_min_size | Minimum number of nodes in the default node group | `number` | `1` |
| node_instance_types | List of instance types for the default node group | `list(string)` | `["t3.medium"]` |
| node_capacity_type | Type of capacity for the default node group (ON_DEMAND, SPOT) | `string` | `"ON_DEMAND"` |
| node_disk_size | Disk size in GiB for the default node group nodes | `number` | `50` |
| node_labels | Labels to apply to the default node group | `map(string)` | `{}` |
| node_taints | Kubernetes taints to apply to the default node group | `list(object)` | `[]` |

### Add-ons Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_coredns | Whether to install the CoreDNS add-on | `bool` | `true` |
| coredns_version | Version of the CoreDNS add-on | `string` | `null` |
| enable_kube_proxy | Whether to install the kube-proxy add-on | `bool` | `true` |
| kube_proxy_version | Version of the kube-proxy add-on | `string` | `null` |
| enable_vpc_cni | Whether to install the VPC CNI add-on | `bool` | `true` |
| vpc_cni_version | Version of the VPC CNI add-on | `string` | `null` |
| enable_aws_ebs_csi_driver | Whether to install the EBS CSI driver add-on | `bool` | `false` |
| aws_ebs_csi_driver_version | Version of the EBS CSI driver add-on | `string` | `null` |
| addon_preserve | Whether to preserve add-on resources on deletion | `bool` | `false` |

### IRSA Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_irsa | Whether to create an OIDC Provider for EKS to enable IRSA | `bool` | `true` |
| create_vpc_cni_service_account_role | Whether to create a service account role for VPC CNI | `bool` | `false` |
| create_ebs_csi_driver_service_account_role | Whether to create a service account role for EBS CSI driver | `bool` | `false` |

### CloudWatch Logs Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| cloudwatch_log_retention_days | Number of days to retain log events in CloudWatch log group | `number` | `90` |
| cloudwatch_log_kms_key_id | KMS key ID to encrypt CloudWatch logs | `string` | `null` |

### Fargate Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| create_fargate_pod_execution_role | Whether to create the Fargate pod execution role | `bool` | `true` |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the EKS cluster |
| cluster_arn | The ARN of the EKS cluster |
| cluster_name | The name of the EKS cluster |
| cluster_endpoint | The endpoint for the Kubernetes API server |
| cluster_certificate_authority | The certificate authority data for the Kubernetes API server |
| cluster_version | The Kubernetes server version of the cluster |
| cluster_security_group_id | The security group ID attached to the EKS cluster |
| oidc_provider_arn | The ARN of the OIDC Provider if enabled |
| oidc_provider_url | The URL of the OIDC Provider if enabled |
| cluster_oidc_issuer_url | The OIDC issuer URL of the EKS cluster |
| default_node_group_id | The ID of the default EKS node group |
| node_groups | Map of all the EKS node groups created |
| fargate_profiles | Map of all the EKS Fargate profiles created |
| kube_config_path | Path to the generated kubeconfig file |
| cloudwatch_log_group_name | The name of the CloudWatch log group for EKS cluster logs |

## License

MIT