# Terraform Module Structure

```
terraform/
├── main.tf                          # Root module - orchestrates all modules
├── variables.tf                     # Input variables for root module
├── outputs.tf                       # Outputs from all modules
├── terraform.tfvars                 # Variable values (customizable)
├── .gitignore                       # Git ignore patterns
├── README.md                        # Main documentation
│
└── modules/                         # Reusable modules directory
    │
    ├── vpc/                         # VPC Module
    │   ├── main.tf                  # VPC, subnets, NAT gateways, routes
    │   ├── variables.tf             # VPC module inputs
    │   ├── outputs.tf               # VPC module outputs
    │   └── README.md                # VPC module documentation
    │
    ├── eks/                         # EKS Module
    │   ├── main.tf                  # EKS cluster, nodes, security, OIDC
    │   ├── variables.tf             # EKS module inputs
    │   ├── outputs.tf               # EKS module outputs
    │   └── README.md                # EKS module documentation
    │
    ├── ecr/                         # ECR Module
    │   ├── main.tf                  # ECR repositories & lifecycle policies
    │   ├── variables.tf             # ECR module inputs
    │   ├── outputs.tf               # ECR module outputs
    │   └── README.md                # ECR module documentation
    │
    └── load-balancer/               # Load Balancer Controller Module
        ├── main.tf                  # IAM roles, policies, Helm installation
        ├── variables.tf             # Load balancer module inputs
        ├── outputs.tf               # Load balancer module outputs
        └── README.md                # Load balancer module documentation
```

## Module Organization

### Root Module (`/terraform`)
The root module ties everything together. It:
- Defines provider configurations (AWS, Kubernetes, Helm)
- Calls child modules with appropriate parameters
- Manages dependencies between modules
- Exposes useful outputs

### Child Modules (`/terraform/modules/*`)
Each child module is self-contained and:
- Has its own `main.tf` with resource definitions
- Declares inputs via `variables.tf`
- Exposes outputs via `outputs.tf`
- Includes comprehensive documentation in `README.md`
- Can be used independently or as part of the root module

## Module Dependencies

```
┌─────────────────────────────────────────────────────┐
│                   Root Module                       │
│                   (main.tf)                         │
└─────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┬───────────┐
          │               │               │           │
          ▼               ▼               ▼           ▼
    ┌─────────┐     ┌─────────┐     ┌─────────┐ ┌─────────┐
    │   VPC   │     │   ECR   │     │   EKS   │ │ LoadBal │
    │ Module  │     │ Module  │     │ Module  │ │ Module  │
    └─────────┘     └─────────┘     └─────────┘ └─────────┘
          │                               ▲           ▲
          └───────────────────────────────┘           │
                    (vpc_id, subnets)                 │
                                                      │
                            (oidc_provider, cluster)──┘
```

### Dependency Flow:
1. **VPC Module** - Created first (no dependencies)
2. **ECR Module** - Created in parallel (no dependencies)
3. **EKS Module** - Requires VPC outputs (vpc_id, subnet_ids)
4. **Load Balancer Module** - Requires EKS outputs (oidc_provider_arn, cluster_endpoint)

## Benefits of Modular Structure

### 1. **Separation of Concerns**
Each module handles a specific infrastructure component:
- VPC = Networking
- EKS = Kubernetes Cluster
- ECR = Container Registry
- Load Balancer = Ingress Controller

### 2. **Reusability**
Modules can be:
- Reused across different projects
- Shared across environments (dev, staging, prod)
- Published to Terraform Registry
- Versioned independently

### 3. **Maintainability**
- Changes to one module don't affect others
- Easier to understand and debug
- Clear separation of resources
- Self-contained documentation

### 4. **Testability**
- Each module can be tested independently
- Unit tests for individual modules
- Integration tests for root module
- Easier to validate changes

### 5. **Flexibility**
- Swap out modules (e.g., different VPC configurations)
- Override module inputs per environment
- Enable/disable modules as needed
- Customize module behavior without changing source

## Usage Examples

### Using Individual Modules

You can use modules independently in other projects:

```hcl
# In another project's main.tf
module "vpc" {
  source = "git::https://github.com/your-org/terraform-modules.git//vpc"
  
  cluster_name       = "my-other-cluster"
  vpc_cidr          = "10.1.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b"]
}
```

### Customizing Module Behavior

Override module inputs in the root module:

```hcl
# In terraform/main.tf
module "eks" {
  source = "./modules/eks"
  
  # Use custom values instead of variables
  desired_nodes      = 5
  node_instance_type = "t3.large"
  
  # Pass through from variables
  cluster_name = var.cluster_name
  vpc_id      = module.vpc.vpc_id
}
```

### Multiple Environments

Use the same modules for different environments:

```hcl
# terraform/environments/dev/main.tf
module "vpc" {
  source = "../../modules/vpc"
  
  cluster_name = "dev-cluster"
  vpc_cidr    = "10.0.0.0/16"
}

# terraform/environments/prod/main.tf
module "vpc" {
  source = "../../modules/vpc"
  
  cluster_name = "prod-cluster"
  vpc_cidr    = "10.1.0.0/16"
}
```

## Best Practices

### 1. **Module Inputs**
- Use descriptive variable names
- Provide sensible defaults
- Add validation rules where appropriate
- Document all variables

### 2. **Module Outputs**
- Export all useful resource attributes
- Use descriptive output names
- Mark sensitive outputs appropriately
- Document all outputs

### 3. **Documentation**
- Include README.md in each module
- Document inputs, outputs, and examples
- Explain architectural decisions
- Provide troubleshooting guidance

### 4. **Versioning**
- Use semantic versioning for modules
- Tag stable releases
- Maintain changelog
- Test before releasing new versions

### 5. **Security**
- Minimize permissions granted
- Use least-privilege IAM policies
- Enable encryption where available
- Follow AWS security best practices
