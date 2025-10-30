#!/bin/bash

# IAI Project - Deploy to AWS EKS
# This script deploys the application to an EKS cluster

set -e

# Configuration
AWS_REGION="${AWS_REGION:-eu-north-1}"
CLUSTER_NAME="${CLUSTER_NAME:-iai-cluster}"
VERSION="${VERSION:-v1.0.0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 IAI Project - EKS Deployment Script${NC}"
echo "========================================"

# Check prerequisites
echo -e "\n${YELLOW}🔍 Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites installed${NC}"

# Get AWS Account ID
echo -e "\n${YELLOW}📋 Getting AWS Account ID...${NC}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}❌ Failed to get AWS Account ID${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AWS Account ID: $AWS_ACCOUNT_ID${NC}"

# Update kubeconfig for EKS
echo -e "\n${YELLOW}☸️  Updating kubeconfig for EKS cluster...${NC}"
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to update kubeconfig. Make sure the cluster exists.${NC}"
    echo -e "${YELLOW}💡 Create a cluster with: eksctl create cluster --name $CLUSTER_NAME --region $AWS_REGION${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Kubeconfig updated${NC}"

# Verify cluster connection
echo -e "\n${YELLOW}🔌 Verifying cluster connection...${NC}"
kubectl cluster-info
kubectl get nodes
echo -e "${GREEN}✓ Connected to cluster${NC}"

# Update Kubernetes manifests with actual values
echo -e "\n${YELLOW}📝 Updating Kubernetes manifests...${NC}"
cd k8s

# Update image references
for file in backend-deployment.yaml frontend-deployment.yaml; do
    sed -i.bak "s/<AWS_ACCOUNT_ID>/$AWS_ACCOUNT_ID/g" $file
    sed -i.bak "s/<AWS_REGION>/$AWS_REGION/g" $file
    rm ${file}.bak
    echo -e "${GREEN}✓ Updated $file${NC}"
done

cd ..

# Apply ConfigMap
echo -e "\n${YELLOW}⚙️  Applying ConfigMap...${NC}"
kubectl apply -f k8s/configmap.yaml
echo -e "${GREEN}✓ ConfigMap applied${NC}"

# Deploy Backend
echo -e "\n${YELLOW}🐍 Deploying Backend...${NC}"
kubectl apply -f k8s/backend-deployment.yaml
echo -e "${GREEN}✓ Backend deployed${NC}"

# Wait for backend to be ready
echo -e "${YELLOW}⏳ Waiting for backend pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=iai-backend --timeout=120s
echo -e "${GREEN}✓ Backend is ready${NC}"

# Deploy Frontend
echo -e "\n${YELLOW}⚛️  Deploying Frontend...${NC}"
kubectl apply -f k8s/frontend-deployment.yaml
echo -e "${GREEN}✓ Frontend deployed${NC}"

# Wait for frontend to be ready
echo -e "${YELLOW}⏳ Waiting for frontend pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=iai-frontend --timeout=120s
echo -e "${GREEN}✓ Frontend is ready${NC}"

# Deploy Ingress (optional)
echo -e "\n${YELLOW}🌐 Deploying Ingress...${NC}"
read -p "Do you want to deploy the ALB Ingress? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl apply -f k8s/ingress.yaml
    echo -e "${GREEN}✓ Ingress deployed${NC}"
    echo -e "${YELLOW}⏳ Waiting for ALB to be provisioned (this may take a few minutes)...${NC}"
    sleep 10
    INGRESS_URL=$(kubectl get ingress iai-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$INGRESS_URL" ]; then
        echo -e "${GREEN}✓ Application URL: http://$INGRESS_URL${NC}"
    else
        echo -e "${YELLOW}⏳ ALB is still being provisioned. Check later with:${NC}"
        echo -e "   kubectl get ingress iai-ingress"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping Ingress deployment${NC}"
fi

# Display deployment status
echo -e "\n${GREEN}✅ Deployment Complete!${NC}"
echo "========================================"
echo -e "\n${BLUE}📊 Deployment Status:${NC}"
kubectl get deployments
echo ""
kubectl get pods
echo ""
kubectl get services

# Get LoadBalancer URLs
echo -e "\n${BLUE}🔗 Service URLs:${NC}"
FRONTEND_URL=$(kubectl get service iai-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
echo -e "${YELLOW}Frontend:${NC} http://$FRONTEND_URL"

# Useful commands
echo -e "\n${BLUE}💡 Useful Commands:${NC}"
echo "  View logs (backend):  kubectl logs -l app=iai-backend -f"
echo "  View logs (frontend): kubectl logs -l app=iai-frontend -f"
echo "  Scale deployment:     kubectl scale deployment iai-backend --replicas=3"
echo "  Delete deployment:    kubectl delete -f k8s/"
echo "  Port forward:         kubectl port-forward service/iai-frontend 8080:80"

echo -e "\n${GREEN}🎉 Application is now running on EKS!${NC}"
