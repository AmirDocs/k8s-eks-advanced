output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "cert_manager_irsa_role_arn" {
  value = module.cert_manager_irsa_role.iam_role_arn
}

output "external_dns_irsa_role_arn" {
  value = module.external_dns_irsa_role.iam_role_arn
}