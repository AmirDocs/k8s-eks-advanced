# EKS Cluster for Production

## Objective:

Host application in Kubernetes and expose them publicly securely via ingress controllers combined with signed SSL certificates for HTTPS.

## Tools utilised:

- Helm (k8s package manager) - To deploy and manage the application.
- NGINX Ingress controller (ingress management) - automate the issuance and renewal of SSL certificates.
- Let's Encrypt (certificate authority)  - automate the issuance and renewal of SSL certificates.
- Cert-manager (to automate certificate management) - 
- External DNS (to automate and sync services with your DNS provider, Route53)
- Add ArgoCD(optional)

## Steps:

1) Write terraform code to deploy and automate in resources (VPC's, EKS Clusters, IAM roles Service accounts etc.) in aws.
2) After the cluster is created and connected to, deploy helm charts (certManager, ingress controller, external DNS etc.) all via terraform again.
3) Deploy test application and show the work flow of what happens when you deploy an application, how the application has a SSL certificate for HTTPS, how its being communicated via ingress and then ArgoCD.

# Delegate Cloudflare Domain to AWS

1) Delegate Cloudflare Domain `amirbeile.uk` as the subdomain `lab.amirbeile.uk` to AWS via Route53. 

2) Save all 4 hosted zone Name Servers onto cloudflare and enter `nslookup -type=NS lab.amirbeile.uk`

# `vpc.tf` and `locals.tf` creation

1) Sourced the VPC module from the community, module allows you to overcome the DRY principle.

2) Rather than hardcoding everything, `locals.tf` allows you to store variables and key-value pairs so they can be reused later.

# Create EKS Cluster

1) Sourced the EKS cluster from the community, module allows you to overcome the DRY principle.