#!/bin/bash

# IAI Project - Deploy to AWS ECR
# This script builds and pushes Docker images to AWS ECR

set -e

# Configuration
AWS_REGION="${AWS_REGION:-eu-north-1}"
VERSION="${VERSION:-v1.0.0}"
FREE_TIER_LIMIT_MB=500  # AWS Free Tier limit for ECR storage

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 IAI Project - ECR Deployment Script${NC}"
echo "========================================"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Get AWS Account ID
echo -e "${YELLOW}📋 Getting AWS Account ID...${NC}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}❌ Failed to get AWS Account ID. Please check your AWS credentials.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AWS Account ID: $AWS_ACCOUNT_ID${NC}"
echo -e "${GREEN}✓ Region: $AWS_REGION${NC}"

# Function to check ECR storage usage
check_ecr_storage() {
    echo -e "\n${YELLOW}📊 Checking ECR storage usage...${NC}"
    total_size_bytes=0
    
    for repo in iai-backend iai-frontend; do
        if aws ecr describe-repositories --repository-names $repo --region $AWS_REGION &> /dev/null; then
            # Get all images in the repository
            images=$(aws ecr describe-images --repository-name $repo --region $AWS_REGION --query 'imageDetails[*].imageSizeInBytes' --output text 2>/dev/null || echo "0")
            if [ "$images" != "0" ]; then
                repo_size=$(echo $images | tr '\t' '\n' | awk '{s+=$1} END {print s}')
                total_size_bytes=$((total_size_bytes + repo_size))
                repo_size_mb=$((repo_size / 1024 / 1024))
                echo -e "  ${repo}: ${repo_size_mb} MB"
            fi
        fi
    done
    
    total_size_mb=$((total_size_bytes / 1024 / 1024))
    echo -e "${GREEN}✓ Total ECR storage: ${total_size_mb} MB / ${FREE_TIER_LIMIT_MB} MB (Free Tier limit)${NC}"
    
    # Warning if approaching limit
    if [ $total_size_mb -gt 400 ]; then
        echo -e "${YELLOW}⚠️  WARNING: You're using more than 80% of the free tier limit!${NC}"
        echo -e "${YELLOW}   Consider deleting old image versions to stay within free tier.${NC}"
    fi
    
    if [ $total_size_mb -gt $FREE_TIER_LIMIT_MB ]; then
        echo -e "${RED}❌ ERROR: Storage exceeds free tier limit!${NC}"
        echo -e "${RED}   You will be charged \$0.10 per GB/month for excess storage.${NC}"
        echo -e "${YELLOW}   Current excess: $((total_size_mb - FREE_TIER_LIMIT_MB)) MB (~\$$(echo "scale=2; ($total_size_mb - $FREE_TIER_LIMIT_MB) * 0.10 / 1024" | bc)/month)${NC}"
        read -p "Do you want to continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to set lifecycle policy to keep only last 3 images
set_lifecycle_policy() {
    local repo=$1
    echo -e "${YELLOW}  Setting lifecycle policy for $repo (keep last 3 images)...${NC}"
    
    cat > /tmp/ecr-lifecycle-policy.json <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep only last 3 images to stay in free tier",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 3
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF

    aws ecr put-lifecycle-policy \
        --repository-name $repo \
        --region $AWS_REGION \
        --lifecycle-policy-text file:///tmp/ecr-lifecycle-policy.json &> /dev/null
    
    echo -e "${GREEN}✓ Lifecycle policy set for $repo${NC}"
    rm /tmp/ecr-lifecycle-policy.json
}

# Create ECR repositories if they don't exist
echo -e "\n${YELLOW}📦 Creating ECR repositories...${NC}"
for repo in iai-backend iai-frontend; do
    if aws ecr describe-repositories --repository-names $repo --region $AWS_REGION &> /dev/null; then
        echo -e "${GREEN}✓ Repository $repo already exists${NC}"
    else
        echo -e "${YELLOW}  Creating repository $repo...${NC}"
        aws ecr create-repository \
            --repository-name $repo \
            --region $AWS_REGION \
            --image-scanning-configuration scanOnPush=true \
            --encryption-configuration encryptionType=AES256
        echo -e "${GREEN}✓ Repository $repo created${NC}"
    fi
    
    # Set lifecycle policy to keep only 3 images (stay in free tier)
    set_lifecycle_policy $repo
done

# Check current storage usage before pushing
check_ecr_storage

# Authenticate Docker to ECR
echo -e "\n${YELLOW}🔐 Authenticating Docker with ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
echo -e "${GREEN}✓ Authentication successful${NC}"

# Build and push backend
echo -e "\n${YELLOW}🐍 Building and pushing Backend image...${NC}"
cd backend
docker build -t iai-backend:latest .
docker tag iai-backend:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:latest
docker tag iai-backend:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:$VERSION

echo -e "${YELLOW}  Pushing backend:latest...${NC}"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:latest
echo -e "${YELLOW}  Pushing backend:$VERSION...${NC}"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:$VERSION
echo -e "${GREEN}✓ Backend images pushed successfully${NC}"
cd ..

# Build and push frontend
echo -e "\n${YELLOW}⚛️  Building and pushing Frontend image...${NC}"
cd frontend
docker build -t iai-frontend:latest .
docker tag iai-frontend:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:latest
docker tag iai-frontend:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:$VERSION

echo -e "${YELLOW}  Pushing frontend:latest...${NC}"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:latest
echo -e "${YELLOW}  Pushing frontend:$VERSION...${NC}"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:$VERSION
echo -e "${GREEN}✓ Frontend images pushed successfully${NC}"
cd ..

# Final storage check
check_ecr_storage

# Summary
echo -e "\n${GREEN}✅ Deployment Complete!${NC}"
echo "========================================"
echo -e "Backend Image URIs:"
echo -e "  ${YELLOW}latest:${NC} $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:latest"
echo -e "  ${YELLOW}$VERSION:${NC} $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:$VERSION"
echo ""
echo -e "Frontend Image URIs:"
echo -e "  ${YELLOW}latest:${NC} $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:latest"
echo -e "  ${YELLOW}$VERSION:${NC} $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:$VERSION"
echo ""
echo -e "${GREEN}💡 Free Tier Protection:${NC}"
echo -e "   • Lifecycle policy: Keeps only last 3 images per repository"
echo -e "   • Automatic cleanup: Old images are deleted automatically"
echo -e "   • Storage limit: 500 MB (AWS Free Tier)"
echo ""
echo -e "${GREEN}🎉 All images are now available in AWS ECR!${NC}"
