# EKS Terraform Module

This module provisions an [Amazon EKS (Elastic Kubernetes Service)](https://aws.amazon.com/eks/) cluster and a managed node group on AWS.

## Features

- Creates an EKS control plane (cluster)
- Provisions a managed node group (worker nodes)
- Configures IAM roles for the cluster and nodes
- Supports custom VPC/subnet configuration
- Outputs kubeconfig for easy `kubectl` access

## Usage

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name        = "my-eks-cluster"
  cluster_role_arn    = "arn:aws:iam::123456789012:role/eks-cluster-role"
  node_role_arn       = "arn:aws:iam::123456789012:role/eks-node-role"
  subnet_ids          = ["subnet-abc123", "subnet-def456"]
  kubernetes_version  = "1.29"
  node_desired_size   = 2
  node_max_size       = 3
  node_min_size       = 1
  node_instance_types = ["t3.medium"]
  tags = {
    Environment = "dev"
    Project     = "k8s-cloud-terraform"
  }
}
```

## Inputs

| Name                | Description                                   | Type           | Default     |
|---------------------|-----------------------------------------------|----------------|-------------|
| cluster_name        | The name of the EKS cluster                   | string         | n/a         |
| cluster_role_arn    | IAM role ARN for the EKS cluster              | string         | n/a         |
| node_role_arn       | IAM role ARN for the EKS node group           | string         | n/a         |
| subnet_ids          | List of subnet IDs for the cluster and nodes  | list(string)   | n/a         |
| kubernetes_version  | Kubernetes version for the EKS cluster        | string         | "1.29"      |
| node_desired_size   | Desired number of worker nodes                | number         | 2           |
| node_max_size       | Maximum number of worker nodes                | number         | 3           |
| node_min_size       | Minimum number of worker nodes                | number         | 1           |
| node_instance_types | List of EC2 instance types for node group     | list(string)   | ["t3.medium"]|
| tags                | Map of tags to assign to resources            | map(string)    | {}          |

## Outputs

| Name             | Description                              |
|------------------|------------------------------------------|
| cluster_id       | The EKS cluster ID                       |
| cluster_endpoint | The endpoint for the EKS cluster         |
| cluster_arn      | The ARN of the EKS cluster               |
| cluster_version  | The Kubernetes version of the cluster    |
| node_group_id    | The EKS node group ID                    |
| node_group_arn   | The ARN of the EKS node group            |
| kubeconfig_file  | Path to the generated kubeconfig file    |

## Requirements

- Terraform 1.3+
- AWS provider 5.0+
- IAM roles and subnets must be pre-created

## License

MIT