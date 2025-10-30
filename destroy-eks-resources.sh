#!/bin/bash

# Script to clean up EKS deployment and AWS resources

set -e

REGION="eu-north-1"
CLUSTER_NAME="iai-cluster"

echo "🧹 Starting cleanup of EKS resources..."
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "⚠️  kubectl not configured. Configuring now..."
    aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME || {
        echo "❌ Failed to configure kubectl. Cluster may not exist."
        echo "Proceeding with Terraform destroy only..."
    }
fi

# Delete Kubernetes resources
if kubectl cluster-info &> /dev/null; then
    echo "📦 Deleting Kubernetes resources..."
    
    echo "  - Deleting Ingress..."
    kubectl delete -f k8s/ingress.yaml --ignore-not-found=true
    
    echo "  - Deleting Frontend deployment..."
    kubectl delete -f k8s/frontend-deployment.yaml --ignore-not-found=true
    
    echo "  - Deleting Backend deployment..."
    kubectl delete -f k8s/backend-deployment.yaml --ignore-not-found=true
    
    echo "  - Deleting ConfigMap..."
    kubectl delete -f k8s/configmap.yaml --ignore-not-found=true
    
    echo "  - Waiting for LoadBalancers to be deleted (this may take a few minutes)..."
    sleep 30
    
    echo "✅ Kubernetes resources deleted"
    echo ""
else
    echo "⏭️  Skipping Kubernetes resource deletion (cluster not accessible)"
    echo ""
fi

# Delete Terraform infrastructure
echo "🏗️  Destroying Terraform infrastructure..."
cd terraform

if [ ! -d ".terraform" ]; then
    echo "⚠️  Terraform not initialized. Initializing now..."
    terraform init
fi

echo ""
echo "This will destroy:"
echo "  - EKS Cluster"
echo "  - Worker Nodes"
echo "  - VPC and Networking"
echo "  - ECR Repositories (and all images)"
echo "  - Load Balancer Controller"
echo "  - All IAM roles and policies"
echo ""
echo "⚠️  WARNING: This action cannot be undone!"
echo ""

read -p "Are you sure you want to destroy all resources? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Destroy cancelled"
    exit 1
fi

echo ""
echo "Starting Terraform destroy..."
terraform destroy -auto-approve

cd ..

echo ""
echo "✅ All AWS resources have been destroyed!"
echo ""
echo "📝 Note: The following still exist and may incur minimal costs:"
echo "  - ECR images (if lifecycle policy hasn't cleaned them yet)"
echo "  - CloudWatch logs (minimal storage cost)"
echo ""
echo "To completely remove ECR repositories and images manually:"
echo "  aws ecr delete-repository --repository-name iai-backend --region $REGION --force"
echo "  aws ecr delete-repository --repository-name iai-frontend --region $REGION --force"
echo ""
echo "🎉 Cleanup complete!"
