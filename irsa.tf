# Cert manager IRSA (IAM roles for service accounts)

module "cert_manager_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                     = "cert-manager"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = ["arn:aws:route53:::hostedzone/Z00435142MHLA7LA0KLSO"]

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"] # k8namespace: service account within it
    }
  }

  tags = local.tags
}

# External DNS IRSA #

module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.2.0"

  role_name                     = "external-dns"
  attach_cert_manager_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/Z00435142MHLA7LA0KLSO"]

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns"] # namespace:service-account
    }
  }

  tags = local.tags

}