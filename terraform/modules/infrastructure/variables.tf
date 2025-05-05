variable "local_name" {
  description = "The local name to use for tagging"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

# locals {
#   name   = "eks-lab"
#   domain = "lab.amirbeile.uk"
#   region = "eu-west-2"

#   tags = {
#    # Environment = "sandbox"
#     Project     = "EKS Advanced Lab"
#     Owner       = "Amir"
#   }
# }