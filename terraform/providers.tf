terraform {
  backend "s3" {
    bucket  = "eks-tfstate-amir"
    key     = "eks-lab"
    region  = "eu-west-2"
    encrypt = true # Stored data encrypted at rest
  }

  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

provider "helm" {

  kubernetes {
    host                   = module.infrastructure.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.infrastructure.eks_cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.infrastructure.eks_cluster_name]
      command     = "aws"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}