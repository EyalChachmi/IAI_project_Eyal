# GitHub Actions Deployment Guide

This guide explains how to set up automated deployment to AWS EKS using GitHub Actions.

## Prerequisites

Before setting up GitHub Actions, ensure you have:

1. ✅ AWS Account with appropriate permissions
2. ✅ EKS Cluster created and running
3. ✅ ECR repositories created (iai-backend, iai-frontend)
4. ✅ AWS IAM user with programmatic access
5. ✅ kubectl configured locally for testing

## Setup Instructions

### Step 1: Create EKS Cluster

If you haven't created an EKS cluster yet:

```bash
# Install eksctl (if not already installed)
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Create cluster
eksctl create cluster \
  --name iai-cluster \
  --region eu-north-1 \
  --nodegroup-name standard-workers \
  --node-type t3.small \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed
```

**Note:** EKS control plane costs ~$73/month. Consider using ECS or App Runner for free tier.

### Step 2: Create ECR Repositories

```bash
aws ecr create-repository --repository-name iai-backend --region eu-north-1
aws ecr create-repository --repository-name iai-frontend --region eu-north-1
```

### Step 3: Create IAM User for GitHub Actions

1. Go to AWS Console → IAM → Users → Create User
2. User name: `github-actions-deployer`
3. Select "Attach policies directly"
4. Attach the following policies:
   - `AmazonEC2ContainerRegistryPowerUser`
   - `AmazonEKSClusterPolicy`
   - `AmazonEKSWorkerNodePolicy`
   
5. Or create a custom policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

6. Create access keys and save them securely

### Step 4: Configure GitHub Secrets

Go to your GitHub repository: `https://github.com/EyalChachmi/IAI_project_Eyal/settings/secrets/actions`

Add the following secrets:

1. **AWS_ACCESS_KEY_ID**
   - Value: Your IAM user access key ID

2. **AWS_SECRET_ACCESS_KEY**
   - Value: Your IAM user secret access key

**How to add secrets:**
1. Click "New repository secret"
2. Enter the name (e.g., `AWS_ACCESS_KEY_ID`)
3. Paste the value
4. Click "Add secret"

### Step 5: Update EKS Node IAM Role

Your EKS worker nodes need permission to pull images from ECR:

```bash
# Get the node group role name
NODE_ROLE=$(aws eks describe-nodegroup \
  --cluster-name iai-cluster \
  --nodegroup-name standard-workers \
  --region eu-north-1 \
  --query 'nodegroup.nodeRole' \
  --output text | cut -d'/' -f2)

# Attach ECR policy to the role
aws iam attach-role-policy \
  --role-name $NODE_ROLE \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

### Step 6: Install AWS Load Balancer Controller (for Ingress)

```bash
# Add the EKS Helm chart repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Create IAM service account
eksctl create iamserviceaccount \
  --cluster=iai-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve \
  --region=eu-north-1

# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=iai-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### Step 7: Test the Workflow

1. **Manual Trigger:**
   - Go to Actions tab in GitHub
   - Click "Deploy to AWS EKS"
   - Click "Run workflow"
   - Select branch: `main`
   - Click "Run workflow"

2. **Automatic Trigger:**
   - Push any commit to the `main` branch
   - GitHub Actions will automatically start

### Step 8: Monitor Deployment

1. **In GitHub:**
   - Go to the "Actions" tab
   - Click on the running workflow
   - Watch the logs in real-time

2. **In AWS/Kubernetes:**
   ```bash
   # Watch pods
   kubectl get pods -w
   
   # Check deployment status
   kubectl get deployments
   
   # View logs
   kubectl logs -l app=iai-backend -f
   kubectl logs -l app=iai-frontend -f
   
   # Get service URL
   kubectl get service iai-frontend
   ```

## Workflow File

The workflow is defined in `.github/workflows/deploy-eks.yml` and includes:

### Triggers
- Push to `main` branch
- Manual workflow dispatch

### Steps
1. **Checkout code** - Gets the latest code
2. **Configure AWS credentials** - Uses GitHub secrets
3. **Login to ECR** - Authenticates Docker with ECR
4. **Build Backend** - Builds and pushes backend Docker image
5. **Build Frontend** - Builds and pushes frontend Docker image
6. **Update kubeconfig** - Connects to EKS cluster
7. **Update manifests** - Replaces placeholders with actual values
8. **Deploy to EKS** - Applies Kubernetes manifests
9. **Wait for readiness** - Ensures pods are running
10. **Get URL** - Retrieves the application URL

## Troubleshooting

### Authentication Errors

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Update kubeconfig
aws eks update-kubeconfig --region eu-north-1 --name iai-cluster
```

### Image Pull Errors

Check if EKS nodes can access ECR:
```bash
kubectl describe pod <pod-name>
```

Ensure the node IAM role has ECR permissions.

### LoadBalancer Not Creating

Check AWS Load Balancer Controller:
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Deployment Timeout

Increase timeout or check pod logs:
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

## Testing Communication Between Frontend and Backend

The frontend communicates with the backend through Kubernetes services:

1. **Backend Service:** `iai-backend:5000` (ClusterIP)
2. **Frontend Service:** `iai-frontend:80` (LoadBalancer)
3. **Nginx Config:** Proxies `/api/*` requests to backend

Test the connection:
```bash
# Get frontend URL
FRONTEND_URL=$(kubectl get service iai-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test frontend
curl http://$FRONTEND_URL

# Test backend through frontend proxy
curl http://$FRONTEND_URL/api/health

# Test direct backend access (from within cluster)
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://iai-backend:5000/api/health
```

## Cost Optimization

### EKS Costs
- **Control Plane:** $0.10/hour (~$73/month) ❌ NOT in free tier
- **Worker Nodes:** EC2 costs (t3.small ~$0.02/hour)
- **Data Transfer:** First 100 GB/month free

### Ways to Reduce Costs

1. **Use Spot Instances:**
   ```bash
   eksctl create nodegroup \
     --cluster=iai-cluster \
     --spot \
     --instance-types=t3.small
   ```

2. **Use Fargate (serverless):**
   - No worker node costs
   - Pay only for running pods

3. **Scale down when not in use:**
   ```bash
   kubectl scale deployment iai-backend --replicas=0
   kubectl scale deployment iai-frontend --replicas=0
   ```

4. **Delete cluster when testing is done:**
   ```bash
   eksctl delete cluster --name iai-cluster --region eu-north-1
   ```

## Alternative: Use ECS Instead

ECS is more cost-effective for learning:
- No control plane costs
- Use Fargate free tier (limited hours/month)
- See `.github/workflows/deploy-ecs.yml` for ECS workflow

## Security Best Practices

✅ Use GitHub Secrets for credentials
✅ Limit IAM permissions (principle of least privilege)
✅ Enable ECR image scanning
✅ Use non-root containers
✅ Set resource limits
✅ Enable network policies
✅ Rotate credentials regularly

## Next Steps

1. Set up monitoring (CloudWatch, Prometheus)
2. Configure autoscaling
3. Add staging environment
4. Implement blue-green deployments
5. Add automated tests before deployment
6. Set up alerts and notifications

## Support

If you encounter issues:
1. Check GitHub Actions logs
2. Check Kubernetes pod logs
3. Review AWS CloudWatch logs
4. Verify IAM permissions
5. Check network/security group settings
