# EKS Terraform Module

This module provisions an [Amazon EKS (Elastic Kubernetes Service)](https://aws.amazon.com/eks/) cluster and a managed node group on AWS.

## Features

- Creates an EKS control plane (cluster)
- Provisions a managed node group (worker nodes)
- Configures IAM roles for the cluster and nodes
- Supports custom VPC/subnet configuration
- Encrypts Kubernetes secrets using KMS
- Installs essential EKS add-ons (CoreDNS, kube-proxy, VPC CNI)
- Outputs kubeconfig for easy `kubectl` access

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"  # Adjust path as needed

  cluster_name        = "my-eks-cluster"
  cluster_role_arn    = "arn:aws:iam::123456789012:role/eks-cluster-role"
  node_role_arn       = "arn:aws:iam::123456789012:role/eks-node-role"
  subnet_ids          = ["subnet-abc123", "subnet-def456"]
  kubernetes_version  = "1.29"
  node_desired_size   = 2
  node_max_size       = 3
  node_min_size       = 1
  node_instance_types = ["t3.medium"]
  node_disk_size      = 50
  
  # Optional: Create IAM roles instead of using existing ones
  # create_iam_roles = true
  # cluster_role_name = "my-cluster-role"  # Only needed when create_iam_roles = false
  # node_role_name = "my-node-role"        # Only needed when create_iam_roles = false
  
  # Optional: Provide your own KMS key
  # kms_key_arn = "arn:aws:kms:us-west-2:123456789012:key/abcd1234-a123-456a-a12b-a123b4cd56ef"
  
  tags = {
    Environment = "dev"
    Project     = "k8s-cloud-terraform"
  }
}
```

## Inputs

| Name                | Description                                   | Type           | Default     | Required |
|---------------------|-----------------------------------------------|----------------|-------------|----------|
| cluster_name        | The name of the EKS cluster                   | string         | n/a         | yes      |
| cluster_role_arn    | IAM role ARN for the EKS cluster              | string         | n/a         | yes      |
| node_role_arn       | IAM role ARN for the EKS node group           | string         | n/a         | yes      |
| subnet_ids          | List of subnet IDs for the cluster and nodes  | list(string)   | n/a         | yes      |
| kubernetes_version  | Kubernetes version for the EKS cluster        | string         | "1.29"      | no       |
| node_desired_size   | Desired number of worker nodes                | number         | 2           | no       |
| node_max_size       | Maximum number of worker nodes                | number         | 3           | no       |
| node_min_size       | Minimum number of worker nodes                | number         | 1           | no       |
| node_instance_types | List of EC2 instance types for node group     | list(string)   | ["t3.medium"]| no      |
| node_disk_size      | Disk size in GiB for worker nodes             | number         | 50          | no       |
| node_labels         | Labels to apply to EKS nodes                  | map(string)    | {}          | no       |
| create_iam_roles    | Whether to create IAM roles                   | bool           | false       | no       |
| cluster_role_name   | Name of existing cluster IAM role             | string         | ""          | no       |
| node_role_name      | Name of existing node IAM role                | string         | ""          | no       |
| kms_key_arn         | ARN of KMS key for secret encryption          | string         | null        | no       |
| coredns_version     | Version of CoreDNS add-on                     | string         | null        | no       |
| kube_proxy_version  | Version of kube-proxy add-on                  | string         | null        | no       |
| vpc_cni_version     | Version of VPC CNI add-on                     | string         | null        | no       |
| tags                | Map of tags to assign to resources            | map(string)    | {}          | no       |

## Outputs

| Name                           | Description                                        |
|--------------------------------|----------------------------------------------------|
| cluster_id                     | The EKS cluster ID                                 |
| cluster_endpoint               | The endpoint for the EKS cluster                   |
| cluster_arn                    | The ARN of the EKS cluster                         |
| cluster_version                | The Kubernetes version of the cluster              |
| cluster_certificate_authority_data | Base64 encoded certificate data                |
| cluster_security_group_id      | Security group ID attached to the EKS cluster      |
| node_group_id                  | The EKS node group ID                              |
| node_group_arn                 | The ARN of the EKS node group                      |
| node_group_status              | Status of the EKS node group                       |
| kubeconfig_path                | Path to the generated kubeconfig file              |

## Requirements

- Terraform 1.3+
- AWS provider 5.0+
- Kubernetes provider 2.20+
- Pre-existing IAM roles and VPC subnets (unless create_iam_roles = true)

## License

MIT