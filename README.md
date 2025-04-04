# EKS Cluster for Production

## Objective

Host applications in Kubernetes and expose them publicly and securely via ingress controllers combined with signed SSL certificates for HTTPS. 

This project deploys an EKS cluster with automated certificate management, DNS integration, and a fully functional ingress controller. ArgoCD integration allows for GitOps-based deployments. *Optional AWS Fargate is used to run workloads without managing EC2 instances, reducing operational complexity.*

## Tools Utilised

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
42. `aws eks --region eu-west-2 update-kubeconfig --name eks-lab`

updates cluster context into a local cluster. When `kubectl get nodes` is entered it returns an error, as you cant access it. This where where you Configure eks IAM access entry via ClickOps on the AWS console to access the cluster on the Command Line Interface. Obtain the aws credentials arn for IAM access entry on the CLI with the command `aws sts get-caller-identity`.

On the AWS console on Create Access Entry:
1) 
 - IAM principle: Enter ARN
 - Username: eks-admin
 - Group name: admin
 - Policy name: Add `AmazonEKSAdminPolicy` and `AmazonEKSClusterPolicy`

This gives the user access to the cluster. Generally for best practice, in production don't give these privileges and take a least privileges approach. After creation, you will have access to the cluster.

# Deploying the resources

in `helm.tf` deploy
- CertManger
- Nginx Ingress controller
- External DNS

Instead of a manual installation (`helm install`), this will be automated via terraform for best practice.

*Note: Helm allows you to package a bunch of resources like pods, deployments, services, ingress etc. into one package, then places deploys into a helm chart. You install a helm chart into your cluster*

### Nginx deployment and certManager deployment

Nginx will be your endpoint, or access point for anything in your cluster.

1) Create `helm.tf` deploy helm releases with the helm release for Nginx. Obtain the helm release from the registry, under provider. Set wait for waits for the IAM role to be created first and installCDRs is telling the helm chart to create CRDs alongside the certManager deployment.

*Note:  Helm (a package manager for Kubernetes) has the ability to create a namespace automatically if it doesn’t already exist before deploying resources inside it.*

2) Create a helm release for CertManager. In this instance, I want a custom certManager. This is done by creating a `helm-values folder > cert-manager.yaml` and we add some inputs (part of the helm chart) These values will customise your helm chart. Add the resources:

- ingressShim
- ExtraArgs
- ServiceAccount

### ExternalDNS deployment

its important to create in the DNS for two reasons:

  - When you can resource kubernetes and different applications and platform services, you want them to be in their own namespaces isolated from other resources and pods
  - irsa created in the right namespace for each one (certManager and External DNS). If the IAM arent created in the right name spaces, they wont be able to access the charts (in helm release). So each `irsa.tf` role has to have access to each chart on `helm.tf`.

1) Create External DNS chart values with `helm-values > external-dns.yaml` and add a External DNS resource block again within its own namespace named `external dns` including `set - wait for` and the values.


Now all three resources have been created. Link helm.tf resources with a cluster by utilising a provider.

Defines the Helm provider to manage Kubernetes resources using Helm by:

```
"helm"
Kubernetes  # helm accesses the actual cluster (kubernetes)
host: Specifies the API server endpoint of the EKS cluster.
cluster_ca_certificate = To access the helm cluster
api_version = specifies APIVersion
args = aws ["eks get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]: executes authentication via AWS CLI
```
and a data block in `providers.tf` to export your eks cluster from `eks.tf` so it can be applied to arguments.

The ingress controller creates a (EC2) load balancer type service behind the scenes `kubectl get svc -n nginx-ingress`. This is the load balancer that hosts nginx. NLB load balancer (layer 4) so it goes straight through.
include a file for troubleshooting.

#### check Logs with:
- `kubectl -n external-dns logs external-dns-5d5457fff-wpgd6`: 
- `kubectl -n cert-manager logs cert-manager-66ff9fbf59-jg6gc`: cert-manager is ready but does not have a cluster issuer.

## Deploying ArgoCD

Before deploying ArgoCD we need a cluster issuer - this allows us to verify SSL. I will use the `cert-man` folder for this.

There are 2 types of servers: Production and Staging server. For this a Production server is used.

### Create issuer

When later creating an ingress resource. This issuer will  be referenced.

`cert-man/issuer.yaml` and input your hosted zone ID and DNS zones.

1) 
Deploy cert issuer with:
```
kubectl apply -f cert-man/issuer.yaml
```

2) 
 Use to view issuer status
```
kubectl get clusterissuers.cert-manager.io
```

### Create ArgoCD Deploy resource

Create a ArgoCD helm release resource in helm.tf.

external-dns will add the record to route 53 that will point to ArgoCD and cert-manager will verify that certificate.


# Troubleshooting:

problem: command ran which deleted the argocd-server/ingress.

must be obtained with: `kubectl get ingress argocd-server -n argo-cd`
1) argocd.yaml, issuer.yaml, data eks/helm (providers) and helm release (helm.tf) all hashtagged out. start terraform without them.

 - before starting terraform add export values, aws eks line(scroll up) then terraform plan, terraform apply.

2) 


values = [
    "${file("helm-values/argocd.yaml")}"
  ]

  server:
  # to disable SSL redirection as our ingress controller is not configured to handle SSL.
  extraArgs:
  - --insecure
  service:
    type: ClusterIP
  ingress:
    enabled: true
    ingressClassName: "nginx" 
    annotations:
      nginx.org/hsts: "false"  # Disabling HSTS. Strict rules.
      cert-manager.io/cluster-issuer: issuer  # Issuer to use for cert-manager
    hosts:
    - argocd.lab.amirbeile.uk # Hostname for the ingress. xxx.hostname
    tls:
    - secretName: argocd-ingress-tls
      hosts:
      - argocd.lab.amirbeile.uk


      upgrade helm release: helm upgrade argocd argo/argo-cd -f helm-values/argocd.yaml -n argo-cd
