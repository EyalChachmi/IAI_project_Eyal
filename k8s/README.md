# Kubernetes Deployment for EKS

This directory contains Kubernetes manifests for deploying the IAI Project to Amazon EKS.

## Files

- `backend-deployment.yaml` - Backend deployment and service
- `frontend-deployment.yaml` - Frontend deployment and service
- `ingress.yaml` - AWS ALB Ingress Controller configuration
- `configmap.yaml` - Application configuration

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **kubectl** installed
3. **eksctl** (optional, for cluster creation)
4. **AWS ALB Ingress Controller** installed in your EKS cluster

## Quick Start

### 1. Create EKS Cluster (if needed)

```bash
eksctl create cluster \
  --name iai-cluster \
  --region eu-north-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed
```

### 2. Install AWS Load Balancer Controller

```bash
# Install the AWS Load Balancer Controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=iai-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 3. Deploy Images to ECR

```bash
cd ..
chmod +x deploy-to-ecr.sh
./deploy-to-ecr.sh
```

### 4. Deploy to EKS

```bash
chmod +x deploy-to-eks.sh
./deploy-to-eks.sh
```

## Manual Deployment

If you prefer manual deployment:

```bash
# Update kubeconfig
aws eks update-kubeconfig --region eu-north-1 --name iai-cluster

# Apply manifests
kubectl apply -f configmap.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f ingress.yaml

# Check status
kubectl get all
kubectl get ingress
```

## Configuration

### Update Image References

Before deploying, update the image references in the deployment files:

```bash
# Replace placeholders with actual values
sed -i 's/<AWS_ACCOUNT_ID>/YOUR_ACCOUNT_ID/g' backend-deployment.yaml frontend-deployment.yaml
sed -i 's/<AWS_REGION>/eu-north-1/g' backend-deployment.yaml frontend-deployment.yaml
```

### Resource Limits

Default resource limits (adjust based on your needs):

**Backend:**
- Requests: 100m CPU, 128Mi RAM
- Limits: 200m CPU, 256Mi RAM

**Frontend:**
- Requests: 50m CPU, 64Mi RAM
- Limits: 100m CPU, 128Mi RAM

## Scaling

```bash
# Scale backend
kubectl scale deployment iai-backend --replicas=3

# Scale frontend
kubectl scale deployment iai-frontend --replicas=3

# Auto-scaling
kubectl autoscale deployment iai-backend --cpu-percent=70 --min=2 --max=5
```

## Monitoring

```bash
# View logs
kubectl logs -l app=iai-backend -f
kubectl logs -l app=iai-frontend -f

# View pod status
kubectl get pods -w

# Describe pods
kubectl describe pod <pod-name>

# View events
kubectl get events --sort-by='.lastTimestamp'
```

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Image pull errors

Ensure your EKS nodes have IAM role with ECR permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ],
    "Resource": "*"
  }]
}
```

### LoadBalancer not provisioning

Check ALB Controller logs:
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## Cleanup

```bash
# Delete all resources
kubectl delete -f .

# Or delete specific resources
kubectl delete deployment iai-backend iai-frontend
kubectl delete service iai-backend iai-frontend
kubectl delete ingress iai-ingress

# Delete cluster (if needed)
eksctl delete cluster --name iai-cluster --region eu-north-1
```

## Cost Optimization

- Use t3.small or t3.medium instances for testing
- Enable cluster autoscaler
- Use spot instances for non-critical workloads
- Set appropriate resource requests/limits
- Delete unused resources

## Security Best Practices

- ✅ Non-root containers
- ✅ Security contexts defined
- ✅ Minimal capabilities
- ✅ Health checks configured
- ✅ Resource limits set
- ✅ Read-only root filesystem (where applicable)

## EKS Free Tier

AWS Free Tier includes:
- **750 hours** of t2.micro or t3.micro EC2 instances per month (12 months)
- EKS control plane: **$0.10/hour** (~$73/month) - NOT free
- Consider using local Kubernetes (minikube, kind) for development

For production testing on a budget, consider:
- Use 1-2 t3.small nodes
- Enable cluster autoscaler to scale down when idle
- Use spot instances
- Delete cluster when not in use
