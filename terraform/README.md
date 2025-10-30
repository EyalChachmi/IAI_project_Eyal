# Terraform Infrastructure for IAI Project

This directory contains Terraform configuration to provision the complete AWS infrastructure for the IAI project, including:

- VPC with public and private subnets across multiple availability zones
- EKS (Elastic Kubernetes Service) cluster
- EKS managed node groups
- ECR (Elastic Container Registry) repositories
- AWS Load Balancer Controller for Ingress support
- All necessary IAM roles and policies

## Project Structure

The Terraform configuration is organized into modular components for better maintainability and reusability:

```
terraform/
├── main.tf                 # Root module that orchestrates all modules
├── variables.tf            # Input variables
├── outputs.tf             # Output values
├── terraform.tfvars       # Variable values (customize this)
├── .gitignore            # Git ignore patterns
├── README.md             # This file
└── modules/              # Reusable modules
    ├── vpc/              # VPC, subnets, NAT gateways, route tables
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── eks/              # EKS cluster, node groups, security groups, OIDC
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ecr/              # ECR repositories with lifecycle policies
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── load-balancer/    # AWS Load Balancer Controller via Helm
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### Module Overview

- **VPC Module**: Creates a complete networking stack with public and private subnets across 2 availability zones, Internet Gateway, NAT Gateways, and route tables.

- **EKS Module**: Provisions an EKS cluster with managed node groups, security groups, IAM roles, and OIDC provider for service account authentication.

- **ECR Module**: Creates ECR repositories for backend and frontend images with automatic lifecycle policies to keep only the last 3 images.

- **Load Balancer Module**: Installs and configures the AWS Load Balancer Controller using Helm, enabling Kubernetes Ingress resources to create AWS Application Load Balancers.

## Prerequisites

1. **Terraform** installed (v1.0+)
   ```bash
   # Install on Linux
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install terraform
   ```

2. **AWS CLI** configured
   ```bash
   aws configure
   ```

3. **kubectl** installed
   ```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   ```

4. **Helm** installed (for Load Balancer Controller)
   ```bash
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

## Quick Start

### 1. Initialize Terraform
```bash
cd terraform
terraform init
```

### 2. Review the Plan
```bash
terraform plan
```

### 3. Create the Infrastructure
```bash
terraform apply
```

Type `yes` when prompted. This will take 10-15 minutes.

### 4. Configure kubectl
```bash
aws eks update-kubeconfig --region eu-north-1 --name iai-cluster
```

### 5. Verify Cluster
```bash
kubectl get nodes
kubectl get pods -A
```

### 6. Deploy Your Application
```bash
cd ..
./deploy-to-ecr.sh
./deploy-to-eks.sh
```

## Destroy Everything

When you're done testing:

```bash
# Delete Kubernetes resources first
kubectl delete -f k8s/

# Destroy Terraform resources
cd terraform
terraform destroy
```

Type `yes` when prompted.

## Configuration

### Customize Variables

Edit `terraform/terraform.tfvars`:

```hcl
# AWS Configuration
aws_region = "eu-north-1"

# EKS Cluster Configuration
cluster_name       = "iai-cluster"
environment        = "production"
kubernetes_version = "1.28"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Node Group Configuration
node_instance_type = "t3.small"
desired_nodes      = 2
min_nodes          = 1
max_nodes          = 3
```

### Available Variables

All variables are defined in `variables.tf` with descriptions and defaults. You can override any variable by:

1. **Editing `terraform.tfvars`** (recommended)
2. Using `-var` flag: `terraform apply -var="desired_nodes=3"`
3. Setting environment variables: `export TF_VAR_desired_nodes=3`

### Module Customization

Each module accepts its own set of inputs. To customize a module, edit the module block in `main.tf`:

```hcl
module "eks" {
  source = "./modules/eks"
  
  cluster_name       = var.cluster_name
  desired_nodes      = 3              # Override for more nodes
  node_instance_type = "t3.medium"    # Use larger instances
  # ... other variables
}
```

### Available Instance Types

For cost optimization:
- `t3.micro` - Cheapest (free tier eligible, but may be too small for EKS)
- `t3.small` - Good balance (~$0.02/hour per node) **← Default**
- `t3.medium` - More resources (~$0.04/hour per node)

## Cost Estimate

**Monthly costs:**
- EKS Control Plane: ~$73/month
- 2 x t3.small nodes: ~$30/month
- Load Balancer: ~$20/month
- **Total: ~$123/month**

**To minimize costs:**
1. Destroy cluster when not in use: `terraform destroy`
2. Use spot instances (see advanced config below)
3. Reduce node count to 1
4. Use smaller instance types (t3.small is already cost-effective)


## Architecture Overview

The modular structure provides:

- **Separation of Concerns**: Each module handles a specific aspect of the infrastructure
- **Reusability**: Modules can be reused across different projects or environments
- **Maintainability**: Changes to one component don't affect others
- **Testability**: Each module can be tested independently

### Resource Flow

```
VPC Module → EKS Module → Load Balancer Module
     ↓
ECR Module (independent)
```

1. **VPC Module** creates the networking foundation
2. **ECR Module** creates container registries (can run in parallel)
3. **EKS Module** uses VPC outputs to create the cluster
4. **Load Balancer Module** uses EKS outputs to install the controller

## Outputs
### Terraform init fails
```bash
rm -rf .terraform
terraform init
```

### Apply fails with permission errors
Check your AWS credentials:
```bash
aws sts get-caller-identity
```

### Cluster not accessible
Update kubeconfig:
```bash
aws eks update-kubeconfig --region eu-north-1 --name iai-cluster
```

### LoadBalancer not working
Check controller logs:
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## Advanced Configuration

### Use Spot Instances (Cheaper)

In `nodes.tf`, add:
```hcl
capacity_type = "SPOT"
```

### Enable Cluster Autoscaler

Add to `main.tf`:
```hcl
enable_cluster_autoscaler = true
```

### Add Monitoring

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack
```

## State Management

Terraform state is stored locally in `terraform.tfstate`. For production:

1. Use S3 backend:
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "iai-project/terraform.tfstate"
    region = "eu-north-1"
  }
}
```

2. Initialize with backend:
```bash
terraform init -backend-config="bucket=your-bucket"
```

## Security Best Practices

✅ VPC with private subnets for worker nodes
✅ Security groups restricting access
✅ IAM roles with least privilege
✅ Encryption enabled on EKS
✅ Private endpoint for Kubernetes API

## Next Steps

After cluster is created:
1. Deploy application: `./deploy-to-eks.sh`
2. Set up monitoring
3. Configure autoscaling
4. Set up backup/disaster recovery
5. Configure CI/CD pipeline

## Support

If you encounter issues:
1. Check Terraform logs
2. Verify AWS credentials
3. Check AWS service quotas
4. Review CloudWatch logs
5. Check EKS cluster status in AWS Console
