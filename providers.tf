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
      version = ">= 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.6"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}
