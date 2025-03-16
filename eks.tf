module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = local.name
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

  tags = local.tags
}