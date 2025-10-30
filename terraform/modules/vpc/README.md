# VPC Module

This module creates a complete AWS VPC networking stack for the EKS cluster.

## Resources Created

- 1 VPC with DNS support
- 1 Internet Gateway
- 2 Public Subnets (across 2 AZs)
- 2 Private Subnets (across 2 AZs)
- 2 NAT Gateways (one per AZ for high availability)
- 2 Elastic IPs (for NAT Gateways)
- 1 Public Route Table
- 2 Private Route Tables (one per AZ)

## Architecture

```
                    Internet Gateway
                           |
                    Public Subnets
                      /        \
                  NAT-1      NAT-2
                    |            |
              Private-1      Private-2
                    |            |
                EKS Nodes    EKS Nodes
```

## Features

- **High Availability**: Resources spread across 2 availability zones
- **Security**: EKS nodes in private subnets with no direct internet access
- **Kubernetes Tags**: Subnets tagged for automatic discovery by AWS Load Balancer Controller
- **NAT Gateway**: Redundant NAT gateways for outbound internet access from private subnets

## Inputs

| Variable | Description | Type | Required |
|----------|-------------|------|----------|
| `cluster_name` | Name of the EKS cluster | string | yes |
| `vpc_cidr` | CIDR block for VPC | string | yes |
| `availability_zones` | List of availability zones | list(string) | yes |
| `tags` | Tags to apply to resources | map(string) | no |

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC ID |
| `private_subnet_ids` | List of private subnet IDs |
| `public_subnet_ids` | List of public subnet IDs |
| `vpc_cidr` | VPC CIDR block |

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  cluster_name       = "my-cluster"
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  tags = {
    Environment = "production"
    Project     = "IAI"
  }
}
```

## Subnet Sizing

The module uses `cidrsubnet()` function to automatically divide the VPC CIDR:

- Public subnets: `10.0.0.0/24`, `10.0.1.0/24`
- Private subnets: `10.0.10.0/24`, `10.0.11.0/24`

This provides ~250 usable IPs per subnet, sufficient for most EKS deployments.
