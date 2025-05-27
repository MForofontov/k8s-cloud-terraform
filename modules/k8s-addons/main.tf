# Kubernetes Addons Module
# This module installs and configures common Kubernetes addons using Helm

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

# --------------------
# Metrics Server
# --------------------
resource "helm_release" "metrics_server" {
  count       = var.enable_metrics_server ? 1 : 0
  name        = lookup(var.metrics_server, "name", "metrics-server")
  chart       = lookup(var.metrics_server, "chart", "metrics-server")
  repository  = lookup(var.metrics_server, "repository", "https://kubernetes-sigs.github.io/metrics-server/")
  version     = lookup(var.metrics_server, "chart_version", null)
  namespace   = lookup(var.metrics_server, "namespace", "kube-system")
  max_history = lookup(var.metrics_server, "max_history", 10)
  timeout     = lookup(var.metrics_server, "timeout", 300)
  create_namespace = lookup(var.metrics_server, "create_namespace", false)

  values = [
    lookup(var.metrics_server, "values", "") != "" ? file(var.metrics_server.values) : "",
    yamlencode(lookup(var.metrics_server, "set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.metrics_server, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

# --------------------
# Cluster Autoscaler
# --------------------
resource "helm_release" "cluster_autoscaler" {
  count       = var.enable_cluster_autoscaler ? 1 : 0
  name        = lookup(var.cluster_autoscaler, "name", "cluster-autoscaler")
  chart       = lookup(var.cluster_autoscaler, "chart", "cluster-autoscaler")
  repository  = lookup(var.cluster_autoscaler, "repository", "https://kubernetes.github.io/autoscaler")
  version     = lookup(var.cluster_autoscaler, "chart_version", null)
  namespace   = lookup(var.cluster_autoscaler, "namespace", "kube-system")
  max_history = lookup(var.cluster_autoscaler, "max_history", 10)
  timeout     = lookup(var.cluster_autoscaler, "timeout", 300)
  create_namespace = lookup(var.cluster_autoscaler, "create_namespace", false)

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

# --------------------
# NGINX Ingress Controller
# --------------------
resource "helm_release" "nginx_ingress" {
  count       = var.enable_nginx_ingress ? 1 : 0
  name        = lookup(var.nginx_ingress, "name", "nginx-ingress")
  chart       = lookup(var.nginx_ingress, "chart", "ingress-nginx")
  repository  = lookup(var.nginx_ingress, "repository", "https://kubernetes.github.io/ingress-nginx")
  version     = lookup(var.nginx_ingress, "chart_version", null)
  namespace   = lookup(var.nginx_ingress, "namespace", "ingress-nginx")
  max_history = lookup(var.nginx_ingress, "max_history", 10)
  timeout     = lookup(var.nginx_ingress, "timeout", 300)
  create_namespace = lookup(var.nginx_ingress, "create_namespace", true)

  values = [
    lookup(var.nginx_ingress, "values", "") != "" ? file(var.nginx_ingress.values) : "",
    yamlencode(lookup(var.nginx_ingress, "set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.nginx_ingress, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

# --------------------
# Cert Manager
# --------------------
resource "helm_release" "cert_manager" {
  count       = var.enable_cert_manager ? 1 : 0
  name        = lookup(var.cert_manager, "name", "cert-manager")
  chart       = lookup(var.cert_manager, "chart", "cert-manager")
  repository  = lookup(var.cert_manager, "repository", "https://charts.jetstack.io")
  version     = lookup(var.cert_manager, "chart_version", null)
  namespace   = lookup(var.cert_manager, "namespace", "cert-manager")
  max_history = lookup(var.cert_manager, "max_history", 10)
  timeout     = lookup(var.cert_manager, "timeout", 300)
  create_namespace = lookup(var.cert_manager, "create_namespace", true)

  values = [
    lookup(var.cert_manager, "values", "") != "" ? file(var.cert_manager.values) : "",
    yamlencode(lookup(var.cert_manager, "set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.cert_manager, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

# --------------------
# External DNS
# --------------------
resource "helm_release" "external_dns" {
  count       = var.enable_external_dns ? 1 : 0
  name        = lookup(var.external_dns, "name", "external-dns")
  chart       = lookup(var.external_dns, "chart", "external-dns")
  repository  = lookup(var.external_dns, "repository", "https://kubernetes-sigs.github.io/external-dns/")
  version     = lookup(var.external_dns, "chart_version", null)
  namespace   = lookup(var.external_dns, "namespace", "external-dns")
  max_history = lookup(var.external_dns, "max_history", 10)
  timeout     = lookup(var.external_dns, "timeout", 300)
  create_namespace = lookup(var.external_dns, "create_namespace", true)

  values = [
    lookup(var.external_dns, "values", "") != "" ? file(var.external_dns.values) : "",
    yamlencode(lookup(var.external_dns, "set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.external_dns, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

# --------------------
# Prometheus Stack (Prometheus, Alertmanager, Grafana)
# --------------------
resource "helm_release" "prometheus_stack" {
  count       = var.enable_prometheus_stack ? 1 : 0
  name        = lookup(var.prometheus_stack, "name", "prometheus")
  chart       = lookup(var.prometheus_stack, "chart", "kube-prometheus-stack")
  repository  = lookup(var.prometheus_stack, "repository", "https://prometheus-community.github.io/helm-charts")
  version     = lookup(var.prometheus_stack, "chart_version", null)
  namespace   = lookup(var.prometheus_stack, "namespace", "monitoring")
  max_history = lookup(var.prometheus_stack, "max_history", 10)
  timeout     = lookup(var.prometheus_stack, "timeout", 600)
  create_namespace = lookup(var.prometheus_stack, "create_namespace", true)

  values = [
    lookup(var.prometheus_stack, "values", "") != "" ? file(var.prometheus_stack.values) : "",
    yamlencode(lookup(var.prometheus_stack, "set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.prometheus_stack, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

# --------------------
# Logging Stack (Fluent Bit)
# --------------------
resource "helm_release" "fluent_bit" {
  count       = var.enable_fluent_bit ? 1 : 0
  name        = lookup(var.fluent_bit, "name", "fluent-bit")
  chart       = lookup(var.fluent_bit, "chart", "fluent-bit")
  repository  = lookup(var.fluent_bit, "repository", "https://fluent.github.io/helm-charts")
  version     = lookup(var.fluent_bit, "chart_version", null)
  namespace   = lookup(var.fluent_bit, "namespace", "logging")
  max_history = lookup(var.fluent_bit, "max_history", 10)
  timeout     = lookup(var.fluent_bit, "timeout", 300)
  create_namespace = lookup(var.fluent_bit, "create_namespace", true)

  values = [
    lookup(var.fluent_bit, "values", "") != "" ? file(var.fluent_bit.values) : "",
    yamlencode(lookup(var.fluent_bit, "set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.fluent_bit, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

# --------------------
# ArgoCD
# --------------------
resource "helm_release" "argocd" {
  count       = var.enable_argocd ? 1 : 0
  name        = lookup(var.argocd, "name", "argocd")
  chart       = lookup(var.argocd, "chart", "argo-cd")
  repository  = lookup(var.argocd, "repository", "https://argoproj.github.io/argo-helm")
  version     = lookup(var.argocd, "chart_version", null)
  namespace   = lookup(var.argocd, "namespace", "argocd")
  max_history = lookup(var.argocd, "max_history", 10)
  timeout     = lookup(var.argocd, "timeout", 300)
  create_namespace = lookup(var.argocd, "create_namespace", true)

  values = [
    lookup(var.argocd, "values", "") != "" ? file(var.argocd.values) : "",
    yamlencode(lookup(var.argocd, "set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.argocd, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

# --------------------
# Velero (Backup)
# --------------------
resource "helm_release" "velero" {
  count       = var.enable_velero ? 1 : 0
  name        = lookup(var.velero, "name", "velero")
  chart       = lookup(var.velero, "chart", "velero")
  repository  = lookup(var.velero, "repository", "https://vmware-tanzu.github.io/helm-charts")
  version     = lookup(var.velero, "chart_version", null)
  namespace   = lookup(var.velero, "namespace", "velero")
  max_history = lookup(var.velero, "max_history", 10)
  timeout     = lookup(var.velero, "timeout", 300)
  create_namespace = lookup(var.velero, "create_namespace", true)

  values = [
    lookup(var.velero, "values", "") != "" ? file(var.velero.values) : "",
    yamlencode(lookup(var.velero, "set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.velero, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

# --------------------
# Sealed Secrets
# --------------------
resource "helm_release" "sealed_secrets" {
  count       = var.enable_sealed_secrets ? 1 : 0
  name        = lookup(var.sealed_secrets, "name", "sealed-secrets")
  chart       = lookup(var.sealed_secrets, "chart", "sealed-secrets")
  repository  = lookup(var.sealed_secrets, "repository", "https://bitnami-labs.github.io/sealed-secrets")
  version     = lookup(var.sealed_secrets, "chart_version", null)
  namespace   = lookup(var.sealed_secrets, "namespace", "kube-system")
  max_history = lookup(var.sealed_secrets, "max_history", 10)
  timeout     = lookup(var.sealed_secrets, "timeout", 300)
  create_namespace = lookup(var.sealed_secrets, "create_namespace", false)

  values = [
    lookup(var.sealed_secrets, "values", "") != "" ? file(var.sealed_secrets.values) : "",
    yamlencode(lookup(var.sealed_secrets, "set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.sealed_secrets, "set", {})
    content {
      name  = set.key
      value = set.value
    }
  }
}

# --------------------
# Istio Service Mesh
# --------------------
resource "helm_release" "istio_base" {
  count       = var.enable_istio ? 1 : 0
  name        = lookup(var.istio, "base_name", "istio-base")
  chart       = lookup(var.istio, "base_chart", "base")
  repository  = lookup(var.istio, "repository", "https://istio-release.storage.googleapis.com/charts")
  version     = lookup(var.istio, "chart_version", null)
  namespace   = lookup(var.istio, "namespace", "istio-system")
  max_history = lookup(var.istio, "max_history", 10)
  timeout     = lookup(var.istio, "timeout", 300)
  create_namespace = lookup(var.istio, "create_namespace", true)

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

resource "helm_release" "istiod" {
  count       = var.enable_istio ? 1 : 0
  name        = lookup(var.istio, "istiod_name", "istiod")
  chart       = lookup(var.istio, "istiod_chart", "istiod")
  repository  = lookup(var.istio, "repository", "https://istio-release.storage.googleapis.com/charts")
  version     = lookup(var.istio, "chart_version", null)
  namespace   = lookup(var.istio, "namespace", "istio-system")
  max_history = lookup(var.istio, "max_history", 10)
  timeout     = lookup(var.istio, "timeout", 300)
  create_namespace = false

  values = [
    lookup(var.istio, "istiod_values", "") != "" ? file(var.istio.istiod_values) : "",
    yamlencode(lookup(var.istio, "istiod_set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.istio, "istiod_set", {})
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  count       = var.enable_istio && lookup(var.istio, "enable_ingress", true) ? 1 : 0
  name        = lookup(var.istio, "ingress_name", "istio-ingress")
  chart       = lookup(var.istio, "ingress_chart", "gateway")
  repository  = lookup(var.istio, "repository", "https://istio-release.storage.googleapis.com/charts")
  version     = lookup(var.istio, "chart_version", null)
  namespace   = lookup(var.istio, "namespace", "istio-system")
  max_history = lookup(var.istio, "max_history", 10)
  timeout     = lookup(var.istio, "timeout", 300)
  create_namespace = false

  values = [
    lookup(var.istio, "ingress_values", "") != "" ? file(var.istio.ingress_values) : "",
    yamlencode(lookup(var.istio, "ingress_set_values", {}))
  ]

  dynamic "set" {
    for_each = lookup(var.istio, "ingress_set", {})
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [helm_release.istiod]
}