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
      version = ">= 2.16.0" # Required for server-side apply and CRD handling
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.16.0" # Required for proper release management
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0" # Used for applying custom resources when needed
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
    enabled         = local.is_production
    replicas        = local.is_production ? 3 : 1
    topology_spread = local.is_production
  }

  # Installed addons data structure for internal use
  installed_addons_data = {
    "metrics-server" = var.enable_metrics_server ? {
      enabled   = true
      namespace = helm_release.metrics_server[0].namespace
      version   = helm_release.metrics_server[0].version
    } : { enabled = false }

    "cluster-autoscaler" = var.enable_cluster_autoscaler ? {
      enabled   = true
      namespace = helm_release.cluster_autoscaler[0].namespace
      version   = helm_release.cluster_autoscaler[0].version
    } : { enabled = false }

    "karpenter" = var.enable_karpenter ? {
      enabled   = true
      namespace = helm_release.karpenter[0].namespace
      version   = helm_release.karpenter[0].version
    } : { enabled = false }

    "nginx-ingress" = var.enable_nginx_ingress ? {
      enabled   = true
      namespace = helm_release.nginx_ingress[0].namespace
      version   = helm_release.nginx_ingress[0].version
    } : { enabled = false }

    "cert-manager" = var.enable_cert_manager ? {
      enabled   = true
      namespace = helm_release.cert_manager[0].namespace
      version   = helm_release.cert_manager[0].version
    } : { enabled = false }

    "external-dns" = var.enable_external_dns ? {
      enabled   = true
      namespace = helm_release.external_dns[0].namespace
      version   = helm_release.external_dns[0].version
    } : { enabled = false }

    "prometheus-stack" = var.enable_prometheus_stack ? {
      enabled   = true
      namespace = helm_release.prometheus_stack[0].namespace
      version   = helm_release.prometheus_stack[0].version
    } : { enabled = false }

    "fluent-bit" = var.enable_fluent_bit ? {
      enabled   = true
      namespace = helm_release.fluent_bit[0].namespace
      version   = helm_release.fluent_bit[0].version
    } : { enabled = false }

    "argocd" = var.enable_argocd ? {
      enabled   = true
      namespace = helm_release.argocd[0].namespace
      version   = helm_release.argocd[0].version
    } : { enabled = false }

    "velero" = var.enable_velero ? {
      enabled   = true
      namespace = helm_release.velero[0].namespace
      version   = helm_release.velero[0].version
    } : { enabled = false }

    "sealed-secrets" = var.enable_sealed_secrets ? {
      enabled   = true
      namespace = helm_release.sealed_secrets[0].namespace
      version   = helm_release.sealed_secrets[0].version
    } : { enabled = false }

    "kyverno" = var.enable_kyverno ? {
      enabled   = true
      namespace = helm_release.kyverno[0].namespace
      version   = helm_release.kyverno[0].version
    } : { enabled = false }

    "crossplane" = var.enable_crossplane ? {
      enabled   = true
      namespace = helm_release.crossplane[0].namespace
      version   = helm_release.crossplane[0].version
    } : { enabled = false }

    "aws-load-balancer-controller" = var.enable_aws_load_balancer_controller ? {
      enabled   = true
      namespace = helm_release.aws_load_balancer_controller[0].namespace
      version   = helm_release.aws_load_balancer_controller[0].version
    } : { enabled = false }

    "istio" = var.enable_istio ? {
      enabled        = true
      namespace      = helm_release.istio_base[0].namespace
      base_version   = helm_release.istio_base[0].version
      istiod_version = helm_release.istiod[0].version
      ingress = {
        enabled = lookup(var.istio, "enable_ingress", true)
        version = lookup(var.istio, "enable_ingress", true) ? helm_release.istio_ingress[0].version : null
      }
    } : { enabled = false }
  }
}

#==============================================================================
# Metrics Server
# Collects resource metrics from kubelets for horizontal pod autoscaling,
# vertical pod autoscaling, and displaying resource usage in the dashboard.
#==============================================================================
resource "helm_release" "metrics_server" {
  # Only deploy if explicitly enabled
  count = var.enable_metrics_server ? 1 : 0

  # Chart details with fallbacks to default values if not specified
  name       = lookup(var.metrics_server, "name", "metrics-server")
  chart      = lookup(var.metrics_server, "chart", "metrics-server")
  repository = lookup(var.metrics_server, "repository", "https://kubernetes-sigs.github.io/metrics-server/")
  version    = lookup(var.metrics_server, "chart_version", null) # null = latest version

  # Deployment configuration
  namespace        = lookup(var.metrics_server, "namespace", "kube-system") # Uses kube-system by default
  max_history      = lookup(var.metrics_server, "max_history", 10)          # Keep history of 10 releases for rollbacks
  timeout          = lookup(var.metrics_server, "timeout", local.default_timeout)
  create_namespace = lookup(var.metrics_server, "create_namespace", false) # kube-system exists by default

  # Deployment safety options
  atomic          = lookup(var.metrics_server, "atomic", true)
  cleanup_on_fail = lookup(var.metrics_server, "cleanup_on_fail", true)
  wait            = lookup(var.metrics_server, "wait", true)

  # Values configuration supports both file-based and direct value settings
  values = [
    # Use custom values file if provided, otherwise empty string
    lookup(var.metrics_server, "values", "") != "" ? file(var.metrics_server.values) : "",
    # Convert map of values to YAML for Helm
    yamlencode(lookup(var.metrics_server, "set_values", {})),
    # Individual value overrides
    lookup(var.metrics_server, "set", {}) != {} ?
    yamlencode(lookup(var.metrics_server, "set", {})) :
    ""
  ]
}

#==============================================================================
# Cluster Autoscaler
# Automatically adjusts the size of the Kubernetes cluster when:
# - pods fail to schedule due to insufficient resources
# - nodes are underutilized and can be removed
#==============================================================================
resource "helm_release" "cluster_autoscaler" {
  count            = var.enable_cluster_autoscaler ? 1 : 0
  name             = lookup(var.cluster_autoscaler, "name", "cluster-autoscaler")
  chart            = lookup(var.cluster_autoscaler, "chart", "cluster-autoscaler")
  repository       = lookup(var.cluster_autoscaler, "repository", "https://kubernetes.github.io/autoscaler")
  version          = lookup(var.cluster_autoscaler, "chart_version", null)
  namespace        = lookup(var.cluster_autoscaler, "namespace", "kube-system")
  max_history      = lookup(var.cluster_autoscaler, "max_history", 10)
  timeout          = lookup(var.cluster_autoscaler, "timeout", local.default_timeout)
  create_namespace = lookup(var.cluster_autoscaler, "create_namespace", false)

  # Deployment safety options
  atomic          = lookup(var.cluster_autoscaler, "atomic", true)
  cleanup_on_fail = lookup(var.cluster_autoscaler, "cleanup_on_fail", true)
  wait            = lookup(var.cluster_autoscaler, "wait", true)

  # Values must be cloud-provider specific (AWS, Azure, GCP) to work correctly
  values = [
    lookup(var.cluster_autoscaler, "values", "") != "" ? file(var.cluster_autoscaler.values) : "",
    yamlencode(lookup(var.cluster_autoscaler, "set_values", {})),
    lookup(var.cluster_autoscaler, "set", {}) != {} ?
    yamlencode(lookup(var.cluster_autoscaler, "set", {})) :
    ""
  ]
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
  count            = var.enable_karpenter ? 1 : 0
  name             = lookup(var.karpenter, "name", "karpenter")
  chart            = lookup(var.karpenter, "chart", "karpenter")
  repository       = lookup(var.karpenter, "repository", "https://charts.karpenter.sh")
  version          = lookup(var.karpenter, "chart_version", null)
  namespace        = lookup(var.karpenter, "namespace", "karpenter")
  max_history      = lookup(var.karpenter, "max_history", 10)
  timeout          = lookup(var.karpenter, "timeout", local.default_timeout)
  create_namespace = lookup(var.karpenter, "create_namespace", true)

  # Deployment safety options
  atomic          = lookup(var.karpenter, "atomic", true)
  cleanup_on_fail = lookup(var.karpenter, "cleanup_on_fail", true)
  wait            = lookup(var.karpenter, "wait", true)

  # Configure cloud provider-specific settings (AWS, Azure, GCP)
  values = [
    lookup(var.karpenter, "values", "") != "" ? file(var.karpenter.values) : "",
    yamlencode(lookup(var.karpenter, "set_values", {})),
    lookup(var.karpenter, "set", {}) != {} ?
    yamlencode(lookup(var.karpenter, "set", {})) :
    ""
  ]
}

#==============================================================================
# NGINX Ingress Controller
#==============================================================================
resource "helm_release" "nginx_ingress" {
  count            = var.enable_nginx_ingress ? 1 : 0
  name             = lookup(var.nginx_ingress, "name", "nginx-ingress")
  chart            = lookup(var.nginx_ingress, "chart", "ingress-nginx")
  repository       = lookup(var.nginx_ingress, "repository", "https://kubernetes.github.io/ingress-nginx")
  version          = lookup(var.nginx_ingress, "chart_version", null)
  namespace        = lookup(var.nginx_ingress, "namespace", "ingress-nginx")
  max_history      = lookup(var.nginx_ingress, "max_history", 10)
  timeout          = lookup(var.nginx_ingress, "timeout", local.default_timeout)
  create_namespace = lookup(var.nginx_ingress, "create_namespace", true)

  atomic          = lookup(var.nginx_ingress, "atomic", true)
  cleanup_on_fail = lookup(var.nginx_ingress, "cleanup_on_fail", true)
  wait            = lookup(var.nginx_ingress, "wait", true)

  values = [
    lookup(var.nginx_ingress, "values", "") != "" ? file(var.nginx_ingress.values) : "",
    yamlencode(lookup(var.nginx_ingress, "set_values", {})),
    lookup(var.nginx_ingress, "set", {}) != {} ?
    yamlencode(lookup(var.nginx_ingress, "set", {})) :
    ""
  ]
}

#==============================================================================
# Cert Manager
#==============================================================================
resource "helm_release" "cert_manager" {
  count            = var.enable_cert_manager ? 1 : 0
  name             = lookup(var.cert_manager, "name", "cert-manager")
  chart            = lookup(var.cert_manager, "chart", "cert-manager")
  repository       = lookup(var.cert_manager, "repository", "https://charts.jetstack.io")
  version          = lookup(var.cert_manager, "chart_version", null)
  namespace        = lookup(var.cert_manager, "namespace", "cert-manager")
  max_history      = lookup(var.cert_manager, "max_history", 10)
  timeout          = lookup(var.cert_manager, "timeout", local.default_timeout)
  create_namespace = lookup(var.cert_manager, "create_namespace", true)

  atomic          = lookup(var.cert_manager, "atomic", true)
  cleanup_on_fail = lookup(var.cert_manager, "cleanup_on_fail", true)
  wait            = lookup(var.cert_manager, "wait", true)

  values = [
    lookup(var.cert_manager, "values", "") != "" ? file(var.cert_manager.values) : "",
    yamlencode(lookup(var.cert_manager, "set_values", {})),
    lookup(var.cert_manager, "set", {}) != {} ?
    yamlencode(lookup(var.cert_manager, "set", {})) :
    ""
  ]
}

#==============================================================================
# External DNS
#==============================================================================
resource "helm_release" "external_dns" {
  count            = var.enable_external_dns ? 1 : 0
  name             = lookup(var.external_dns, "name", "external-dns")
  chart            = lookup(var.external_dns, "chart", "external-dns")
  repository       = lookup(var.external_dns, "repository", "https://kubernetes-sigs.github.io/external-dns/")
  version          = lookup(var.external_dns, "chart_version", null)
  namespace        = lookup(var.external_dns, "namespace", "external-dns")
  max_history      = lookup(var.external_dns, "max_history", 10)
  timeout          = lookup(var.external_dns, "timeout", local.default_timeout)
  create_namespace = lookup(var.external_dns, "create_namespace", true)

  atomic          = lookup(var.external_dns, "atomic", true)
  cleanup_on_fail = lookup(var.external_dns, "cleanup_on_fail", true)
  wait            = lookup(var.external_dns, "wait", true)

  values = [
    lookup(var.external_dns, "values", "") != "" ? file(var.external_dns.values) : "",
    yamlencode(lookup(var.external_dns, "set_values", {})),
    lookup(var.external_dns, "set", {}) != {} ?
    yamlencode(lookup(var.external_dns, "set", {})) :
    ""
  ]
}

#==============================================================================
# Prometheus Stack
#==============================================================================
resource "helm_release" "prometheus_stack" {
  count            = var.enable_prometheus_stack ? 1 : 0
  name             = lookup(var.prometheus_stack, "name", "prometheus-stack")
  chart            = lookup(var.prometheus_stack, "chart", "kube-prometheus-stack")
  repository       = lookup(var.prometheus_stack, "repository", "https://prometheus-community.github.io/helm-charts")
  version          = lookup(var.prometheus_stack, "chart_version", null)
  namespace        = lookup(var.prometheus_stack, "namespace", "monitoring")
  max_history      = lookup(var.prometheus_stack, "max_history", 10)
  timeout          = lookup(var.prometheus_stack, "timeout", local.default_timeout)
  create_namespace = lookup(var.prometheus_stack, "create_namespace", true)

  atomic          = lookup(var.prometheus_stack, "atomic", true)
  cleanup_on_fail = lookup(var.prometheus_stack, "cleanup_on_fail", true)
  wait            = lookup(var.prometheus_stack, "wait", true)

  values = [
    lookup(var.prometheus_stack, "values", "") != "" ? file(var.prometheus_stack.values) : "",
    yamlencode(lookup(var.prometheus_stack, "set_values", {})),
    lookup(var.prometheus_stack, "set", {}) != {} ?
    yamlencode(lookup(var.prometheus_stack, "set", {})) :
    ""
  ]
}

#==============================================================================
# Fluent Bit
#==============================================================================
resource "helm_release" "fluent_bit" {
  count            = var.enable_fluent_bit ? 1 : 0
  name             = lookup(var.fluent_bit, "name", "fluent-bit")
  chart            = lookup(var.fluent_bit, "chart", "fluent-bit")
  repository       = lookup(var.fluent_bit, "repository", "https://fluent.github.io/helm-charts")
  version          = lookup(var.fluent_bit, "chart_version", null)
  namespace        = lookup(var.fluent_bit, "namespace", "logging")
  max_history      = lookup(var.fluent_bit, "max_history", 10)
  timeout          = lookup(var.fluent_bit, "timeout", local.default_timeout)
  create_namespace = lookup(var.fluent_bit, "create_namespace", true)

  atomic          = lookup(var.fluent_bit, "atomic", true)
  cleanup_on_fail = lookup(var.fluent_bit, "cleanup_on_fail", true)
  wait            = lookup(var.fluent_bit, "wait", true)

  values = [
    lookup(var.fluent_bit, "values", "") != "" ? file(var.fluent_bit.values) : "",
    yamlencode(lookup(var.fluent_bit, "set_values", {})),
    lookup(var.fluent_bit, "set", {}) != {} ?
    yamlencode(lookup(var.fluent_bit, "set", {})) :
    ""
  ]
}

#==============================================================================
# ArgoCD
#==============================================================================
resource "helm_release" "argocd" {
  count            = var.enable_argocd ? 1 : 0
  name             = lookup(var.argocd, "name", "argocd")
  chart            = lookup(var.argocd, "chart", "argo-cd")
  repository       = lookup(var.argocd, "repository", "https://argoproj.github.io/argo-helm")
  version          = lookup(var.argocd, "chart_version", null)
  namespace        = lookup(var.argocd, "namespace", "argocd")
  max_history      = lookup(var.argocd, "max_history", 10)
  timeout          = lookup(var.argocd, "timeout", local.default_timeout)
  create_namespace = lookup(var.argocd, "create_namespace", true)

  atomic          = lookup(var.argocd, "atomic", true)
  cleanup_on_fail = lookup(var.argocd, "cleanup_on_fail", true)
  wait            = lookup(var.argocd, "wait", true)

  values = [
    lookup(var.argocd, "values", "") != "" ? file(var.argocd.values) : "",
    yamlencode(lookup(var.argocd, "set_values", {})),
    lookup(var.argocd, "set", {}) != {} ?
    yamlencode(lookup(var.argocd, "set", {})) :
    ""
  ]
}

#==============================================================================
# Velero
#==============================================================================
resource "helm_release" "velero" {
  count            = var.enable_velero ? 1 : 0
  name             = lookup(var.velero, "name", "velero")
  chart            = lookup(var.velero, "chart", "velero")
  repository       = lookup(var.velero, "repository", "https://vmware-tanzu.github.io/helm-charts")
  version          = lookup(var.velero, "chart_version", null)
  namespace        = lookup(var.velero, "namespace", "velero")
  max_history      = lookup(var.velero, "max_history", 10)
  timeout          = lookup(var.velero, "timeout", local.default_timeout)
  create_namespace = lookup(var.velero, "create_namespace", true)

  atomic          = lookup(var.velero, "atomic", true)
  cleanup_on_fail = lookup(var.velero, "cleanup_on_fail", true)
  wait            = lookup(var.velero, "wait", true)

  values = [
    lookup(var.velero, "values", "") != "" ? file(var.velero.values) : "",
    yamlencode(lookup(var.velero, "set_values", {})),
    lookup(var.velero, "set", {}) != {} ?
    yamlencode(lookup(var.velero, "set", {})) :
    ""
  ]
}

#==============================================================================
# Sealed Secrets
#==============================================================================
resource "helm_release" "sealed_secrets" {
  count            = var.enable_sealed_secrets ? 1 : 0
  name             = lookup(var.sealed_secrets, "name", "sealed-secrets")
  chart            = lookup(var.sealed_secrets, "chart", "sealed-secrets")
  repository       = lookup(var.sealed_secrets, "repository", "https://bitnami-labs.github.io/sealed-secrets")
  version          = lookup(var.sealed_secrets, "chart_version", null)
  namespace        = lookup(var.sealed_secrets, "namespace", "kube-system")
  max_history      = lookup(var.sealed_secrets, "max_history", 10)
  timeout          = lookup(var.sealed_secrets, "timeout", local.default_timeout)
  create_namespace = lookup(var.sealed_secrets, "create_namespace", false)

  atomic          = lookup(var.sealed_secrets, "atomic", true)
  cleanup_on_fail = lookup(var.sealed_secrets, "cleanup_on_fail", true)
  wait            = lookup(var.sealed_secrets, "wait", true)

  values = [
    lookup(var.sealed_secrets, "values", "") != "" ? file(var.sealed_secrets.values) : "",
    yamlencode(lookup(var.sealed_secrets, "set_values", {})),
    lookup(var.sealed_secrets, "set", {}) != {} ?
    yamlencode(lookup(var.sealed_secrets, "set", {})) :
    ""
  ]
}

#==============================================================================
# Kyverno
#==============================================================================
resource "helm_release" "kyverno" {
  count            = var.enable_kyverno ? 1 : 0
  name             = lookup(var.kyverno, "name", "kyverno")
  chart            = lookup(var.kyverno, "chart", "kyverno")
  repository       = lookup(var.kyverno, "repository", "https://kyverno.github.io/kyverno/")
  version          = lookup(var.kyverno, "chart_version", null)
  namespace        = lookup(var.kyverno, "namespace", "kyverno")
  max_history      = lookup(var.kyverno, "max_history", 10)
  timeout          = lookup(var.kyverno, "timeout", local.default_timeout)
  create_namespace = lookup(var.kyverno, "create_namespace", true)

  atomic          = lookup(var.kyverno, "atomic", true)
  cleanup_on_fail = lookup(var.kyverno, "cleanup_on_fail", true)
  wait            = lookup(var.kyverno, "wait", true)

  values = [
    lookup(var.kyverno, "values", "") != "" ? file(var.kyverno.values) : "",
    yamlencode(lookup(var.kyverno, "set_values", {})),
    lookup(var.kyverno, "set", {}) != {} ?
    yamlencode(lookup(var.kyverno, "set", {})) :
    ""
  ]
}

#==============================================================================
# Crossplane
#==============================================================================
resource "helm_release" "crossplane" {
  count            = var.enable_crossplane ? 1 : 0
  name             = lookup(var.crossplane, "name", "crossplane")
  chart            = lookup(var.crossplane, "chart", "crossplane")
  repository       = lookup(var.crossplane, "repository", "https://charts.crossplane.io/stable")
  version          = lookup(var.crossplane, "chart_version", null)
  namespace        = lookup(var.crossplane, "namespace", "crossplane-system")
  max_history      = lookup(var.crossplane, "max_history", 10)
  timeout          = lookup(var.crossplane, "timeout", local.default_timeout)
  create_namespace = lookup(var.crossplane, "create_namespace", true)

  atomic          = lookup(var.crossplane, "atomic", true)
  cleanup_on_fail = lookup(var.crossplane, "cleanup_on_fail", true)
  wait            = lookup(var.crossplane, "wait", true)

  values = [
    lookup(var.crossplane, "values", "") != "" ? file(var.crossplane.values) : "",
    yamlencode(lookup(var.crossplane, "set_values", {})),
    lookup(var.crossplane, "set", {}) != {} ?
    yamlencode(lookup(var.crossplane, "set", {})) :
    ""
  ]
}

#==============================================================================
# AWS Load Balancer Controller
#==============================================================================
resource "helm_release" "aws_load_balancer_controller" {
  count            = var.enable_aws_load_balancer_controller ? 1 : 0
  name             = lookup(var.aws_load_balancer_controller, "name", "aws-load-balancer-controller")
  chart            = lookup(var.aws_load_balancer_controller, "chart", "aws-load-balancer-controller")
  repository       = lookup(var.aws_load_balancer_controller, "repository", "https://aws.github.io/eks-charts")
  version          = lookup(var.aws_load_balancer_controller, "chart_version", null)
  namespace        = lookup(var.aws_load_balancer_controller, "namespace", "kube-system")
  max_history      = lookup(var.aws_load_balancer_controller, "max_history", 10)
  timeout          = lookup(var.aws_load_balancer_controller, "timeout", local.default_timeout)
  create_namespace = lookup(var.aws_load_balancer_controller, "create_namespace", false)

  atomic          = lookup(var.aws_load_balancer_controller, "atomic", true)
  cleanup_on_fail = lookup(var.aws_load_balancer_controller, "cleanup_on_fail", true)
  wait            = lookup(var.aws_load_balancer_controller, "wait", true)

  values = [
    lookup(var.aws_load_balancer_controller, "values", "") != "" ? file(var.aws_load_balancer_controller.values) : "",
    yamlencode(lookup(var.aws_load_balancer_controller, "set_values", {})),
    lookup(var.aws_load_balancer_controller, "set", {}) != {} ?
    yamlencode(lookup(var.aws_load_balancer_controller, "set", {})) :
    ""
  ]
}

#==============================================================================
# Istio Service Mesh
#==============================================================================
resource "helm_release" "istio_base" {
  count            = var.enable_istio ? 1 : 0
  name             = lookup(var.istio, "base_name", "istio-base")
  chart            = lookup(var.istio, "base_chart", "base")
  repository       = lookup(var.istio, "repository", "https://istio-release.storage.googleapis.com/charts")
  version          = lookup(var.istio, "chart_version", null)
  namespace        = lookup(var.istio, "namespace", "istio-system")
  max_history      = lookup(var.istio, "max_history", 10)
  timeout          = lookup(var.istio, "timeout", local.default_timeout)
  create_namespace = lookup(var.istio, "create_namespace", true)

  atomic          = lookup(var.istio, "atomic", true)
  cleanup_on_fail = lookup(var.istio, "cleanup_on_fail", true)
  wait            = lookup(var.istio, "wait", true)

  values = [
    lookup(var.istio, "base_values", "") != "" ? file(var.istio.base_values) : "",
    yamlencode(lookup(var.istio, "base_set_values", {})),
    lookup(var.istio, "base_set", {}) != {} ?
    yamlencode(lookup(var.istio, "base_set", {})) :
    ""
  ]
}

resource "helm_release" "istiod" {
  count            = var.enable_istio ? 1 : 0
  name             = lookup(var.istio, "istiod_name", "istiod")
  chart            = lookup(var.istio, "istiod_chart", "istiod")
  repository       = lookup(var.istio, "repository", "https://istio-release.storage.googleapis.com/charts")
  version          = lookup(var.istio, "chart_version", null)
  namespace        = lookup(var.istio, "namespace", "istio-system")
  max_history      = lookup(var.istio, "max_history", 10)
  timeout          = lookup(var.istio, "timeout", local.default_timeout)
  create_namespace = false

  atomic          = lookup(var.istio, "atomic", true)
  cleanup_on_fail = lookup(var.istio, "cleanup_on_fail", true)
  wait            = lookup(var.istio, "wait", true)

  depends_on = [helm_release.istio_base]

  values = [
    lookup(var.istio, "istiod_values", "") != "" ? file(var.istio.istiod_values) : "",
    yamlencode(lookup(var.istio, "istiod_set_values", {})),
    lookup(var.istio, "istiod_set", {}) != {} ?
    yamlencode(lookup(var.istio, "istiod_set", {})) :
    ""
  ]
}

resource "helm_release" "istio_ingress" {
  count            = var.enable_istio && lookup(var.istio, "enable_ingress", true) ? 1 : 0
  name             = lookup(var.istio, "ingress_name", "istio-ingress")
  chart            = lookup(var.istio, "ingress_chart", "gateway")
  repository       = lookup(var.istio, "repository", "https://istio-release.storage.googleapis.com/charts")
  version          = lookup(var.istio, "chart_version", null)
  namespace        = lookup(var.istio, "ingress_namespace", "istio-ingress")
  max_history      = lookup(var.istio, "max_history", 10)
  timeout          = lookup(var.istio, "timeout", local.default_timeout)
  create_namespace = lookup(var.istio, "create_ingress_namespace", true)

  atomic          = lookup(var.istio, "atomic", true)
  cleanup_on_fail = lookup(var.istio, "cleanup_on_fail", true)
  wait            = lookup(var.istio, "wait", true)

  depends_on = [helm_release.istiod]

  values = [
    lookup(var.istio, "ingress_values", "") != "" ? file(var.istio.ingress_values) : "",
    yamlencode(lookup(var.istio, "ingress_set_values", {})),
    lookup(var.istio, "ingress_set", {}) != {} ?
    yamlencode(lookup(var.istio, "ingress_set", {})) :
    ""
  ]
}
