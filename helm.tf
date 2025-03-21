resource "helm_release" "nginx" {
  name = "nginx-ingress"

  repository = "https://helm.nginx.com/stable" # Change bitnami to nginx.
  chart      = "nginx-ingress"                 # chart needed from https.

  create_namespace = true
  namespace        = "nginx-ingress"
} # Cluster IP service created by default, service type unnecessary.


resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io" # documentation for cert-manager
  chart      = "cert-manager"

  create_namespace = true
  namespace        = "cert-manager"

  set {
    name  = "wait-for"
    value = module.cert_manager_irsa_role.iam_role_arn
  }

  set {
    name  = "installCRDs" # custom resource definitions
    value = "true"
  }

  values = [
    "${file("helm-values/cert-manager.yaml")}"
  ]
}


resource "helm_release" "external_dns" {
  name = "external-dns"

  repository = "oci://registry-1.docker.io/bitnamicharts"  # changed from bitnami to io.
  chart      = "external-dns"

  create_namespace = true
  namespace        = "external-dns"

  set {
    name  = "wait-for"
    value = module.external_dns_irsa_role.iam_role_arn
  }

  values = [
    "${file("helm-values/external-dns.yaml")}"
  ]
}