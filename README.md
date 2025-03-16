# EKS Cluster for Production

## Objective

Host applications in Kubernetes and expose them publicly and securely via ingress controllers combined with signed SSL certificates for HTTPS. 

This project deploys an EKS cluster with automated certificate management, DNS integration, and a fully functional ingress controller. ArgoCD integration allows for GitOps-based deployments. *Optional AWS Fargate is used to run workloads without managing EC2 instances, reducing operational complexity.*

## Tools Utilized

- **Helm (Kubernetes package manager)** - To deploy and manage the application.
- **NGINX Ingress Controller** - Manages ingress and automates SSL certificate issuance.
- **Let's Encrypt (Certificate Authority)** - Automates SSL certificate issuance and renewal.
- **Cert-Manager** - Automates certificate management.
- **External DNS** - Syncs Kubernetes services with your DNS provider (Route53).
- **ArgoCD (Optional)** - For GitOps continuous deployment.
- **AWS Fargate** - Serverless compute engine for running Kubernetes pods without managing EC2 instances. *We wont be using this but it helps to know*

## Steps

1. Write Terraform code to deploy and automate resources (VPCs, EKS Clusters, IAM roles, Service Accounts, etc.) in AWS.
2. Deploy Helm charts (Cert-Manager, Ingress Controller, External DNS, etc.) via Terraform after the cluster is created.
3. Deploy a test application and demonstrate how it:
   - Uses SSL certificates for HTTPS.
   - Communicates via ingress.
   - Integrates with ArgoCD (if used).

## Delegate Cloudflare Domain to AWS

1. Delegate Cloudflare Domain `amirbeile.uk` as the subdomain `lab.amirbeile.uk` to AWS via Route53.
2. Save all four hosted zone Name Servers in Cloudflare and verify with:

   ```bash
   nslookup -type=NS lab.amirbeile.uk
   ```


## `vpc.tf` and `locals.tf` Creation

1. **VPC Module**: Sourced from the community module to follow the DRY principle.
2. **`locals.tf`**: Stores variables and key-value pairs to avoid hardcoding everything.

## Create EKS Cluster

1. **EKS Module**: Sourced from the community module to follow the DRY principle.
2. **Public Access**: Set `allow_public_access = true` for testing.
3. **IRSA (IAM Roles for Service Accounts)**:
   - Enables IAM roles/policies to be associated with Kubernetes service accounts.
   - Used later for Cert-Manager and External DNS.
4. **VPC Configuration**:
   - Add a VPC and public/private subnets.
   - Control plane resides in public subnets; worker nodes in private subnets.
5. **Worker Nodes**:
   - Create managed worker nodes inside the EKS cluster.
   *- Optionally, use AWS Fargate for serverless pod execution.*

For our certManager and External DNS to react with Route53 we need permissions. Cert manager simply allows us to create SSL certificate management. For this to happen it needs to access our Route 53 zone and create TXT records.

 - TXT records allows a user or someone to actually verify that you own the domain.
 - External DNS allows the automation of adding these records.

 ### *AWS Fargate Integration Optional - Not used in project.*

1. Enable AWS Fargate in EKS by defining a `Fargate Profile`:

   ```hcl
   resource "aws_eks_fargate_profile" "default" {
     cluster_name           = aws_eks_cluster.this.name
     fargate_profile_name   = "default"
     pod_execution_role_arn = aws_iam_role.fargate.arn
     subnet_ids             = module.vpc.private_subnets
     selector {
       namespace = "default"
     }
   }
   ```

2. Deploy workloads to the `default` namespace, and they will automatically run on AWS Fargate.
3. Verify Fargate pods:

   ```bash
   kubectl get pods -n default
   ```

## Cert-Manager and External DNS Permissions

To interact with Route53, Cert-Manager and External DNS need permissions:

- **Cert-Manager**: Creates and manages SSL certificates.
- **External DNS**: Automates adding DNS records.
- **TXT Records**: Used for domain verification.

## Create IAM Roles for Service Accounts (IRSA) - Cert-Manager

1. Use the IRSA module from the community.
2. Attach a Cert-Manager policy and set it to `true`. 
3. Allow the `cert-manager` service account to modify Route53 hosted zones:

   ```hcl
   cert_manager_hosted_zone_arns = ["arn:aws:route53:::hostedzone/Z123456ABC"]
   ```

4. **OIDC (OpenID Connect) Explanation**:

   ```bash
   🔹 OIDC (OpenID Connect) links Kubernetes service accounts with AWS IAM roles.
   🔹 IRSA (IAM Roles for Service Accounts) allows Kubernetes workloads to access AWS securely.
   🔹 Terraform uses OIDC providers for secure authentication.
   ```

## External DNS IRSA

1. Use the IRSA module from the community.
2. Attach an External DNS policy and set it to `true`.
3. Allow `external-dns` service account to modify Route53 records:

   ```hcl
   external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/Z123456ABC"]
   ```

## Add Provider and S3 Backend

1. Define an S3 backend for Terraform state management, add a key for the resource to be created later, and add the required version.:

   ```hcl
   terraform {
     backend "s3" {
       bucket = "eks-tfstate-amir"
       key    = "terraform.tfstate"
       region = "eu-west-2"
     }
   }
   ```

2. Add required Terraform providers:

   ```hcl
   provider "aws" {
     region = "eu-west-2"
   }

   provider "helm" {}
   ```

-  With the required provider (aws) added, the helm provider is also added for later use for later use, to enable me to interact with the cluster.

-  Define the provider (aws). Core resources are complete.

## Set AWS Access Keys

For this, I will be using pre-existing access keys. Create one on aws, if necessary:

```bash
export AWS_ACCESS_KEY_ID="*****"
export AWS_SECRET_ACCESS_KEY="*****"
export AWS_DEFAULT_REGION="eu-west-2"
```

Check authentication:

```bash
aws sts get-caller-identity
```

Expected error if S3 bucket is missing:

```bash
Error: Failed to get existing workspaces: S3 bucket "eks-tfstate-amir" does not exist.
```

## Create the S3 Bucket via ClickOps

1. Manually create the bucket `eks-tfstate-amir` in AWS Console via s3, referring to the bucket name is irsa.tf `eks-tfstate-amir`.
2. Run Terraform commands:

   ```bash
   terraform init
   terraform plan
   terraform apply --auto-approve
   ```

### Some terraform Resources created from this

- `aws_kms_key`: Manages encryption keys.
- `aws_iam_policy_document.this`: Defines IAM permissions for EKS-managed nodes.
- `aws_eks_cluster`: Deploys the EKS cluster.
- `aws_eks_fargate_profile`: Defines Fargate settings.
- `aws_vpc`: Defines VPC settings.
- `aws_subnet`: Creates subnets.
- `aws_route_table`: Manages routing.

/////

# Add IAM rules to s3 via clickOps, Review+kubectl
42. `aws eks --region eu-west-2 update kubeconfig --name eks-lab`