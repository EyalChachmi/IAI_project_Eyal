# Load Balancer Module

This module installs and configures the AWS Load Balancer Controller on an EKS cluster using Helm.

## Resources Created

- IAM Role for AWS Load Balancer Controller
- IAM Policy with required permissions
- Kubernetes Service Account with IAM role annotation
- Helm release of AWS Load Balancer Controller

## What is AWS Load Balancer Controller?

The AWS Load Balancer Controller is a Kubernetes controller that:
- Watches for Kubernetes Ingress resources
- Automatically creates AWS Application Load Balancers (ALB)
- Manages ALB configuration based on Ingress annotations
- Handles target group registration and health checks

## Features

- **Automatic ALB Creation**: Creates load balancers from Ingress resources
- **IAM Integration**: Uses IRSA (IAM Roles for Service Accounts) for secure AWS API access
- **Cost Optimization**: Shares ALBs across multiple Ingress resources
- **Health Checks**: Configures health checks based on Kubernetes readiness probes
- **TLS Support**: Automatic SSL/TLS certificate management with AWS ACM

## Prerequisites

- EKS cluster with OIDC provider configured
- VPC with properly tagged subnets
- Kubernetes and Helm providers configured

## Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `cluster_name` | Name of the EKS cluster | string | - | yes |
| `aws_region` | AWS region | string | - | yes |
| `vpc_id` | VPC ID | string | - | yes |
| `oidc_provider_arn` | ARN of OIDC provider | string | - | yes |
| `oidc_provider_url` | URL of OIDC provider | string | - | yes |
| `chart_version` | Helm chart version | string | `1.6.2` | no |
| `tags` | Tags to apply to resources | map(string) | `{}` | no |

## Outputs

| Output | Description |
|--------|-------------|
| `load_balancer_controller_role_arn` | ARN of the IAM role |
| `load_balancer_controller_service_account` | Name of the service account |

## Usage

```hcl
module "load_balancer" {
  source = "./modules/load-balancer"

  cluster_name       = "my-cluster"
  aws_region        = "us-east-1"
  vpc_id            = module.vpc.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  chart_version     = "1.6.2"
  
  tags = {
    Environment = "production"
    Project     = "IAI"
  }
  
  depends_on = [module.eks]
}
```

## IAM Permissions

The module creates an IAM policy with permissions for:
- Creating and managing Application Load Balancers
- Creating and managing Target Groups
- Configuring security groups
- Managing EC2 network interfaces
- Reading VPC and subnet information
- Integrating with AWS WAF and Shield

## Using with Ingress

After this module is applied, you can create Kubernetes Ingress resources:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 80
```

## Verification

After deployment, verify the controller is running:

```bash
# Check controller pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check service account
kubectl get sa -n kube-system aws-load-balancer-controller -o yaml
```

## Troubleshooting

### Controller not creating ALBs
1. Check controller logs: `kubectl logs -n kube-system deployment/aws-load-balancer-controller`
2. Verify OIDC provider is configured: `aws eks describe-cluster --name <cluster> --query cluster.identity.oidc`
3. Check IAM role trust policy allows service account
4. Verify subnets are tagged correctly:
   - Public subnets: `kubernetes.io/role/elb=1`
   - Private subnets: `kubernetes.io/role/internal-elb=1`

### IAM permissions errors
1. Check IAM policy is attached to role
2. Verify service account has role annotation
3. Review CloudTrail logs for denied API calls

## Cost Considerations

The controller itself is free, but created resources have costs:
- Application Load Balancer: ~$20-25/month
- Data processing charges: $0.008 per GB
- Per-rule charges: $0.01 per rule per hour (beyond 10 rules)

To minimize costs:
- Share ALBs across multiple Ingress resources using group annotations
- Use internal load balancers when external access isn't needed
- Clean up unused Ingress resources
