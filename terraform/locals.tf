locals {
  name   = "eks-lab"
  domain = "lab.amirbeile.uk"
  region = "eu-west-2"


  tags = {
    # Environment = "sandbox"
    Project = "EKS Advanced Lab"
    Owner   = "Amir"
  }
}