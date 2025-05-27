# Kubernetes Addons Variables

# ------------------------
# Global Configuration
# ------------------------
variable "kubernetes_config_path" {
  description = "Path to the kubernetes config file. If not provided, the provider will use the default location"
  type        = string
  default     = null
}

variable "kubernetes_config_context" {
  description = "Kubernetes config context to use. If not provided, the provider will use the current context"
  type        = string
  default     = null
}

# ------------------------
# Metrics Server
# ------------------------
variable "enable_metrics_server" {
  description = "Whether to install Metrics Server"
  type        = bool
  default     = false
}

variable "metrics_server" {
  description = "Metrics Server configuration options"
  type        = any
  default     = {
    name           = "metrics-server"
    chart          = "metrics-server"
    repository     = "https://kubernetes-sigs.github.io/metrics-server/"
    chart_version  = null
    namespace      = "kube-system"
    max_history    = 10
    timeout        = 300
    create_namespace = false
    set_values     = {}
    set            = {}
    # values       = "" # Path to values file
  }
}

# ------------------------
# Cluster Autoscaler
# ------------------------
variable "enable_cluster_autoscaler" {
  description = "Whether to install Cluster Autoscaler"
  type        = bool
  default     = false
}

variable "cluster_autoscaler" {
  description = "Cluster Autoscaler configuration options"
  type        = any
  default     = {
    name           = "cluster-autoscaler"
    chart          = "cluster-autoscaler"
    repository     = "https://kubernetes.github.io/autoscaler"
    chart_version  = null
    namespace      = "kube-system"
    max_history    = 10
    timeout        = 300
    create_namespace = false
    set_values     = {}
    set            = {}
    # values       = "" # Path to values file
  }
}

# ------------------------
# NGINX Ingress Controller
# ------------------------
variable "enable_nginx_ingress" {
  description = "Whether to install NGINX Ingress Controller"
  type        = bool
  default     = false
}

variable "nginx_ingress" {
  description = "NGINX Ingress Controller configuration options"
  type        = any
  default     = {
    name           = "nginx-ingress"
    chart          = "ingress-nginx"
    repository     = "https://kubernetes.github.io/ingress-nginx"
    chart_version  = null
    namespace      = "ingress-nginx"
    max_history    = 10
    timeout        = 300
    create_namespace = true
    set_values     = {}
    set            = {}
    # values       = "" # Path to values file
  }
}

# ------------------------
# Cert Manager
# ------------------------
variable "enable_cert_manager" {
  description = "Whether to install Cert Manager"
  type        = bool
  default     = false
}

variable "cert_manager" {
  description = "Cert Manager configuration options"
  type        = any
  default     = {
    name           = "cert-manager"
    chart          = "cert-manager"
    repository     = "https://charts.jetstack.io"
    chart_version  = null
    namespace      = "cert-manager"
    max_history    = 10
    timeout        = 300
    create_namespace = true
    set_values     = {
      installCRDs = true
    }
    set            = {}
    # values       = "" # Path to values file
  }
}

# ------------------------
# External DNS
# ------------------------
variable "enable_external_dns" {
  description = "Whether to install External DNS"
  type        = bool
  default     = false
}

variable "external_dns" {
  description = "External DNS configuration options"
  type        = any
  default     = {
    name           = "external-dns"
    chart          = "external-dns"
    repository     = "https://kubernetes-sigs.github.io/external-dns/"
    chart_version  = null
    namespace      = "external-dns"
    max_history    = 10
    timeout        = 300
    create_namespace = true
    set_values     = {}
    set            = {}
    # values       = "" # Path to values file
  }
}

# ------------------------
# Prometheus Stack
# ------------------------
variable "enable_prometheus_stack" {
  description = "Whether to install Prometheus Operator (includes Prometheus, Alertmanager, and Grafana)"
  type        = bool
  default     = false
}

variable "prometheus_stack" {
  description = "Prometheus Stack configuration options"
  type        = any
  default     = {
    name           = "prometheus"
    chart          = "kube-prometheus-stack"
    repository     = "https://prometheus-community.github.io/helm-charts"
    chart_version  = null
    namespace      = "monitoring"
    max_history    = 10
    timeout        = 600
    create_namespace = true
    set_values     = {}
    set            = {}
    # values       = "" # Path to values file
  }
}

# ------------------------
# Fluent Bit
# ------------------------
variable "enable_fluent_bit" {
  description = "Whether to install Fluent Bit for logging"
  type        = bool
  default     = false
}

variable "fluent_bit" {
  description = "Fluent Bit configuration options"
  type        = any
  default     = {
    name           = "fluent-bit"
    chart          = "fluent-bit"
    repository     = "https://fluent.github.io/helm-charts"
    chart_version  = null
    namespace      = "logging"
    max_history    = 10
    timeout        = 300
    create_namespace = true
    set_values     = {}
    set            = {}
    # values       = "" # Path to values file
  }
}

# ------------------------
# ArgoCD
# ------------------------
variable "enable_argocd" {
  description = "Whether to install ArgoCD"
  type        = bool
  default     = false
}

variable "argocd" {
  description = "ArgoCD configuration options"
  type        = any
  default     = {
    name           = "argocd"
    chart          = "argo-cd"
    repository     = "https://argoproj.github.io/argo-helm"
    chart_version  = null
    namespace      = "argocd"
    max_history    = 10
    timeout        = 300
    create_namespace = true
    set_values     = {}
    set            = {}
    # values       = "" # Path to values file
  }
}

# ------------------------
# Velero
# ------------------------
variable "enable_velero" {
  description = "Whether to install Velero for backup and restore"
  type        = bool
  default     = false
}

variable "velero" {
  description = "Velero configuration options"
  type        = any
  default     = {
    name           = "velero"
    chart          = "velero"
    repository     = "https://vmware-tanzu.github.io/helm-charts"
    chart_version  = null
    namespace      = "velero"
    max_history    = 10
    timeout        = 300
    create_namespace = true
    set_values     = {}
    set            = {}
    # values       = "" # Path to values file
  }
}

# ------------------------
# Sealed Secrets
# ------------------------
variable "enable_sealed_secrets" {
  description = "Whether to install Sealed Secrets"
  type        = bool
  default     = false
}

variable "sealed_secrets" {
  description = "Sealed Secrets configuration options"
  type        = any
  default     = {
    name           = "sealed-secrets"
    chart          = "sealed-secrets"
    repository     = "https://bitnami-labs.github.io/sealed-secrets"
    chart_version  = null
    namespace      = "kube-system"
    max_history    = 10
    timeout        = 300
    create_namespace = false
    set_values     = {}
    set            = {}
    # values       = "" # Path to values file
  }
}

# ------------------------
# Istio Service Mesh
# ------------------------
variable "enable_istio" {
  description = "Whether to install Istio Service Mesh"
  type        = bool
  default     = false
}

variable "istio" {
  description = "Istio configuration options"
  type        = any
  default     = {
    repository      = "https://istio-release.storage.googleapis.com/charts"
    chart_version   = null
    namespace       = "istio-system"
    max_history     = 10
    timeout         = 300
    create_namespace = true
    
    # Base installation
    base_name       = "istio-base"
    base_chart      = "base"
    base_set_values = {}
    base_set        = {}
    # base_values   = "" # Path to values file
    
    # Istiod installation
    istiod_name     = "istiod"
    istiod_chart    = "istiod"
    istiod_set_values = {}
    istiod_set      = {}
    # istiod_values = "" # Path to values file
    
    # Ingress gateway installation
    enable_ingress  = true
    ingress_name    = "istio-ingress"
    ingress_chart   = "gateway"
    ingress_set_values = {}
    ingress_set     = {}
    # ingress_values = "" # Path to values file
  }
}