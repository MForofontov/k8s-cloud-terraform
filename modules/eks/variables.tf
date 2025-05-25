variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for the EKS node group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster and node group"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "create_iam_roles" {
  description = "Whether to create IAM roles for the EKS cluster and nodes"
  type        = bool
  default     = false
}

variable "cluster_role_name" {
  description = "Name of the IAM role for the EKS cluster (used when create_iam_roles = false)"
  type        = string
  default     = ""
}

variable "node_role_name" {
  description = "Name of the IAM role for the EKS nodes (used when create_iam_roles = false)"
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for encrypting EKS secrets"
  type        = string
  default     = null
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 50
}

variable "node_labels" {
  description = "Labels to apply to EKS nodes"
  type        = map(string)
  default     = {}
}

variable "coredns_version" {
  description = "Version of the CoreDNS add-on"
  type        = string
  default     = null  # null means use the default version
}

variable "kube_proxy_version" {
  description = "Version of the kube-proxy add-on"
  type        = string
  default     = null  # null means use the default version
}

variable "vpc_cni_version" {
  description = "Version of the VPC CNI add-on"
  type        = string
  default     = null  # null means use the default version
}