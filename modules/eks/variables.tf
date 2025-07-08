#==============================================================================
# Amazon EKS (Elastic Kubernetes Service) Module Variables
#
# This file defines all configuration options for AWS EKS clusters. Variables
# are organized into logical sections and include detailed descriptions,
# defaults, and usage guidance.
#
# The module supports both managed node groups and Fargate profiles, with
# options for customizing IAM roles, networking, add-ons, and security.
#==============================================================================

#==============================================================================
# Required Variables
# These variables must be provided when using this module
#==============================================================================
variable "cluster_name" {
  description = "Name of the EKS cluster. This identifier will be used for AWS resources, logs, and for referencing the cluster in the AWS Console and CLI commands."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster. Must include at least two subnets in different Availability Zones for high availability. These subnets must have the proper tagging for EKS to use them."
  type        = list(string)
}

#==============================================================================
# IAM Role Configuration
# Controls identity and access management for the cluster and nodes
#==============================================================================
variable "create_iam_roles" {
  description = "Determines whether IAM roles should be created by this module. Set to false if you want to use existing roles and provide their ARNs. This allows for separation of duties where IAM administration is handled separately."
  type        = bool
  default     = true
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the EKS cluster. If not provided and create_iam_roles is true, a role with AmazonEKSClusterPolicy will be created. This role is assumed by the EKS service to manage AWS resources for Kubernetes."
  type        = string
  default     = null
}

variable "cluster_role_name" {
  description = "Name of existing IAM role for the EKS cluster, used when attaching policies to an existing role. Only applicable when create_iam_roles is false and you need to attach additional policies to an existing role."
  type        = string
  default     = null
}

variable "node_role_arn" {
  description = "ARN of the IAM role for the EKS node groups. If not provided and create_iam_roles is true, a role with necessary node policies will be created. This role is used by the worker nodes to access AWS services like ECR and CloudWatch."
  type        = string
  default     = null
}

variable "node_role_name" {
  description = "Name of existing IAM role for the EKS node groups, used when attaching policies to an existing role. Only applicable when create_iam_roles is false and you need to attach additional policies to an existing role."
  type        = string
  default     = null
}

#==============================================================================
# Cluster Configuration
# Basic settings for the EKS control plane
#==============================================================================
variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster (e.g., '1.27'). If not specified, the latest available version in AWS will be used. Consider your application compatibility requirements when selecting a version."
  type        = string
  default     = null  # Uses latest by default
}

variable "endpoint_private_access" {
  description = "Indicates whether the Amazon EKS private API server endpoint is enabled. When true, the Kubernetes API server can be accessed from within your VPC. Recommended for production clusters to enhance security by keeping the API server private."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Indicates whether the Amazon EKS public API server endpoint is enabled. When true, the Kubernetes API can be accessed from the internet. Can be disabled for maximum security, but requires VPN or Direct Connect to access the cluster."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the Amazon EKS public API server endpoint. Use this to restrict public access to trusted IP ranges. Defaults to allowing access from anywhere, which is not recommended for production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "security_group_ids" {
  description = "List of security group IDs for the cross-account elastic network interfaces. These security groups control network traffic to the Kubernetes control plane. Leave empty to have EKS create and manage these automatically."
  type        = list(string)
  default     = []
}

variable "enabled_cluster_log_types" {
  description = "List of the desired control plane logging to enable. Valid values: api, audit, authenticator, controllerManager, scheduler. These logs are sent to CloudWatch and are valuable for troubleshooting and compliance."
  type        = list(string)
  default     = ["api", "audit"]
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt Kubernetes secrets. If not provided, a new key will be created. Using a customer-managed KMS key provides additional control over encryption and key rotation policies."
  type        = string
  default     = null
}

#==============================================================================
# Default Node Group Configuration
# Settings for the primary managed node group
#==============================================================================
variable "create_default_node_group" {
  description = "Determines whether a default managed node group should be created. Set to false if you only want to use custom node groups or Fargate profiles defined separately."
  type        = bool
  default     = true
}

variable "node_desired_size" {
  description = "Desired number of nodes in the default node group. This is the initial number of nodes that will be created. Consider your application requirements and high availability needs when setting this value."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes in the default node group. The cluster autoscaler can scale up to this number. Set based on your peak capacity needs and AWS service quotas for EC2 instances."
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of nodes in the default node group. The cluster autoscaler will maintain at least this many nodes. Should be at least 2 for high availability in production environments."
  type        = number
  default     = 1
}

variable "node_instance_types" {
  description = "List of EC2 instance types for the default node group. EKS will select from this list based on availability. Include similar instance types for consistent performance. For production, consider compute-optimized instances."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Type of capacity associated with the default node group. Valid values: ON_DEMAND (reliable but more expensive) or SPOT (lower cost but can be reclaimed). SPOT is suitable for fault-tolerant workloads and significant cost savings."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  description = "Disk size in GiB for the default node group nodes. This disk hosts the container runtime, images, and emptyDir volumes. For production workloads, 50GB+ is recommended to avoid disk pressure."
  type        = number
  default     = 50
}

variable "node_labels" {
  description = "Kubernetes labels to apply to the default node group. These labels can be used for node selection in pod deployments using nodeSelector or node affinity. Example: { 'role': 'general', 'environment': 'prod' }"
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "Kubernetes taints to apply to the default node group. Taints prevent pods from scheduling unless they have matching tolerations. Useful for dedicating nodes to specific workloads or reserving capacity for critical services."
  type        = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default     = []
}

#==============================================================================
# Additional Node Groups
# Configuration for specialized node groups beyond the default
#==============================================================================
variable "node_groups" {
  description = "Map of node group configurations to create. Use this to create specialized pools for different workloads (e.g., compute-intensive, memory-intensive, GPU). Each group can have unique instance types, scaling parameters, and node configurations."
  type        = map(object({
    instance_types = list(string)     # List of EC2 instance types for this node group
    desired_size   = number           # Initial number of nodes
    min_size       = number           # Minimum number of nodes (for autoscaling)
    max_size       = number           # Maximum number of nodes (for autoscaling)
    disk_size      = optional(number, 50)  # Root volume size in GiB
    capacity_type  = optional(string, "ON_DEMAND")  # ON_DEMAND or SPOT
    labels         = optional(map(string), {})  # Kubernetes labels for node selection
    taints         = optional(list(object({
      key    = string  # Taint identifier (e.g., "dedicated")
      value  = string  # Taint value (e.g., "gpu")
      effect = string  # NoSchedule, PreferNoSchedule, or NoExecute
    })), [])
    subnet_ids     = optional(list(string), null)  # Override default subnets if needed
    tags           = optional(map(string), {})  # AWS tags for the node group
  }))
  default     = {}
}

#==============================================================================
# Fargate Configuration
# Serverless compute for Kubernetes pods
#==============================================================================
variable "fargate_profiles" {
  description = "Map of Fargate profile configurations to create. Fargate provides serverless compute for pods, eliminating the need to manage EC2 instances. Define which pods run on Fargate based on namespace and label selectors."
  type        = map(object({
    selectors = list(object({
      namespace = string  # Kubernetes namespace to match (e.g., "kube-system")
      labels    = optional(map(string), null)  # Pod labels to match for Fargate execution
    }))
    subnet_ids             = optional(list(string), null)  # Private subnets for Fargate pods
    pod_execution_role_arn = optional(string, null)  # IAM role for Fargate pods
    tags                   = optional(map(string), {})  # AWS tags for the Fargate profile
  }))
  default     = {}
}

variable "create_fargate_pod_execution_role" {
  description = "Determines whether the Fargate pod execution role should be created. This role is assumed by the Fargate infrastructure and used by pods running on Fargate to access AWS services like ECR."
  type        = bool
  default     = true
}

#==============================================================================
# Add-ons Configuration
# EKS-managed operational components
#==============================================================================
variable "addon_preserve" {
  description = "Indicates if you want to preserve the created resources when deleting the EKS add-on. When true, resources like CoreDNS deployments remain when removing the add-on. Helpful for upgrades or preventing disruption."
  type        = bool
  default     = false
}

variable "enable_coredns" {
  description = "Determines whether the CoreDNS add-on should be installed. CoreDNS provides DNS services within the cluster and is required for internal service discovery. Generally should be enabled unless using a custom DNS solution."
  type        = bool
  default     = true
}

variable "coredns_version" {
  description = "Version of the CoreDNS add-on (e.g., 'v1.10.1-eksbuild.1'). If not specified, EKS will use the default version for your cluster's Kubernetes version. Check compatibility when upgrading Kubernetes."
  type        = string
  default     = null  # Uses latest by default
}

variable "enable_kube_proxy" {
  description = "Determines whether the kube-proxy add-on should be installed. kube-proxy maintains network rules on nodes for pod communication. Required for basic Kubernetes networking functionality."
  type        = bool
  default     = true
}

variable "kube_proxy_version" {
  description = "Version of the kube-proxy add-on (e.g., 'v1.27.4-eksbuild.2'). If not specified, EKS will use the default version for your cluster's Kubernetes version. Should match or be compatible with the cluster version."
  type        = string
  default     = null  # Uses latest by default
}

variable "enable_vpc_cni" {
  description = "Determines whether the VPC CNI add-on should be installed. The Amazon VPC CNI provides pod networking using elastic network interfaces. Required for standard EKS pod networking capabilities."
  type        = bool
  default     = true
}

variable "vpc_cni_version" {
  description = "Version of the VPC CNI add-on (e.g., 'v1.13.2-eksbuild.1'). If not specified, EKS will use the default version. Newer versions support additional features like custom networking and increased pod density."
  type        = string
  default     = null  # Uses latest by default
}

variable "enable_aws_ebs_csi_driver" {
  description = "Determines whether the EBS CSI driver add-on should be installed. This driver enables Kubernetes workloads to use Amazon EBS volumes for persistent storage. Required for dynamic provisioning of EBS volumes."
  type        = bool
  default     = false
}

variable "aws_ebs_csi_driver_version" {
  description = "Version of the EBS CSI driver add-on (e.g., 'v1.19.0-eksbuild.2'). If not specified, EKS will use the default version. Newer versions may support additional features like volume snapshots and resizing."
  type        = string
  default     = null  # Uses latest by default
}

#==============================================================================
# IRSA Configuration
# IAM Roles for Service Accounts integration
#==============================================================================
variable "enable_irsa" {
  description = "Determines whether to create an OpenID Connect Provider for EKS to enable IRSA (IAM Roles for Service Accounts). IRSA allows pods to have fine-grained AWS permissions without using node instance profiles."
  type        = bool
  default     = true
}

variable "create_vpc_cni_service_account_role" {
  description = "Determines whether to create a service account role for the VPC CNI add-on. This allows the CNI plugin to manage ENIs and IP addresses without requiring extensive node permissions."
  type        = bool
  default     = false
}

variable "create_ebs_csi_driver_service_account_role" {
  description = "Determines whether to create a service account role for the EBS CSI driver add-on. This allows the driver to create, attach, and mount EBS volumes without requiring extensive node permissions."
  type        = bool
  default     = false
}

#==============================================================================
# CloudWatch Logs Configuration
# Logging settings for the EKS control plane
#==============================================================================
variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain log events in CloudWatch log group. Higher values increase logging costs but provide longer history for troubleshooting. Common values: 7, 14, 30, 60, 90, 180, 365, 730."
  type        = number
  default     = 90
}

variable "cloudwatch_log_kms_key_id" {
  description = "KMS key ID to encrypt CloudWatch logs. If provided, encrypts all cluster logs with this key for additional security. This must be a customer-managed CMK with appropriate permissions."
  type        = string
  default     = null
}

#==============================================================================
# Resource Tagging
# AWS tags applied to all resources created by this module
#==============================================================================
variable "tags" {
  description = "A map of tags to add to all resources created by this module. These tags help with resource organization, cost allocation, and access control. Common tags include: Environment, Owner, Project, and CostCenter."
  type        = map(string)
  default     = {}
}
