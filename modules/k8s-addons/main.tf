#==============================================================================
# Kubernetes Addons Module
#
# This module provides a unified interface for deploying common operational
# add-ons to Kubernetes clusters using Helm charts. It follows a consistent
# pattern where each addon:
#   - Can be enabled/disabled via a boolean flag
#   - Has sensible defaults that work out-of-the-box
#   - Allows detailed configuration via variable objects
#   - Supports custom values files and individual value overrides
#
# The module supports both operational tools (monitoring, logging) and
# platform extensions (ingress, service mesh, GitOps).
#==============================================================================

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.0"  # Required for server-side apply and CRD handling
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"   # Required for proper release management
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"  # Used for applying custom resources when needed
    }
  }
  required_version = ">= 1.0.0"
}

# Local variables for dynamic resource sizing and cloud provider optimizations
locals {
  # Scale timeouts and resource requests based on cluster size
  timeouts = {
    small  = 300
    medium = 600
    large  = 900
  }

  # Default timeout based on cluster context or medium if not provided
  default_timeout = try(local.timeouts[var.cluster_context.cluster_size], local.timeouts["medium"])

  # Default storage classes by cloud provider
  default_storage_class = {
    aws   = "gp2"
    azure = "managed-premium"
    gcp   = "standard"
  }

  # Selected storage class based on cloud provider or user override
  storage_class = var.storage_class != null ? var.storage_class : try(
    local.default_storage_class[var.cluster_context.cloud_provider],
    "standard"
  )

  # Determine if running in a production environment
  is_production = try(var.cluster_context.is_production, false)

  # High availability settings based on environment
  high_availability = {
    enabled = local.is_production
    replicas = local.is_production ? 3 : 1
    topology_spread = local.is_production
  }
}

#==============================================================================
# Metrics Server
# Collects resource metrics from kubelets for horizontal pod autoscaling,
# vertical pod autoscaling, and displaying resource usage in the dashboard.
#==============================================================================
resource "helm_release" "metrics_server" {
  # Only deploy if explicitly enabled
  count       = var.enable_metrics_server ? 1 : 0

  # Chart details with fallbacks to default values if not specified
  name        = lookup(var.metrics_server, "name", "metrics-server")
  chart       = lookup(var.metrics_server, "chart", "metrics-server")
  repository  = lookup(var.metrics_server, "repository", "https://kubernetes-sigs.github.io/metrics-server/")
  version     = lookup(var.metrics_server, "chart_version", null)  # null = latest version

  # Deployment configuration
  namespace   = lookup(var.metrics_server, "namespace", "kube-system")  # Uses kube-system by default
  max_history = lookup(var.metrics_server, "max_history", 10)  # Keep history of 10 releases for rollbacks
  timeout     = lookup(var.metrics_server, "timeout", local.default_timeout)
  create_namespace = lookup(var.metrics_server, "create_namespace", false)  # kube-system exists by default

  # Deployment safety options
  atomic          = lookup(var.metrics_server, "atomic", true)
  cleanup_on_fail = lookup(var.metrics_server, "cleanup_on_fail", true)
  wait            = lookup(var.metrics_server, "wait", true)

  # Values configuration supports both file-based and direct value settings
  values = [
    # Use custom values file if provided, otherwise empty string
    lookup(var.metrics_server, "values", "") != "" ? file(var.metrics_server.values) : "",
    # Convert map of values to YAML for Helm
    yamlencode(lookup(var.metrics_server, "set_values", {}))
  ]

  # Dynamically set individual values (alternative to set_values for complex cases)
  dynamic "set" {
    for_each = lookup(var.metrics_server, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

#==============================================================================
# Cluster Autoscaler
# Automatically adjusts the size of the Kubernetes cluster when:
# - pods fail to schedule due to insufficient resources
# - nodes are underutilized and can be removed
#==============================================================================
resource "helm_release" "cluster_autoscaler" {
  count       = var.enable_cluster_autoscaler ? 1 : 0
  name        = lookup(var.cluster_autoscaler, "name", "cluster-autoscaler")
  chart       = lookup(var.cluster_autoscaler, "chart", "cluster-autoscaler")
  repository  = lookup(var.cluster_autoscaler, "repository", "https://kubernetes.github.io/autoscaler")
  version     = lookup(var.cluster_autoscaler, "chart_version", null)
  namespace   = lookup(var.cluster_autoscaler, "namespace", "kube-system")
  max_history = lookup(var.cluster_autoscaler, "max_history", 10)
  timeout     = lookup(var.cluster_autoscaler, "timeout", local.default_timeout)
  create_namespace = lookup(var.cluster_autoscaler, "create_namespace", false)

  # Deployment safety options
  atomic          = lookup(var.cluster_autoscaler, "atomic", true)
  cleanup_on_fail = lookup(var.cluster_autoscaler, "cleanup_on_fail", true)
  wait            = lookup(var.cluster_autoscaler, "wait", true)

  # Values must be cloud-provider specific (AWS, Azure, GCP) to work correctly
  values = [
    lookup(var.cluster_autoscaler, "values", "") != "" ? file(var.cluster_autoscaler.values) : "",
    yamlencode(lookup(var.cluster_autoscaler, "set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.cluster_autoscaler, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

#==============================================================================
# Karpenter - Next-generation Kubernetes autoscaler (alternative to cluster-autoscaler)
# Provides just-in-time capacity for workloads with:
# - Rapid provisioning of nodes when needed
# - Sophisticated scheduling and resource allocation
# - More efficient bin-packing than Cluster Autoscaler
# - Cloud-provider optimized instance selection
#==============================================================================
resource "helm_release" "karpenter" {
  count       = var.enable_karpenter ? 1 : 0
  name        = lookup(var.karpenter, "name", "karpenter")
  chart       = lookup(var.karpenter, "chart", "karpenter")
  repository  = lookup(var.karpenter, "repository", "https://charts.karpenter.sh")
  version     = lookup(var.karpenter, "chart_version", null)
  namespace   = lookup(var.karpenter, "namespace", "karpenter")
  max_history = lookup(var.karpenter, "max_history", 10)
  timeout     = lookup(var.karpenter, "timeout", local.default_timeout)
  create_namespace = lookup(var.karpenter, "create_namespace", true)

  # Deployment safety options
  atomic          = lookup(var.karpenter, "atomic", true)
  cleanup_on_fail = lookup(var.karpenter, "cleanup_on_fail", true)
  wait            = lookup(var.karpenter, "wait", true)

  # Configure cloud provider-specific settings (AWS, Azure, GCP)
  values = [
    lookup(var.karpenter, "values", "") != "" ? file(var.karpenter.values) : "",
    yamlencode(lookup(var.karpenter, "set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.karpenter, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

#==============================================================================
# NGINX Ingress Controller
# Manages external HTTP/HTTPS access to services in the cluster by:
# - Implementing Kubernetes Ingress resources as NGINX configuration
# - Providing load balancing, SSL termination and name-based virtual hosting
# - Supporting WebSocket, HTTP/2, and automatic TLS with cert-manager
#==============================================================================
resource "helm_release" "nginx_ingress" {
  count       = var.enable_nginx_ingress ? 1 : 0
  name        = lookup(var.nginx_ingress, "name", "nginx-ingress")
  chart       = lookup(var.nginx_ingress, "chart", "ingress-nginx")
  repository  = lookup(var.nginx_ingress, "repository", "https://kubernetes.github.io/ingress-nginx")
  version     = lookup(var.nginx_ingress, "chart_version", null)
  namespace   = lookup(var.nginx_ingress, "namespace", "ingress-nginx")
  max_history = lookup(var.nginx_ingress, "max_history", 10)
  timeout     = lookup(var.nginx_ingress, "timeout", local.default_timeout)
  create_namespace = lookup(var.nginx_ingress, "create_namespace", true)

  # Deployment safety options
  atomic          = lookup(var.nginx_ingress, "atomic", true)
  cleanup_on_fail = lookup(var.nginx_ingress, "cleanup_on_fail", true)
  wait            = lookup(var.nginx_ingress, "wait", true)

  # Configure controller type, replica count, and service settings
  values = [
    lookup(var.nginx_ingress, "values", "") != "" ? file(var.nginx_ingress.values) : "",
    yamlencode(merge(
      # Add high availability settings if in production
      local.is_production ? {
        controller = {
          replicaCount = local.high_availability.replicas
          podAnnotations = {
            "cluster-autoscaler.kubernetes.io/safe-to-evict" = "true"
          }
          affinity = {
            podAntiAffinity = {
              preferredDuringSchedulingIgnoredDuringExecution = [{
                weight = 100
                podAffinityTerm = {
                  labelSelector = {
                    matchExpressions = [{
                      key = "app.kubernetes.io/name"
                      operator = "In"
                      values = ["ingress-nginx"]
                    }]
                  }
                  topologyKey = "kubernetes.io/hostname"
                }
              }]
            }
          }
          resources = {
            requests = {
              cpu = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu = "200m"
              memory = "256Mi"
            }
          }
        }
      } : {},
      lookup(var.nginx_ingress, "set_values", {})
    ))
  ]

  dynamic "set" {
    for_each = lookup(var.nginx_ingress, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

#==============================================================================
# Cert Manager
# Automates certificate management in Kubernetes by:
# - Managing issuers (Let's Encrypt, HashiCorp Vault, SelfSigned, etc.)
# - Requesting and renewing TLS certificates
# - Ensuring certificates are valid and up-to-date
# - Supports integration with Ingress resources
#==============================================================================
resource "helm_release" "cert_manager" {
  count       = var.enable_cert_manager ? 1 : 0
  name        = lookup(var.cert_manager, "name", "cert-manager")
  chart       = lookup(var.cert_manager, "chart", "cert-manager")
  repository  = lookup(var.cert_manager, "repository", "https://charts.jetstack.io")
  version     = lookup(var.cert_manager, "chart_version", null)
  namespace   = lookup(var.cert_manager, "namespace", "cert-manager")
  max_history = lookup(var.cert_manager, "max_history", 10)
  timeout     = lookup(var.cert_manager, "timeout", local.default_timeout)
  create_namespace = lookup(var.cert_manager, "create_namespace", true)

  # Deployment safety options
  atomic          = lookup(var.cert_manager, "atomic", true)
  cleanup_on_fail = lookup(var.cert_manager, "cleanup_on_fail", true)
  wait            = lookup(var.cert_manager, "wait", true)

  # Important: Typically requires installCRDs=true for proper operation
  values = [
    lookup(var.cert_manager, "values", "") != "" ? file(var.cert_manager.values) : "",
    yamlencode(merge(
      {
        installCRDs = true
      },
      # Add high availability settings if in production
      local.is_production ? {
        replicaCount = local.high_availability.replicas
        podDisruptionBudget = {
          enabled = true
        }
      } : {},
      lookup(var.cert_manager, "set_values", {})
    ))
  ]

  dynamic "set" {
    for_each = lookup(var.cert_manager, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

# Wait for cert-manager webhook to be available before deploying dependent resources
resource "null_resource" "wait_for_cert_manager_webhook" {
  count = var.enable_cert_manager ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --for=condition=Available deployment/cert-manager-webhook \
        -n ${helm_release.cert_manager[0].namespace} --timeout=180s
      kubectl wait --for=condition=Available deployment/cert-manager \
        -n ${helm_release.cert_manager[0].namespace} --timeout=180s
    EOT
  }

  depends_on = [helm_release.cert_manager]
}

#==============================================================================
# External DNS
# Synchronizes exposed Kubernetes Services and Ingresses with DNS providers:
# - Automatically creates DNS records for services with public endpoints
# - Supports AWS Route53, Google Cloud DNS, Azure DNS, and others
# - Manages lifecycle of DNS records based on service/ingress existence
# - Works with both Ingress resources and LoadBalancer services
#==============================================================================
resource "helm_release" "external_dns" {
  count       = var.enable_external_dns ? 1 : 0
  name        = lookup(var.external_dns, "name", "external-dns")
  chart       = lookup(var.external_dns, "chart", "external-dns")
  repository  = lookup(var.external_dns, "repository", "https://kubernetes-sigs.github.io/external-dns/")
  version     = lookup(var.external_dns, "chart_version", null)
  namespace   = lookup(var.external_dns, "namespace", "external-dns")
  max_history = lookup(var.external_dns, "max_history", 10)
  timeout     = lookup(var.external_dns, "timeout", local.default_timeout)
  create_namespace = lookup(var.external_dns, "create_namespace", true)

  # Deployment safety options
  atomic          = lookup(var.external_dns, "atomic", true)
  cleanup_on_fail = lookup(var.external_dns, "cleanup_on_fail", true)
  wait            = lookup(var.external_dns, "wait", true)

  # Requires provider-specific configuration (AWS/GCP/Azure credentials)
  values = [
    lookup(var.external_dns, "values", "") != "" ? file(var.external_dns.values) : "",
    yamlencode(merge(
      # Add high availability settings if in production
      local.is_production ? {
        replicaCount = local.high_availability.replicas
      } : {},
      lookup(var.external_dns, "set_values", {})
    ))
  ]

  dynamic "set" {
    for_each = lookup(var.external_dns, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }

  # Ensure cert-manager is ready if both are enabled
  depends_on = [
    helm_release.cert_manager,
    null_resource.wait_for_cert_manager_webhook
  ]
}

#==============================================================================
# Prometheus Stack (Prometheus, Alertmanager, Grafana)
# Comprehensive monitoring solution that includes:
# - Prometheus: metrics collection and storage
# - Alertmanager: alert routing and notification
# - Grafana: metrics visualization and dashboarding
# - Node exporter: hardware and OS metrics
# - kube-state-metrics: Kubernetes objects metrics
# - Pre-configured dashboards and alerting rules
#==============================================================================
resource "helm_release" "prometheus_stack" {
  count       = var.enable_prometheus_stack ? 1 : 0
  name        = lookup(var.prometheus_stack, "name", "prometheus")
  chart       = lookup(var.prometheus_stack, "chart", "kube-prometheus-stack")
  repository  = lookup(var.prometheus_stack, "repository", "https://prometheus-community.github.io/helm-charts")
  version     = lookup(var.prometheus_stack, "chart_version", null)
  namespace   = lookup(var.prometheus_stack, "namespace", "monitoring")
  max_history = lookup(var.prometheus_stack, "max_history", 10)
  timeout     = lookup(var.prometheus_stack, "timeout",
                  lookup(var.prometheus_stack, "timeout",
                    local.is_production ? local.timeouts["large"] : local.default_timeout))
  create_namespace = lookup(var.prometheus_stack, "create_namespace", true)

  # Deployment safety options
  atomic          = lookup(var.prometheus_stack, "atomic", true)
  cleanup_on_fail = lookup(var.prometheus_stack, "cleanup_on_fail", true)
  wait            = lookup(var.prometheus_stack, "wait", true)
  wait_for_jobs   = lookup(var.prometheus_stack, "wait_for_jobs", true)

  # Complex chart with many configurable components and storage options
  values = [
    lookup(var.prometheus_stack, "values", "") != "" ? file(var.prometheus_stack.values) : "",
    yamlencode(merge(
      # Configure persistent storage with cloud provider optimized settings
      {
        prometheus = {
          prometheusSpec = {
            storageSpec = {
              volumeClaimTemplate = {
                spec = {
                  storageClassName = local.storage_class
                  accessModes = ["ReadWriteOnce"]
                  resources = {
                    requests = {
                      storage = lookup(
                        lookup(var.prometheus_stack, "storage", {}),
                        "size",
                        local.is_production ? "100Gi" : "50Gi"
                      )
                    }
                  }
                }
              }
            }
          }
        }
      },
      # Add high availability settings if in production
      local.is_production ? {
        prometheus = {
          prometheusSpec = {
            replicas = local.high_availability.replicas
            podAntiAffinity = {
              preferredDuringSchedulingIgnoredDuringExecution = [{
                weight = 100
                podAffinityTerm = {
                  labelSelector = {
                    matchExpressions = [{
                      key = "app"
                      operator = "In"
                      values = ["prometheus"]
                    }]
                  }
                  topologyKey = "kubernetes.io/hostname"
                }
              }]
            }
          }
        }
        alertmanager = {
          alertmanagerSpec = {
            replicas = local.high_availability.replicas
          }
        }
        grafana = {
          replicas = local.high_availability.replicas
        }
      } : {},
      lookup(var.prometheus_stack, "set_values", {})
    ))
  ]

  dynamic "set" {
    for_each = lookup(var.prometheus_stack, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

#==============================================================================
# Logging Stack (Fluent Bit)
# Lightweight and efficient log processor and forwarder:
# - Collects logs from the node filesystem and container runtime
# - Processes logs with filters (parsing, enrichment)
# - Forwards logs to various destinations (Elasticsearch, S3, Loki, etc.)
# - Low memory footprint and high performance C implementation
#==============================================================================
resource "helm_release" "fluent_bit" {
  count       = var.enable_fluent_bit ? 1 : 0
  name        = lookup(var.fluent_bit, "name", "fluent-bit")
  chart       = lookup(var.fluent_bit, "chart", "fluent-bit")
  repository  = lookup(var.fluent_bit, "repository", "https://fluent.github.io/helm-charts")
  version     = lookup(var.fluent_bit, "chart_version", null)
  namespace   = lookup(var.fluent_bit, "namespace", "logging")
  max_history = lookup(var.fluent_bit, "max_history", 10)
  timeout     = lookup(var.fluent_bit, "timeout", local.default_timeout)
  create_namespace = lookup(var.fluent_bit, "create_namespace", true)

  # Deployment safety options
  atomic          = lookup(var.fluent_bit, "atomic", true)
  cleanup_on_fail = lookup(var.fluent_bit, "cleanup_on_fail", true)
  wait            = lookup(var.fluent_bit, "wait", true)

  # Configure inputs, parsers, filters and outputs
  values = [
    lookup(var.fluent_bit, "values", "") != "" ? file(var.fluent_bit.values) : "",
    yamlencode(merge(
      # Add tolerations to ensure logs are collected from all nodes
      {
        tolerations = [
          {
            key = "node-role.kubernetes.io/master"
            operator = "Exists"
            effect = "NoSchedule"
          },
          {
            key = "node-role.kubernetes.io/control-plane"
            operator = "Exists"
            effect = "NoSchedule"
          }
        ]
      },
      lookup(var.fluent_bit, "set_values", {})
    ))
  ]

  dynamic "set" {
    for_each = lookup(var.fluent_bit, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

#==============================================================================
# ArgoCD
# GitOps continuous delivery tool for Kubernetes that:
# - Syncs application definitions from Git repositories
# - Monitors deployed applications for drift from desired state
# - Automatically corrects drift by applying changes from Git
# - Provides visualization and manual sync/rollback through UI
#==============================================================================
resource "helm_release" "argocd" {
  count       = var.enable_argocd ? 1 : 0
  name        = lookup(var.argocd, "name", "argocd")
  chart       = lookup(var.argocd, "chart", "argo-cd")
  repository  = lookup(var.argocd, "repository", "https://argoproj.github.io/argo-helm")
  version     = lookup(var.argocd, "chart_version", null)
  namespace   = lookup(var.argocd, "namespace", "argocd")
  max_history = lookup(var.argocd, "max_history", 10)
  timeout     = lookup(var.argocd, "timeout", local.default_timeout)
  create_namespace = lookup(var.argocd, "create_namespace", true)

  # Deployment safety options
  atomic          = lookup(var.argocd, "atomic", true)
  cleanup_on_fail = lookup(var.argocd, "cleanup_on_fail", true)
  wait            = lookup(var.argocd, "wait", true)

  # Configure server, repositories, RBAC, and SSO
  values = [
    lookup(var.argocd, "values", "") != "" ? file(var.argocd.values) : "",
    yamlencode(merge(
      # Add high availability settings if in production
      local.is_production ? {
        controller = {
          replicas = local.high_availability.replicas
        }
        server = {
          replicas = local.high_availability.replicas
          autoscaling = {
            enabled = true
            minReplicas = local.high_availability.replicas
            maxReplicas = 5
          }
        }
        repoServer = {
          replicas = local.high_availability.replicas
          autoscaling = {
            enabled = true
            minReplicas = local.high_availability.replicas
            maxReplicas = 5
          }
        }
      } : {},
      lookup(var.argocd, "set_values", {})
    ))
  ]

  dynamic "set" {
    for_each = lookup(var.argocd, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

#==============================================================================
# Velero (Backup)
# Kubernetes backup and disaster recovery solution that:
# - Backs up Kubernetes cluster resources to object storage
# - Snapshots persistent volumes with cloud provider APIs
# - Schedules regular backups and handles retention
# - Restores full clusters or selected resources
#==============================================================================
resource "helm_release" "velero" {
  count       = var.enable_velero ? 1 : 0
  name        = lookup(var.velero, "name", "velero")
  chart       = lookup(var.velero, "chart", "velero")
  repository  = lookup(var.velero, "repository", "https://vmware-tanzu.github.io/helm-charts")
  version     = lookup(var.velero, "chart_version", null)
  namespace   = lookup(var.velero, "namespace", "velero")
  max_history = lookup(var.velero, "max_history", 10)
  timeout     = lookup(var.velero, "timeout", local.default_timeout)
  create_namespace = lookup(var.velero, "create_namespace", true)

  # Deployment safety options
  atomic          = lookup(var.velero, "atomic", true)
  cleanup_on_fail = lookup(var.velero, "cleanup_on_fail", true)
  wait            = lookup(var.velero, "wait", true)

  # Requires storage provider configuration (S3, GCS, Azure Blob)
  values = [
    lookup(var.velero, "values", "") != "" ? file(var.velero.values) : "",
    yamlencode(merge(
      # Configure default schedules for production environments
      local.is_production ? {
        schedules = {
          daily-backup = {
            schedule = "0 1 * * *"  # 1:00 AM every day
            template = {
              ttl = "720h"  # 30 days
              includedNamespaces = ["*"]
              excludedNamespaces = ["kube-system"]
              includedResources = ["*"]
              excludedResources = [""]
              includeClusterResources = true
              snapshotVolumes = true
            }
          }
        }
      } : {},
      lookup(var.velero, "set_values", {})
    ))
  ]

  dynamic "set" {
    for_each = lookup(var.velero, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

#==============================================================================
# Sealed Secrets
# Secure secret management for Kubernetes that:
# - Encrypts secrets so they can be safely stored in Git
# - Uses asymmetric cryptography (public/private key)
# - Controller in the cluster decrypts sealed secrets automatically
# - Enables GitOps workflows with sensitive information
#==============================================================================
resource "helm_release" "sealed_secrets" {
  count       = var.enable_sealed_secrets ? 1 : 0
  name        = lookup(var.sealed_secrets, "name", "sealed-secrets")
  chart       = lookup(var.sealed_secrets, "chart", "sealed-secrets")
  repository  = lookup(var.sealed_secrets, "repository", "https://bitnami-labs.github.io/sealed-secrets")
  version     = lookup(var.sealed_secrets, "chart_version", null)
  namespace   = lookup(var.sealed_secrets, "namespace", "kube-system")
  max_history = lookup(var.sealed_secrets, "max_history", 10)
  timeout     = lookup(var.sealed_secrets, "timeout", local.default_timeout)
  create_namespace = lookup(var.sealed_secrets, "create_namespace", false)

  # Deployment safety options
  atomic          = lookup(var.sealed_secrets, "atomic", true)
  cleanup_on_fail = lookup(var.sealed_secrets, "cleanup_on_fail", true)
  wait            = lookup(var.sealed_secrets, "wait", true)

  # Configure key rotation, secret scope, and monitoring
  values = [
    lookup(var.sealed_secrets, "values", "") != "" ? file(var.sealed_secrets.values) : "",
    yamlencode(merge(
      # Add high availability settings if in production
      local.is_production ? {
        replicaCount = local.high_availability.replicas
        podAntiAffinity = {
          preferredDuringSchedulingIgnoredDuringExecution = [{
            weight = 100
            podAffinityTerm = {
              labelSelector = {
                matchExpressions = [{
                  key = "app.kubernetes.io/name"
                  operator = "In"
                  values = ["sealed-secrets"]
                }]
              }
              topologyKey = "kubernetes.io/hostname"
            }
          }]
        }
      } : {},
      lookup(var.sealed_secrets, "set_values", {})
    ))
  ]

  dynamic "set" {
    for_each = lookup(var.sealed_secrets, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

#==============================================================================
# Istio Service Mesh
# Advanced networking platform that provides:
# - Traffic management with fine-grained routing control
# - Security with mTLS encryption between services
# - Observability with distributed tracing and metrics
# - Multi-cluster and multi-environment support
#
# Deployed in three stages:
# 1. Base CRDs and cluster resources
# 2. Istiod control plane
# 3. Ingress gateway (optional)
#==============================================================================

# 1. Istio Base - CRDs and cluster resources
resource "helm_release" "istio_base" {
  count       = var.enable_istio ? 1 : 0
  name        = lookup(var.istio, "base_name", "istio-base")
  chart       = lookup(var.istio, "base_chart", "base")
  repository  = lookup(var.istio, "repository", "https://istio-release.storage.googleapis.com/charts")
  version     = lookup(var.istio, "chart_version", null)
  namespace   = lookup(var.istio, "namespace", "istio-system")
  max_history = lookup(var.istio, "max_history", 10)
  timeout     = lookup(var.istio, "timeout", local.default_timeout)
  create_namespace = lookup(var.istio, "create_namespace", true)

  # Deployment safety options
  atomic          = lookup(var.istio, "atomic", true)
  cleanup_on_fail = lookup(var.istio, "cleanup_on_fail", true)
  wait            = lookup(var.istio, "wait", true)

  # Base chart contains CRDs and cluster resources
  values = [
    lookup(var.istio, "base_values", "") != "" ? file(var.istio.base_values) : "",
    yamlencode(lookup(var.istio, "base_set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.istio, "base_set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

# Wait for Istio CRDs to be available
resource "null_resource" "wait_for_istio_crds" {
  count = var.enable_istio ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=Established crd/virtualservices.networking.istio.io --timeout=90s"
  }

  depends_on = [helm_release.istio_base]
}

# 2. Istiod - Istio control plane
resource "helm_release" "istiod" {
  count       = var.enable_istio ? 1 : 0
  name        = lookup(var.istio, "istiod_name", "istiod")
  chart       = lookup(var.istio, "istiod_chart", "istiod")
  repository  = lookup(var.istio, "repository", "https://istio-release.storage.googleapis.com/charts")
  version     = lookup(var.istio, "chart_version", null)
  namespace   = lookup(var.istio, "namespace", "istio-system")
  max_history = lookup(var.istio, "max_history", 10)
  timeout     = lookup(var.istio, "timeout", local.default_timeout)
  create_namespace = false  # Already created by istio-base

  # Deployment safety options
  atomic          = lookup(var.istio, "atomic", true)
  cleanup_on_fail = lookup(var.istio, "cleanup_on_fail", true)
  wait            = lookup(var.istio, "wait", true)

  # Istiod is the control plane that configures the service mesh
  values = [
    lookup(var.istio, "istiod_values", "") != "" ? file(var.istio.istiod_values) : "",
    yamlencode(merge(
      # Add high availability settings if in production
      local.is_production ? {
        pilot = {
          replicaCount = local.high_availability.replicas
          autoscaleEnabled = true
          autoscaleMin = local.high_availability.replicas
          autoscaleMax = 5
          resources = {
            requests = {
              cpu = "500m"
              memory = "2Gi"
            }
          }
        }
      } : {},
      lookup(var.istio, "istiod_set_values", {})
    ))
  ]

  dynamic "set" {
    for_each = lookup(var.istio, "istiod_set", {})
    content {
      name  = set.key
      value = set.value
    }
  }

  # Must deploy after istio-base installs CRDs
  depends_on = [
    helm_release.istio_base,
    null_resource.wait_for_istio_crds
  ]
}

# 3. Istio Ingress Gateway - Entry point for external traffic
resource "helm_release" "istio_ingress" {
  count       = var.enable_istio && lookup(var.istio, "enable_ingress", true) ? 1 : 0
  name        = lookup(var.istio, "ingress_name", "istio-ingress")
  chart       = lookup(var.istio, "ingress_chart", "gateway")
  repository  = lookup(var.istio, "repository", "https://istio-release.storage.googleapis.com/charts")
  version     = lookup(var.istio, "chart_version", null)
  namespace   = lookup(var.istio, "namespace", "istio-system")
  max_history = lookup(var.istio, "max_history", 10)
  timeout     = lookup(var.istio, "timeout", local.default_timeout)
  create_namespace = false  # Already created by istio-base

  # Deployment safety options
  atomic          = lookup(var.istio, "atomic", true)
  cleanup_on_fail = lookup(var.istio, "cleanup_on_fail", true)
  wait            = lookup(var.istio, "wait", true)

  # Gateway provides the entry point for traffic into the mesh
  values = [
    lookup(var.istio, "ingress_values", "") != "" ? file(var.istio.ingress_values) : "",
    yamlencode(merge(
      # Add high availability settings if in production
      local.is_production ? {
        replicaCount = local.high_availability.replicas
        autoscaling = {
          enabled = true
          minReplicas = local.high_availability.replicas
          maxReplicas = 5
        }
        resources = {
          requests = {
            cpu = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu = "2000m"
            memory = "1024Mi"
          }
        }
      } : {},
      lookup(var.istio, "ingress_set_values", {})
    ))
  ]

  dynamic "set" {
    for_each = lookup(var.istio, "ingress_set", {})
    content {
      name  = set.key
      value = set.value
    }
  }

  # Must deploy after istiod is running
  depends_on = [helm_release.istiod]
}

#==============================================================================
# Kyverno - Policy Management Engine
# Kubernetes policy engine that:
# - Validates, mutates, and generates resources
# - Enforces security and compliance requirements
# - Provides policy reports and audit capabilities
# - Supports pre-admission webhooks and background scanning
#==============================================================================
resource "helm_release" "kyverno" {
  count       = var.enable_kyverno ? 1 : 0
  name        = lookup(var.kyverno, "name", "kyverno")
  chart       = lookup(var.kyverno, "chart", "kyverno")
  repository  = lookup(var.kyverno, "repository", "https://kyverno.github.io/kyverno/")
  version     = lookup(var.kyverno, "chart_version", null)
  namespace   = lookup(var.kyverno, "namespace", "kyverno")
  max_history = lookup(var.kyverno, "max_history", 10)
  timeout     = lookup(var.kyverno, "timeout", local.default_timeout)
  create_namespace = lookup(var.kyverno, "create_namespace", true)

  # Deployment safety options
  atomic          = lookup(var.kyverno, "atomic", true)
  cleanup_on_fail = lookup(var.kyverno, "cleanup_on_fail", true)
  wait            = lookup(var.kyverno, "wait", true)

  # Configure policy engine options and monitoring integration
  values = [
    lookup(var.kyverno, "values", "") != "" ? file(var.kyverno.values) : "",
    yamlencode(merge(
      # Add high availability settings if in production
      local.is_production ? {
        replicaCount = local.high_availability.replicas
        resources = {
          limits = {
            cpu = "1000m"
            memory = "512Mi"
          }
          requests = {
            cpu = "100m"
            memory = "128Mi"
          }
        }
      } : {},
      lookup(var.kyverno, "set_values", {})
    ))
  ]

  dynamic "set" {
    for_each = lookup(var.kyverno, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

#==============================================================================
# Crossplane - Universal Control Plane
# Extends Kubernetes with:
# - Custom Resource Definitions (XRDs) for cloud resources
# - Infrastructure as Code directly from Kubernetes
# - Composition of complex infrastructure from simple abstractions
# - Multi-cloud and hybrid cloud resource management
#==============================================================================
resource "helm_release" "crossplane" {
  count       = var.enable_crossplane ? 1 : 0
  name        = lookup(var.crossplane, "name", "crossplane")
  chart       = lookup(var.crossplane, "chart", "crossplane")
  repository  = lookup(var.crossplane, "repository", "https://charts.crossplane.io/stable")
  version     = lookup(var.crossplane, "chart_version", null)
  namespace   = lookup(var.crossplane, "namespace", "crossplane-system")
  max_history = lookup(var.crossplane, "max_history", 10)
  timeout     = lookup(var.crossplane, "timeout", local.default_timeout)
  create_namespace = lookup(var.crossplane, "create_namespace", true)

  # Deployment safety options
  atomic          = lookup(var.crossplane, "atomic", true)
  cleanup_on_fail = lookup(var.crossplane, "cleanup_on_fail", true)
  wait            = lookup(var.crossplane, "wait", true)

  # Configure providers and resource management options
  values = [
    lookup(var.crossplane, "values", "") != "" ? file(var.crossplane.values) : "",
    yamlencode(lookup(var.crossplane, "set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.crossplane, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

#==============================================================================
# AWS Load Balancer Controller
# AWS-specific controller that:
# - Manages AWS Elastic Load Balancers for Kubernetes Services
# - Implements the Ingress API using Application Load Balancers
# - Supports Network Load Balancers for high-performance workloads
# - Enables additional AWS-specific annotations and features
#==============================================================================
resource "helm_release" "aws_load_balancer_controller" {
  count       = var.enable_aws_load_balancer_controller ? 1 : 0
  name        = lookup(var.aws_load_balancer_controller, "name", "aws-load-balancer-controller")
  chart       = lookup(var.aws_load_balancer_controller, "chart", "aws-load-balancer-controller")
  repository  = lookup(var.aws_load_balancer_controller, "repository", "https://aws.github.io/eks-charts")
  version     = lookup(var.aws_load_balancer_controller, "chart_version", null)
  namespace   = lookup(var.aws_load_balancer_controller, "namespace", "kube-system")
  max_history = lookup(var.aws_load_balancer_controller, "max_history", 10)
  timeout     = lookup(var.aws_load_balancer_controller, "timeout", local.default_timeout)
  create_namespace = lookup(var.aws_load_balancer_controller, "create_namespace", false)

  # Deployment safety options
  atomic          = lookup(var.aws_load_balancer_controller, "atomic", true)
  cleanup_on_fail = lookup(var.aws_load_balancer_controller, "cleanup_on_fail", true)
  wait            = lookup(var.aws_load_balancer_controller, "wait", true)

  # Configure AWS-specific settings and IAM integration
  values = [
    lookup(var.aws_load_balancer_controller, "values", "") != "" ? file(var.aws_load_balancer_controller.values) : "",
    yamlencode(merge(
      # Add high availability settings if in production
      local.is_production ? {
        replicaCount = local.high_availability.replicas
      } : {},
      lookup(var.aws_load_balancer_controller, "set_values", {})
    ))
  ]

  dynamic "set" {
    for_each = lookup(var.aws_load_balancer_controller, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}
