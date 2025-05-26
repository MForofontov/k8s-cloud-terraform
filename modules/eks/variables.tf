// EKS Cluster Variables

# Required Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

# IAM Role Variables
variable "create_iam_roles" {
  description = "Determines whether IAM roles should be created"
  type        = bool
  default     = true
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the EKS cluster. If not provided, one will be created if create_iam_roles is true"
  type        = string
  default     = null
}

variable "cluster_role_name" {
  description = "Name of existing IAM role for the EKS cluster, used when attaching policies to an existing role"
  type        = string
  default     = null
}

variable "node_role_arn" {
  description = "ARN of the IAM role for the EKS node groups. If not provided, one will be created if create_iam_roles is true"
  type        = string
  default     = null
}

variable "node_role_name" {
  description = "Name of existing IAM role for the EKS node groups, used when attaching policies to an existing role"
  type        = string
  default     = null
}

# Cluster Configuration Variables
variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = null  # Uses latest by default
}

variable "endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "security_group_ids" {
  description = "List of security group IDs for the cross-account elastic network interfaces"
  type        = list(string)
  default     = []
}

variable "enabled_cluster_log_types" {
  description = "List of the desired control plane logging to enable: api, audit, authenticator, controllerManager, scheduler"
  type        = list(string)
  default     = ["api", "audit"]
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt secrets. If not provided, a new key will be created"
  type        = string
  default     = null
}

# Default Node Group Variables
variable "create_default_node_group" {
  description = "Determines whether a default node group should be created"
  type        = bool
  default     = true
}

variable "node_desired_size" {
  description = "Desired number of nodes in the default node group"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes in the default node group"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of nodes in the default node group"
  type        = number
  default     = 1
}

variable "node_instance_types" {
  description = "List of instance types for the default node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Type of capacity associated with the default node group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  description = "Disk size in GiB for the default node group nodes"
  type        = number
  default     = 50
}

variable "node_labels" {
  description = "Labels to apply to the default node group"
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "Kubernetes taints to apply to the default node group"
  type        = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default     = []
}

# Additional Node Groups
variable "node_groups" {
  description = "Map of node group configurations to create"
  type        = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = optional(number, 50)
    capacity_type  = optional(string, "ON_DEMAND")
    labels         = optional(map(string), {})
    taints         = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    subnet_ids     = optional(list(string), null)
    tags           = optional(map(string), {})
  }))
  default     = {}
}

# Fargate Configuration
variable "fargate_profiles" {
  description = "Map of Fargate profile configurations to create"
  type        = map(object({
    selectors = list(object({
      namespace = string
      labels    = optional(map(string), null)
    }))
    subnet_ids             = optional(list(string), null)
    pod_execution_role_arn = optional(string, null)
    tags                   = optional(map(string), {})
  }))
  default     = {}
}

variable "create_fargate_pod_execution_role" {
  description = "Determines whether the Fargate pod execution role should be created"
  type        = bool
  default     = true
}

# Add-ons Configuration
variable "addon_preserve" {
  description = "Indicates if you want to preserve the created resources when deleting the EKS add-on"
  type        = bool
  default     = false
}

variable "enable_coredns" {
  description = "Determines whether the CoreDNS add-on should be installed"
  type        = bool
  default     = true
}

variable "coredns_version" {
  description = "Version of the CoreDNS add-on"
  type        = string
  default     = null  # Uses latest by default
}

variable "enable_kube_proxy" {
  description = "Determines whether the kube-proxy add-on should be installed"
  type        = bool
  default     = true
}

variable "kube_proxy_version" {
  description = "Version of the kube-proxy add-on"
  type        = string
  default     = null  # Uses latest by default
}

variable "enable_vpc_cni" {
  description = "Determines whether the VPC CNI add-on should be installed"
  type        = bool
  default     = true
}

variable "vpc_cni_version" {
  description = "Version of the VPC CNI add-on"
  type        = string
  default     = null  # Uses latest by default
}

variable "enable_aws_ebs_csi_driver" {
  description = "Determines whether the EBS CSI driver add-on should be installed"
  type        = bool
  default     = false
}

variable "aws_ebs_csi_driver_version" {
  description = "Version of the EBS CSI driver add-on"
  type        = string
  default     = null  # Uses latest by default
}

# IRSA Configuration
variable "enable_irsa" {
  description = "Determines whether to create an OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

variable "create_vpc_cni_service_account_role" {
  description = "Determines whether to create a service account role for the VPC CNI add-on"
  type        = bool
  default     = false
}

variable "create_ebs_csi_driver_service_account_role" {
  description = "Determines whether to create a service account role for the EBS CSI driver add-on"
  type        = bool
  default     = false
}

# CloudWatch Logs Configuration
variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain log events in CloudWatch log group"
  type        = number
  default     = 90
}

variable "cloudwatch_log_kms_key_id" {
  description = "KMS key ID to encrypt CloudWatch logs"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}