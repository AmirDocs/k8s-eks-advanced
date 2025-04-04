resource "helm_release" "nginx_ingress" {
  name = "nginx-ingress"

  repository = "https://kubernetes.github.io/ingress-nginx" # Change bitnami to nginx.
  chart      = "ingress-nginx"
  version    = "4.10.1"
  # chart needed from https.

  create_namespace = true
  namespace        = "ingress-nginx"

  values = [
    <<EOF
controller:
  service:
    type: LoadBalancer
  watchIngressWithoutClass: true
EOF
  ]

  wait = true # Ensures the release is deployed before Terraform continues
}             # Cluster IP service created by default, service type unnecessary.


resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io" # documentation for cert-manager
  chart      = "cert-manager"

  create_namespace = true
  namespace        = "cert-manager"

  # set {
  #   name  = "wait-for"
  #   value = module.cert_manager_irsa_role.iam_role_arn
  # }

  set {
    name  = "installCRDs" # custom resource definitions
    value = "true"
  }

  values = [
    file("helm-values/cert-manager.yaml")
  ]
}


resource "helm_release" "external_dns" {
  name = "external-dns"

  repository = "oci://registry-1.docker.io/bitnamicharts" # changed from bitnami to io.
  chart      = "external-dns"

  create_namespace = true
  namespace        = "external-dns"

  set {
    name  = "wait-for"
    value = module.external_dns_irsa_role.iam_role_arn
  }

  values = [
    file("helm-values/external-dns.yaml")
  ]
}

resource "helm_release" "argocd_deploy" {

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  timeout    = "600"

  namespace        = "argo-cd"
  create_namespace = true

  values = [
    file("helm-values/argocd.yaml")
  ]
}

