#==============================================================================
# Kubernetes Addons Module Variables
#
# This file defines the input variables for the Kubernetes Addons module,
# which installs and configures common operational components for Kubernetes
# clusters using Helm charts. Each section controls a specific addon with
# both simple enable/disable flags and detailed configuration options.
#==============================================================================

#==============================================================================
# Global Configuration
# Settings that apply to the entire module and Kubernetes connection
#==============================================================================
variable "kubernetes_config_path" {
  description = "Path to the Kubernetes config file (kubeconfig). If not provided, the provider will use the default location (~/.kube/config). Specify this when using a non-default kubeconfig location."
  type        = string
  default     = null
}

variable "kubernetes_config_context" {
  description = "Kubernetes config context to use for cluster operations. If not provided, the current context from kubeconfig will be used. Helpful when your kubeconfig contains multiple contexts."
  type        = string
  default     = null
}

#==============================================================================
# Metrics Server
# Kubernetes resource metrics collector for horizontal pod autoscaling
#==============================================================================
variable "enable_metrics_server" {
  description = "Whether to install Metrics Server. This component collects resource metrics from kubelets and exposes them through the Kubernetes metrics API for use with HPA and VPA."
  type        = bool
  default     = false
}

variable "metrics_server" {
  description = "Metrics Server configuration options. Controls how the Metrics Server Helm chart is deployed and configured."
  type        = any
  default     = {
    name           = "metrics-server"      # Release name for the Helm deployment
    chart          = "metrics-server"      # The name of the chart to install
    repository     = "https://kubernetes-sigs.github.io/metrics-server/"  # Helm chart repository
    chart_version  = null                  # Specific chart version (null = latest)
    namespace      = "kube-system"         # Kubernetes namespace to install into
    max_history    = 10                    # Number of release versions to retain
    timeout        = 300                   # Timeout in seconds for installation/upgrade
    create_namespace = false               # Whether to create the namespace if it doesn't exist
    set_values     = {}                    # Values to set directly via Helm's --set option
    set            = {}                    # Alternative syntax for setting values
    # values       = ""                    # Path to a values.yaml file for customization
  }
}

#==============================================================================
# Cluster Autoscaler
# Automatically adjusts the size of node pools based on workload demand
#==============================================================================
variable "enable_cluster_autoscaler" {
  description = "Whether to install Cluster Autoscaler. This component automatically adjusts the size of Kubernetes node pools when pods fail to schedule due to resource constraints or nodes are underutilized."
  type        = bool
  default     = false
}

variable "cluster_autoscaler" {
  description = "Cluster Autoscaler configuration options. The autoscaler requires cloud provider-specific settings to access the node group API."
  type        = any
  default     = {
    name           = "cluster-autoscaler"  # Release name for the Helm deployment
    chart          = "cluster-autoscaler"  # The name of the chart to install
    repository     = "https://kubernetes.github.io/autoscaler"  # Helm chart repository
    chart_version  = null                  # Specific chart version (null = latest)
    namespace      = "kube-system"         # Kubernetes namespace to install into
    max_history    = 10                    # Number of release versions to retain
    timeout        = 300                   # Timeout in seconds for installation/upgrade
    create_namespace = false               # Autoscaler typically uses kube-system, which always exists
    set_values     = {}                    # Values to set directly via Helm's --set option
    set            = {}                    # Alternative syntax for setting values
    # values       = ""                    # Path to a values.yaml file for customization
  }
}

#==============================================================================
# NGINX Ingress Controller
# Manages external access to services within the cluster
#==============================================================================
variable "enable_nginx_ingress" {
  description = "Whether to install NGINX Ingress Controller. This component implements an Ingress controller using NGINX as a reverse proxy and load balancer to route HTTP/HTTPS traffic into the cluster."
  type        = bool
  default     = false
}

variable "nginx_ingress" {
  description = "NGINX Ingress Controller configuration options. Controls service type, replica count, annotations, and other ingress-specific settings."
  type        = any
  default     = {
    name           = "nginx-ingress"       # Release name for the Helm deployment
    chart          = "ingress-nginx"       # The name of the chart to install
    repository     = "https://kubernetes.github.io/ingress-nginx"  # Helm chart repository
    chart_version  = null                  # Specific chart version (null = latest)
    namespace      = "ingress-nginx"       # Kubernetes namespace to install into
    max_history    = 10                    # Number of release versions to retain
    timeout        = 300                   # Timeout in seconds for installation/upgrade
    create_namespace = true                # Create a dedicated namespace for isolation
    set_values     = {}                    # Values to set directly via Helm's --set option
    set            = {}                    # Alternative syntax for setting values
    # values       = ""                    # Path to a values.yaml file for customization
  }
}

#==============================================================================
# Cert Manager
# X.509 certificate management for Kubernetes
#==============================================================================
variable "enable_cert_manager" {
  description = "Whether to install Cert Manager. This component automates the management and issuance of TLS certificates from various issuing sources (Let's Encrypt, HashiCorp Vault, etc.)."
  type        = bool
  default     = false
}

variable "cert_manager" {
  description = "Cert Manager configuration options. Controls issuers, certificate resources, and webhook configuration."
  type        = any
  default     = {
    name           = "cert-manager"        # Release name for the Helm deployment
    chart          = "cert-manager"        # The name of the chart to install
    repository     = "https://charts.jetstack.io"  # Helm chart repository
    chart_version  = null                  # Specific chart version (null = latest)
    namespace      = "cert-manager"        # Kubernetes namespace to install into
    max_history    = 10                    # Number of release versions to retain
    timeout        = 300                   # Timeout in seconds for installation/upgrade
    create_namespace = true                # Create a dedicated namespace for isolation
    set_values     = {
      installCRDs = true                   # Automatically install Custom Resource Definitions
    }
    set            = {}                    # Alternative syntax for setting values
    # values       = ""                    # Path to a values.yaml file for customization
  }
}

#==============================================================================
# External DNS
# Synchronizes exposed Kubernetes Services and Ingresses with DNS providers
#==============================================================================
variable "enable_external_dns" {
  description = "Whether to install External DNS. This component automatically configures external DNS servers with information about exposed Kubernetes Services and Ingresses."
  type        = bool
  default     = false
}

variable "external_dns" {
  description = "External DNS configuration options. Requires provider-specific settings (AWS Route53, Google Cloud DNS, etc.) and permissions to modify DNS records."
  type        = any
  default     = {
    name           = "external-dns"        # Release name for the Helm deployment
    chart          = "external-dns"        # The name of the chart to install
    repository     = "https://kubernetes-sigs.github.io/external-dns/"  # Helm chart repository
    chart_version  = null                  # Specific chart version (null = latest)
    namespace      = "external-dns"        # Kubernetes namespace to install into
    max_history    = 10                    # Number of release versions to retain
    timeout        = 300                   # Timeout in seconds for installation/upgrade
    create_namespace = true                # Create a dedicated namespace for isolation
    set_values     = {}                    # Values to set directly via Helm's --set option
    set            = {}                    # Alternative syntax for setting values
    # values       = ""                    # Path to a values.yaml file for customization
  }
}

#==============================================================================
# Prometheus Stack
# Comprehensive monitoring solution with Prometheus, Alertmanager, and Grafana
#==============================================================================
variable "enable_prometheus_stack" {
  description = "Whether to install the Prometheus Operator Stack. This deploys a complete monitoring solution including Prometheus, Alertmanager, Grafana, and default dashboards and alerting rules."
  type        = bool
  default     = false
}

variable "prometheus_stack" {
  description = "Prometheus Stack configuration options. Controls storage configuration, retention, alerting rules, and Grafana settings."
  type        = any
  default     = {
    name           = "prometheus"          # Release name for the Helm deployment
    chart          = "kube-prometheus-stack"  # The name of the chart to install
    repository     = "https://prometheus-community.github.io/helm-charts"  # Helm chart repository
    chart_version  = null                  # Specific chart version (null = latest)
    namespace      = "monitoring"          # Kubernetes namespace to install into
    max_history    = 10                    # Number of release versions to retain
    timeout        = 600                   # Longer timeout due to complex deployment
    create_namespace = true                # Create a dedicated namespace for isolation
    set_values     = {}                    # Values to set directly via Helm's --set option
    set            = {}                    # Alternative syntax for setting values
    # values       = ""                    # Path to a values.yaml file for customization
  }
}

#==============================================================================
# Fluent Bit
# Log processor and forwarder for collecting and shipping logs
#==============================================================================
variable "enable_fluent_bit" {
  description = "Whether to install Fluent Bit for logging. This lightweight log processor and forwarder collects logs from various inputs and routes them to multiple destinations (Elasticsearch, S3, Loki, etc.)."
  type        = bool
  default     = false
}

variable "fluent_bit" {
  description = "Fluent Bit configuration options. Controls log sources, parsers, filters, and output destinations."
  type        = any
  default     = {
    name           = "fluent-bit"          # Release name for the Helm deployment
    chart          = "fluent-bit"          # The name of the chart to install
    repository     = "https://fluent.github.io/helm-charts"  # Helm chart repository
    chart_version  = null                  # Specific chart version (null = latest)
    namespace      = "logging"             # Kubernetes namespace to install into
    max_history    = 10                    # Number of release versions to retain
    timeout        = 300                   # Timeout in seconds for installation/upgrade
    create_namespace = true                # Create a dedicated namespace for isolation
    set_values     = {}                    # Values to set directly via Helm's --set option
    set            = {}                    # Alternative syntax for setting values
    # values       = ""                    # Path to a values.yaml file for customization
  }
}

#==============================================================================
# ArgoCD
# Declarative, GitOps continuous delivery tool for Kubernetes
#==============================================================================
variable "enable_argocd" {
  description = "Whether to install ArgoCD. This GitOps continuous delivery tool automates the deployment of applications to Kubernetes by monitoring Git repositories for changes."
  type        = bool
  default     = false
}

variable "argocd" {
  description = "ArgoCD configuration options. Controls server settings, repositories, SSO integration, and RBAC configuration."
  type        = any
  default     = {
    name           = "argocd"              # Release name for the Helm deployment
    chart          = "argo-cd"             # The name of the chart to install
    repository     = "https://argoproj.github.io/argo-helm"  # Helm chart repository
    chart_version  = null                  # Specific chart version (null = latest)
    namespace      = "argocd"              # Kubernetes namespace to install into
    max_history    = 10                    # Number of release versions to retain
    timeout        = 300                   # Timeout in seconds for installation/upgrade
    create_namespace = true                # Create a dedicated namespace for isolation
    set_values     = {}                    # Values to set directly via Helm's --set option
    set            = {}                    # Alternative syntax for setting values
    # values       = ""                    # Path to a values.yaml file for customization
  }
}

#==============================================================================
# Velero
# Backup and disaster recovery for Kubernetes cluster resources
#==============================================================================
variable "enable_velero" {
  description = "Whether to install Velero for backup and restore. This tool provides disaster recovery capabilities for Kubernetes clusters, backing up cluster resources and persistent volumes."
  type        = bool
  default     = false
}

variable "velero" {
  description = "Velero configuration options. Requires provider-specific settings for backup storage location (e.g., S3 bucket, GCS) and volume snapshots."
  type        = any
  default     = {
    name           = "velero"              # Release name for the Helm deployment
    chart          = "velero"              # The name of the chart to install
    repository     = "https://vmware-tanzu.github.io/helm-charts"  # Helm chart repository
    chart_version  = null                  # Specific chart version (null = latest)
    namespace      = "velero"              # Kubernetes namespace to install into
    max_history    = 10                    # Number of release versions to retain
    timeout        = 300                   # Timeout in seconds for installation/upgrade
    create_namespace = true                # Create a dedicated namespace for isolation
    set_values     = {}                    # Values to set directly via Helm's --set option
    set            = {}                    # Alternative syntax for setting values
    # values       = ""                    # Path to a values.yaml file for customization
  }
}

#==============================================================================
# Sealed Secrets
# Encrypt Kubernetes secrets that are safe to store in version control
#==============================================================================
variable "enable_sealed_secrets" {
  description = "Whether to install Sealed Secrets. This tool allows you to encrypt secrets that are safe to store in Git, solving the problem of securely managing Kubernetes secret objects."
  type        = bool
  default     = false
}

variable "sealed_secrets" {
  description = "Sealed Secrets configuration options. Controls key management, certificate rotation, and secret decryption settings."
  type        = any
  default     = {
    name           = "sealed-secrets"      # Release name for the Helm deployment
    chart          = "sealed-secrets"      # The name of the chart to install
    repository     = "https://bitnami-labs.github.io/sealed-secrets"  # Helm chart repository
    chart_version  = null                  # Specific chart version (null = latest)
    namespace      = "kube-system"         # Kubernetes namespace to install into
    max_history    = 10                    # Number of release versions to retain
    timeout        = 300                   # Timeout in seconds for installation/upgrade
    create_namespace = false               # Uses kube-system, which always exists
    set_values     = {}                    # Values to set directly via Helm's --set option
    set            = {}                    # Alternative syntax for setting values
    # values       = ""                    # Path to a values.yaml file for customization
  }
}

#==============================================================================
# Istio Service Mesh
# Connect, secure, control, and observe services in your Kubernetes cluster
#==============================================================================
variable "enable_istio" {
  description = "Whether to install Istio Service Mesh. This service mesh provides traffic management, security, and observability for microservices running in Kubernetes."
  type        = bool
  default     = false
}

variable "istio" {
  description = "Istio configuration options. Controls all aspects of the service mesh including control plane, data plane, and gateway configuration."
  type        = any
  default     = {
    repository      = "https://istio-release.storage.googleapis.com/charts"  # Helm chart repository
    chart_version   = null                  # Specific chart version (null = latest)
    namespace       = "istio-system"        # Kubernetes namespace to install into
    max_history     = 10                    # Number of release versions to retain
    timeout         = 300                   # Timeout in seconds for installation/upgrade
    create_namespace = true                 # Create a dedicated namespace for isolation
    
    # Base installation (CRDs and cluster resources)
    base_name       = "istio-base"          # Release name for the base Helm deployment
    base_chart      = "base"                # The name of the base chart to install
    base_set_values = {}                    # Values to set directly via Helm's --set option
    base_set        = {}                    # Alternative syntax for setting values
    # base_values   = ""                    # Path to a values.yaml file for customization
    
    # Istiod installation (control plane)
    istiod_name     = "istiod"              # Release name for the istiod Helm deployment
    istiod_chart    = "istiod"              # The name of the istiod chart to install
    istiod_set_values = {}                  # Values to set directly via Helm's --set option
    istiod_set      = {}                    # Alternative syntax for setting values
    # istiod_values = ""                    # Path to a values.yaml file for customization
    
    # Ingress gateway installation (entry point for external traffic)
    enable_ingress  = true                  # Whether to install the Istio ingress gateway
    ingress_name    = "istio-ingress"       # Release name for the ingress Helm deployment
    ingress_chart   = "gateway"             # The name of the gateway chart to install
    ingress_set_values = {}                 # Values to set directly via Helm's --set option
    ingress_set     = {}                    # Alternative syntax for setting values
    # ingress_values = ""                   # Path to a values.yaml file for customization
  }
}