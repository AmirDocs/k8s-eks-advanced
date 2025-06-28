resource "helm_release" "nginx_ingress" {

  name = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  # chart needed from https.

  create_namespace = true
  namespace        = "ingress-nginx"

  # values = [
  #   file("../helm-values/nginx-metrics.yaml")
  # ]
}

resource "helm_release" "cert_manager" {

  name       = "cert-manager"
  repository = "https://charts.jetstack.io" # documentation for cert-manager
  chart      = "cert-manager"

  create_namespace = true
  namespace        = "cert-manager"
  version          = "v1.15.3"


  set {
    name  = "wait-for"
    value = var.cert_manager_irsa_role_arn
  }
  set {
    name  = "installCRDs" # custom resource definitions
    value = "true"
  }


  values = [
    file("../helm-values/cert-manager.yaml")
  ]


}


resource "helm_release" "external_dns" {

  name       = "external-dns"
  repository = "oci://registry-1.docker.io/bitnamicharts" # changed from bitnami to io.
  chart      = "external-dns"

  create_namespace = true
  namespace        = "external-dns"
  version          = "8.3.5"

  set {
    name  = "wait-for"
    value = var.external_dns_irsa_role_arn
  }

  values = [
    file("../helm-values/external-dns.yaml")
  ]


}

resource "helm_release" "argocd_deploy" {

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.19.15"
  timeout    = "600"

  namespace        = "argo-cd"
  create_namespace = true

  values = [
    file("../helm-values/argocd.yaml")
  ]


}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  timeout    = "600"

  create_namespace = true  # Already created
  namespace        = "prometheus"

  values = [
    file("../helm-values/prometheus.yaml"),
    file("../helm-values/grafana.yaml"),
  ]
}

resource "kubernetes_manifest" "prometheus_alert_rules" {
  manifest = yamldecode(file("../grafana-dashboards/alerts-rules/prometheus-alerts.yaml"))

}

resource "kubernetes_manifest" "detect_app_servicemonitor" {
  manifest = yamldecode(file("../grafana-dashboards/alerts-rules/servicemonitor-detect.yaml"))

}

resource "kubernetes_manifest" "site_traffic_dashboard" {
  manifest = yamldecode(file("../grafana-dashboards/alerts-rules/configmap-traffic.yaml"))
}