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

variable "cluster_context" {
  description = "Cluster context information to enable smart defaults based on environment and cloud provider"
  type = object({
    cloud_provider = string         # aws, azure, gcp
    cluster_size   = string         # small, medium, large
    region         = string
    environment    = string         # dev, staging, prod
    is_production  = bool
  })
  default = {
    cloud_provider = "aws"
    cluster_size   = "medium"
    region         = "us-west-2"
    environment    = "dev"
    is_production  = false
  }

  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cluster_context.cloud_provider)
    error_message = "The cloud_provider value must be one of: aws, azure, gcp."
  }

  validation {
    condition     = contains(["small", "medium", "large"], var.cluster_context.cluster_size)
    error_message = "The cluster_size value must be one of: small, medium, large."
  }

  validation {
    condition     = contains(["dev", "staging", "prod"], var.cluster_context.environment)
    error_message = "The environment value must be one of: dev, staging, prod."
  }
}

variable "storage_class" {
  description = "Default storage class to use for persistent volumes. If not specified, the module will use cloud provider-specific defaults."
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
  type = object({
    name               = optional(string, "metrics-server")
    chart              = optional(string, "metrics-server")
    repository         = optional(string, "https://kubernetes-sigs.github.io/metrics-server/")
    chart_version      = optional(string)
    namespace          = optional(string, "kube-system")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, false)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), {})
    set                = optional(map(string), {})
  })
  default = {}
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
  type = object({
    name               = optional(string, "cluster-autoscaler")
    chart              = optional(string, "cluster-autoscaler")
    repository         = optional(string, "https://kubernetes.github.io/autoscaler")
    chart_version      = optional(string)
    namespace          = optional(string, "kube-system")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, false)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), {})
    set                = optional(map(string), {})

    # Cloud provider-specific settings
    aws_config = optional(object({
      auto_discovery = optional(bool, true)
      cluster_name   = optional(string)
      region         = optional(string)
      role_arn       = optional(string)
      expander       = optional(string, "least-waste")
    }))

    azure_config = optional(object({
      node_resource_group = optional(string)
      subscription_id     = optional(string)
      tenant_id           = optional(string)
      client_id           = optional(string)
      client_secret       = optional(string)
      cluster_name        = optional(string)
    }))

    gcp_config = optional(object({
      project_id   = optional(string)
      location     = optional(string)
      cluster_name = optional(string)
      node_pool_patterns = optional(list(string), [".*"])
    }))
  })
  default = {}
}

#==============================================================================
# Karpenter
# Next-generation Kubernetes autoscaler for on-demand node provisioning
#==============================================================================
variable "enable_karpenter" {
  description = "Whether to install Karpenter. This next-generation Kubernetes autoscaler provides just-in-time compute resource scaling with fast node provisioning and efficient bin-packing."
  type        = bool
  default     = false
}

variable "karpenter" {
  description = "Karpenter configuration options. Controls how this next-generation node provisioner works with your cloud provider and node provisioning requirements."
  type = object({
    name               = optional(string, "karpenter")
    chart              = optional(string, "karpenter")
    repository         = optional(string, "https://charts.karpenter.sh")
    chart_version      = optional(string)
    namespace          = optional(string, "karpenter")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, true)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), {})
    set                = optional(map(string), {})

    # Cloud provider settings
    aws_config = optional(object({
      cluster_name        = optional(string)
      cluster_endpoint    = optional(string)
      instance_profile    = optional(string)
      interrupt_queue_name = optional(string)
    }))

    # Default provisioner settings
    provisioner = optional(object({
      create_default     = optional(bool, true)
      default_name       = optional(string, "default")
      instance_families  = optional(list(string), ["c5", "m5", "r5", "t3"])
      instance_sizes     = optional(list(string), ["large", "xlarge", "2xlarge"])
      availability_zones = optional(list(string))
      ttl_seconds_after_empty = optional(number, 30)
      ttl_seconds_until_expired = optional(number, 604800) # 7 days
    }))
  })
  default = {}
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
  type = object({
    name               = optional(string, "nginx-ingress")
    chart              = optional(string, "ingress-nginx")
    repository         = optional(string, "https://kubernetes.github.io/ingress-nginx")
    chart_version      = optional(string)
    namespace          = optional(string, "ingress-nginx")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, true)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), {})
    set                = optional(map(string), {})

    # Controller configuration
    controller = optional(object({
      replicas          = optional(number)
      service_type      = optional(string, "LoadBalancer")
      use_proxy_protocol = optional(bool, false)
      use_host_port     = optional(bool, false)
      publish_service   = optional(bool, true)
      internal          = optional(bool, false)
      enable_metrics    = optional(bool, true)

      resources = optional(object({
        requests = optional(object({
          cpu    = optional(string, "100m")
          memory = optional(string, "128Mi")
        }))
        limits = optional(object({
          cpu    = optional(string, "200m")
          memory = optional(string, "256Mi")
        }))
      }))
    }))
  })
  default = {}
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
  type = object({
    name               = optional(string, "cert-manager")
    chart              = optional(string, "cert-manager")
    repository         = optional(string, "https://charts.jetstack.io")
    chart_version      = optional(string)
    namespace          = optional(string, "cert-manager")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, true)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), { installCRDs = true })
    set                = optional(map(string), {})

    # Cluster issuers configuration
    cluster_issuers = optional(object({
      create_selfsigned_issuer = optional(bool, true)
      create_letsencrypt_issuer = optional(bool, false)
      letsencrypt_email = optional(string)
      letsencrypt_server = optional(string, "https://acme-v02.api.letsencrypt.org/directory")
      letsencrypt_solvers = optional(list(object({
        dns01 = optional(object({
          provider = string
          config = map(string)
        }))
        http01 = optional(object({
          ingress_class = optional(string, "nginx")
        }))
      })))
    }))

    # Resource usage settings
    resources = optional(object({
      requests = optional(object({
        cpu    = optional(string, "10m")
        memory = optional(string, "32Mi")
      }))
      limits = optional(object({
        cpu    = optional(string, "100m")
        memory = optional(string, "128Mi")
      }))
    }))
  })
  default = {}
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
  type = object({
    name               = optional(string, "external-dns")
    chart              = optional(string, "external-dns")
    repository         = optional(string, "https://kubernetes-sigs.github.io/external-dns/")
    chart_version      = optional(string)
    namespace          = optional(string, "external-dns")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, true)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), {})
    set                = optional(map(string), {})

    # Provider configuration
    provider_config = optional(object({
      provider           = optional(string)  # aws, google, azure, etc.
      domain_filters     = optional(list(string), [])
      exclude_domains    = optional(list(string), [])
      txt_owner_id       = optional(string)
      txt_prefix         = optional(string)
      registry           = optional(string, "txt")
      policy             = optional(string, "upsert-only")

      # AWS specific
      aws_zone_type      = optional(string)  # public, private
      aws_assume_role    = optional(string)
      aws_batch_change_size = optional(number, 1000)

      # Azure specific
      azure_resource_group = optional(string)
      azure_subscription_id = optional(string)
      azure_tenant_id    = optional(string)

      # Google specific
      google_project     = optional(string)
    }))

    # Resource usage settings
    resources = optional(object({
      requests = optional(object({
        cpu    = optional(string, "50m")
        memory = optional(string, "64Mi")
      }))
      limits = optional(object({
        cpu    = optional(string, "100m")
        memory = optional(string, "128Mi")
      }))
    }))
  })
  default = {}
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
  type = object({
    name               = optional(string, "prometheus")
    chart              = optional(string, "kube-prometheus-stack")
    repository         = optional(string, "https://prometheus-community.github.io/helm-charts")
    chart_version      = optional(string)
    namespace          = optional(string, "monitoring")
    max_history        = optional(number, 10)
    timeout            = optional(number, 600)  # Longer timeout due to complex deployment
    create_namespace   = optional(bool, true)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    wait_for_jobs      = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), {})
    set                = optional(map(string), {})

    # Prometheus server configuration
    prometheus = optional(object({
      retention        = optional(string, "10d")
      scrape_interval  = optional(string, "30s")
      evaluation_interval = optional(string, "30s")
      enable_remote_write = optional(bool, false)
      remote_write_urls = optional(list(string), [])

      # Storage configuration
      storage = optional(object({
        size           = optional(string, "50Gi")
        storage_class  = optional(string)
        retention_size = optional(string, "50GiB")
      }))

      # Resource usage settings
      resources = optional(object({
        requests = optional(object({
          cpu    = optional(string, "300m")
          memory = optional(string, "512Mi")
        }))
        limits = optional(object({
          cpu    = optional(string, "1000m")
          memory = optional(string, "1Gi")
        }))
      }))
    }))

    # Alertmanager configuration
    alertmanager = optional(object({
      enabled          = optional(bool, true)
      replicas         = optional(number)
      retention        = optional(string, "120h")

      # Storage configuration
      storage = optional(object({
        size          = optional(string, "10Gi")
        storage_class = optional(string)
      }))

      # Resource usage settings
      resources = optional(object({
        requests = optional(object({
          cpu    = optional(string, "100m")
          memory = optional(string, "128Mi")
        }))
        limits = optional(object({
          cpu    = optional(string, "200m")
          memory = optional(string, "256Mi")
        }))
      }))
    }))

    # Grafana configuration
    grafana = optional(object({
      enabled         = optional(bool, true)
      admin_password  = optional(string, "prom-operator")
      admin_user      = optional(string, "admin")

      # Ingress configuration
      ingress = optional(object({
        enabled      = optional(bool, false)
        hostname     = optional(string)
        path         = optional(string, "/")
        tls_enabled  = optional(bool, true)
        tls_secret   = optional(string)
        annotations  = optional(map(string), {})
      }))

      # Resource usage settings
      resources = optional(object({
        requests = optional(object({
          cpu    = optional(string, "100m")
          memory = optional(string, "128Mi")
        }))
        limits = optional(object({
          cpu    = optional(string, "200m")
          memory = optional(string, "256Mi")
        }))
      }))

      # Persistent storage
      persistence = optional(object({
        enabled      = optional(bool, true)
        size         = optional(string, "10Gi")
        storage_class = optional(string)
      }))
    }))
  })
  default = {}
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
  type = object({
    name               = optional(string, "fluent-bit")
    chart              = optional(string, "fluent-bit")
    repository         = optional(string, "https://fluent.github.io/helm-charts")
    chart_version      = optional(string)
    namespace          = optional(string, "logging")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, true)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), {})
    set                = optional(map(string), {})

    # Output configuration
    outputs = optional(object({
      # Elasticsearch output
      elasticsearch = optional(object({
        enabled     = optional(bool, false)
        host        = optional(string)
        port        = optional(number, 9200)
        index       = optional(string, "kubernetes_cluster")
        type        = optional(string, "_doc")
        http_user   = optional(string)
        http_passwd = optional(string)
        tls         = optional(bool, false)
      }))

      # Amazon CloudWatch Logs output
      cloudwatch = optional(object({
        enabled     = optional(bool, false)
        region      = optional(string)
        log_group_name = optional(string)
        log_stream_name = optional(string)
        auto_create_group = optional(bool, true)
      }))

      # Loki output
      loki = optional(object({
        enabled     = optional(bool, false)
        host        = optional(string)
        port        = optional(number, 3100)
        tenant_id   = optional(string)
        labels      = optional(map(string), {})
      }))

      # S3 output
      s3 = optional(object({
        enabled     = optional(bool, false)
        bucket      = optional(string)
        region      = optional(string)
        total_file_size = optional(string, "10M")
        upload_timeout = optional(string, "10m")
      }))
    }))

    # Resource usage settings
    resources = optional(object({
      requests = optional(object({
        cpu    = optional(string, "50m")
        memory = optional(string, "64Mi")
      }))
      limits = optional(object({
        cpu    = optional(string, "100m")
        memory = optional(string, "128Mi")
      }))
    }))
  })
  default = {}
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
  type = object({
    name               = optional(string, "argocd")
    chart              = optional(string, "argo-cd")
    repository         = optional(string, "https://argoproj.github.io/argo-helm")
    chart_version      = optional(string)
    namespace          = optional(string, "argocd")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, true)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), {})
    set                = optional(map(string), {})

    # Server configuration
    server = optional(object({
      replicas         = optional(number)

      # Ingress configuration
      ingress = optional(object({
        enabled        = optional(bool, false)
        hostname       = optional(string)
        path           = optional(string, "/")
        tls_enabled    = optional(bool, true)
        tls_secret     = optional(string)
        annotations    = optional(map(string), {})
      }))

      # Resource usage settings
      resources = optional(object({
        requests = optional(object({
          cpu    = optional(string, "100m")
          memory = optional(string, "128Mi")
        }))
        limits = optional(object({
          cpu    = optional(string, "200m")
          memory = optional(string, "256Mi")
        }))
      }))
    }))

    # Authentication and SSO
    auth = optional(object({
      admin_password     = optional(string)
      sso = optional(object({
        enabled          = optional(bool, false)
        provider         = optional(string)  # github, gitlab, microsoft, etc.
        client_id        = optional(string)
        client_secret    = optional(string)
        groups           = optional(list(string), [])
      }))
    }))

    # Git repositories
    repositories = optional(map(object({
      url              = string
      username         = optional(string)
      password         = optional(string)
      ssh_private_key  = optional(string)
      insecure         = optional(bool, false)
    })), {})
  })
  default = {}
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
  type = object({
    name               = optional(string, "velero")
    chart              = optional(string, "velero")
    repository         = optional(string, "https://vmware-tanzu.github.io/helm-charts")
    chart_version      = optional(string)
    namespace          = optional(string, "velero")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, true)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), {})
    set                = optional(map(string), {})

    # Backup storage location configuration
    backup_storage = optional(object({
      provider         = optional(string)  # aws, gcp, azure, etc.

      # AWS S3 configuration
      aws = optional(object({
        bucket         = optional(string)
        region         = optional(string)
        s3_url         = optional(string)
        kms_key_id     = optional(string)
      }))

      # Azure Blob Storage configuration
      azure = optional(object({
        resource_group  = optional(string)
        storage_account = optional(string)
        subscription_id = optional(string)
        bucket          = optional(string)
      }))

      # Google Cloud Storage configuration
      gcp = optional(object({
        bucket         = optional(string)
        project        = optional(string)
      }))
    }))

    # Volume snapshot provider configuration
    snapshot_provider = optional(object({
      provider         = optional(string)  # aws, gcp, azure, etc.

      # AWS EBS configuration
      aws = optional(object({
        region         = optional(string)
      }))

      # Azure Disk configuration
      azure = optional(object({
        resource_group  = optional(string)
        subscription_id = optional(string)
      }))

      # Google Persistent Disk configuration
      gcp = optional(object({
        project        = optional(string)
      }))
    }))

    # Backup schedules
    schedules = optional(map(object({
      schedule         = string  # cron format, e.g., "0 1 * * *" for daily at 1:00 AM
      template = optional(object({
        ttl            = optional(string, "720h")  # 30 days
        includedNamespaces = optional(list(string), ["*"])
        excludedNamespaces = optional(list(string), [])
        includedResources = optional(list(string), ["*"])
        excludedResources = optional(list(string), [])
        includeClusterResources = optional(bool, true)
        snapshotVolumes = optional(bool, true)
      }))
    })), {})

    # Resource usage settings
    resources = optional(object({
      requests = optional(object({
        cpu    = optional(string, "50m")
        memory = optional(string, "128Mi")
      }))
      limits = optional(object({
        cpu    = optional(string, "100m")
        memory = optional(string, "256Mi")
      }))
    }))
  })
  default = {}
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
  type = object({
    name               = optional(string, "sealed-secrets")
    chart              = optional(string, "sealed-secrets")
    repository         = optional(string, "https://bitnami-labs.github.io/sealed-secrets")
    chart_version      = optional(string)
    namespace          = optional(string, "kube-system")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, false)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), {})
    set                = optional(map(string), {})

    # Key management configuration
    key_management = optional(object({
      enable_key_rotation = optional(bool, true)
      rotation_period     = optional(string, "30d")
      key_ttl             = optional(string, "180d")
    }))

    # Resource usage settings
    resources = optional(object({
      requests = optional(object({
        cpu    = optional(string, "50m")
        memory = optional(string, "64Mi")
      }))
      limits = optional(object({
        cpu    = optional(string, "100m")
        memory = optional(string, "128Mi")
      }))
    }))
  })
  default = {}
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
  type = object({
    repository         = optional(string, "https://istio-release.storage.googleapis.com/charts")
    chart_version      = optional(string)
    namespace          = optional(string, "istio-system")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, true)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)

    # Base installation (CRDs and cluster resources)
    base_name          = optional(string, "istio-base")
    base_chart         = optional(string, "base")
    base_values        = optional(string, "")
    base_set_values    = optional(map(any), {})
    base_set           = optional(map(string), {})

    # Istiod installation (control plane)
    istiod_name        = optional(string, "istiod")
    istiod_chart       = optional(string, "istiod")
    istiod_values      = optional(string, "")
    istiod_set_values  = optional(map(any), {})
    istiod_set         = optional(map(string), {})

    # Ingress gateway installation (entry point for external traffic)
    enable_ingress     = optional(bool, true)
    ingress_name       = optional(string, "istio-ingress")
    ingress_chart      = optional(string, "gateway")
    ingress_values     = optional(string, "")
    ingress_set_values = optional(map(any), {})
    ingress_set        = optional(map(string), {})

    # Mesh configuration
    mesh_config = optional(object({
      enable_auto_injection = optional(bool, false)
      default_namespace_injection = optional(bool, false)
      mtls_mode          = optional(string, "PERMISSIVE")  # PERMISSIVE, STRICT
      enable_tracing     = optional(bool, false)
      tracing_provider   = optional(string, "jaeger")  # jaeger, zipkin, datadog
      enable_access_logs = optional(bool, true)
    }))

    # Resource usage settings
    resources = optional(object({
      istiod = optional(object({
        requests = optional(object({
          cpu    = optional(string, "500m")
          memory = optional(string, "2Gi")
        }))
        limits = optional(object({
          cpu    = optional(string, "1000m")
          memory = optional(string, "4Gi")
        }))
      }))

      ingress = optional(object({
        requests = optional(object({
          cpu    = optional(string, "100m")
          memory = optional(string, "128Mi")
        }))
        limits = optional(object({
          cpu    = optional(string, "2000m")
          memory = optional(string, "1Gi")
        }))
      }))
    }))
  })
  default = {}
}

#==============================================================================
# Kyverno
# Policy Management Engine for Kubernetes
#==============================================================================
variable "enable_kyverno" {
  description = "Whether to install Kyverno. This policy engine for Kubernetes provides policy management capabilities for validating, mutating, and generating resources."
  type        = bool
  default     = false
}

variable "kyverno" {
  description = "Kyverno configuration options. Controls the policy engine's behavior, webhook settings, and reporting features."
  type = object({
    name               = optional(string, "kyverno")
    chart              = optional(string, "kyverno")
    repository         = optional(string, "https://kyverno.github.io/kyverno/")
    chart_version      = optional(string)
    namespace          = optional(string, "kyverno")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, true)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), {})
    set                = optional(map(string), {})

    # Policy configuration
    policies = optional(object({
      enable_default_policies = optional(bool, false)
      require_pod_probes      = optional(bool, false)
      require_pod_requests_limits = optional(bool, false)
      require_latest_tag      = optional(bool, true)
      require_namespace_labels = optional(bool, false)
      restrict_repository_prefixes = optional(bool, false)
      allowed_repositories    = optional(list(string), [])
      allowed_registries      = optional(list(string), [])
    }))

    # Policy reporter configuration
    policy_reporter = optional(object({
      enabled        = optional(bool, true)
      ui_enabled     = optional(bool, true)
      prometheus     = optional(bool, true)
    }))

    # Resource usage settings
    resources = optional(object({
      requests = optional(object({
        cpu    = optional(string, "100m")
        memory = optional(string, "128Mi")
      }))
      limits = optional(object({
        cpu    = optional(string, "1000m")
        memory = optional(string, "512Mi")
      }))
    }))
  })
  default = {}
}

#==============================================================================
# Crossplane
# Universal Control Plane for Cloud Resources
#==============================================================================
variable "enable_crossplane" {
  description = "Whether to install Crossplane. This Kubernetes extension makes it possible to provision and manage cloud infrastructure, services, and applications using Kubernetes-style APIs."
  type        = bool
  default     = false
}

variable "crossplane" {
  description = "Crossplane configuration options. Controls providers, compositions, and integration with cloud services."
  type = object({
    name               = optional(string, "crossplane")
    chart              = optional(string, "crossplane")
    repository         = optional(string, "https://charts.crossplane.io/stable")
    chart_version      = optional(string)
    namespace          = optional(string, "crossplane-system")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, true)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), {})
    set                = optional(map(string), {})

    # Provider configuration
    providers = optional(object({
      aws = optional(object({
        enabled        = optional(bool, false)
        version        = optional(string, "v0.36.0")
        credentials_secret_name = optional(string)
      }))

      azure = optional(object({
        enabled        = optional(bool, false)
        version        = optional(string, "v0.19.0")
        credentials_secret_name = optional(string)
      }))

      gcp = optional(object({
        enabled        = optional(bool, false)
        version        = optional(string, "v0.21.0")
        credentials_secret_name = optional(string)
      }))

      kubernetes = optional(object({
        enabled        = optional(bool, false)
        version        = optional(string, "v0.5.0")
      }))

      helm = optional(object({
        enabled        = optional(bool, false)
        version        = optional(string, "v0.13.0")
      }))
    }))

    # Resource usage settings
    resources = optional(object({
      requests = optional(object({
        cpu    = optional(string, "100m")
        memory = optional(string, "256Mi")
      }))
      limits = optional(object({
        cpu    = optional(string, "500m")
        memory = optional(string, "512Mi")
      }))
    }))
  })
  default = {}
}

#==============================================================================
# AWS Load Balancer Controller
# AWS-specific controller for managing Elastic Load Balancers
#==============================================================================
variable "enable_aws_load_balancer_controller" {
  description = "Whether to install AWS Load Balancer Controller. This controller manages AWS Elastic Load Balancers for Kubernetes Services with more efficient management than the in-tree provider."
  type        = bool
  default     = false
}

variable "aws_load_balancer_controller" {
  description = "AWS Load Balancer Controller configuration options. Requires AWS-specific settings and permissions."
  type = object({
    name               = optional(string, "aws-load-balancer-controller")
    chart              = optional(string, "aws-load-balancer-controller")
    repository         = optional(string, "https://aws.github.io/eks-charts")
    chart_version      = optional(string)
    namespace          = optional(string, "kube-system")
    max_history        = optional(number, 10)
    timeout            = optional(number, 300)
    create_namespace   = optional(bool, false)
    atomic             = optional(bool, true)
    cleanup_on_fail    = optional(bool, true)
    wait               = optional(bool, true)
    values             = optional(string, "")
    set_values         = optional(map(any), {})
    set                = optional(map(string), {})

    # AWS configuration
    aws_config = optional(object({
      cluster_name     = string
      region           = optional(string)
      vpc_id           = optional(string)
      service_account = optional(object({
        create         = optional(bool, true)
        name           = optional(string, "aws-load-balancer-controller")
        annotations    = optional(map(string), {})
      }))
    }))

    # Controller configuration
    controller_config = optional(object({
      enable_shield        = optional(bool, false)
      enable_waf           = optional(bool, false)
      enable_wafv2         = optional(bool, false)
      ingress_class        = optional(string, "alb")
      default_tags         = optional(map(string), {})
      sync_period          = optional(string, "1h")
    }))

    # Resource usage settings
    resources = optional(object({
      requests = optional(object({
        cpu    = optional(string, "100m")
        memory = optional(string, "128Mi")
      }))
      limits = optional(object({
        cpu    = optional(string, "200m")
        memory = optional(string, "256Mi")
      }))
    }))
  })
  default = {}

  validation {
    condition     = var.enable_aws_load_balancer_controller == false || try(var.aws_load_balancer_controller.aws_config.cluster_name, null) != null
    error_message = "When AWS Load Balancer Controller is enabled, aws_config.cluster_name must be specified."
  }
}