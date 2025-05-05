# VPC

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"

  name = var.local_name

  cidr = "10.0.0.0/16"

  azs = ["${var.region}a", "${var.region}b", "${var.region}c"]

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  public_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.local_name}" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }

  tags = var.tags
}

# EKS

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = var.local_name
  cluster_version = "1.29"

  cluster_endpoint_public_access       = true # kubectl API will be public. Only done for testing. In production a VPN is required for best practice.
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  enable_irsa = true # Creates IAM roles and allows us to associate them with k8.

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  eks_managed_node_group_defaults = { # managed node groups
    disk_size      = 50
    instance_types = ["t3a.large", "t3.large"]
  }

  eks_managed_node_groups = {
    default = {}
  }

  tags = var.tags
}

# EKS Access

resource "aws_eks_access_entry" "access-entry" {
  cluster_name  = var.local_name
  principal_arn = "arn:aws:iam::872515255126:user/Amir2"
  type          = "STANDARD"

  depends_on = [module.eks]
}

resource "aws_eks_access_policy_association" "policy-association1" {
  cluster_name  = var.local_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = "arn:aws:iam::872515255126:user/Amir2"

  access_scope {
    type = "cluster"
  }

  depends_on = [module.eks]
}

resource "aws_eks_access_policy_association" "policy-association2" {
  cluster_name  = var.local_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::872515255126:user/Amir2"

  access_scope {
    type = "cluster"
  }

  depends_on = [module.eks]
}


# IRSA Roles Cert Manager and External DNS

module "cert_manager_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.2.0"

  role_name                     = "cert-manager"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = ["arn:aws:route53:::hostedzone/Z06920746EPQXTK8Q687"]

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"] # k8namespace: service account within it
    }
  }


  tags = var.tags

}


module "external_dns_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.2.0"

  role_name                     = "external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/Z06920746EPQXTK8Q687"]

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns"] # namespace:service-account
    }
  }

  tags = var.tags

}



  