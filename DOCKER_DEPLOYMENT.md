# IAI Project - Docker Deployment Guide

## Docker Files Overview

This project includes production-optimized Docker configurations:

### Backend Dockerfile Features
- **Multi-stage build**: Uses Python 3.11 slim image for smaller size
- **Security**: Runs as non-root user
- **Production server**: Uses Gunicorn with 4 workers
- **Health checks**: Built-in health monitoring
- **Optimized layers**: Dependencies cached separately from code

### Frontend Dockerfile Features
- **Multi-stage build**: Build stage with Node 16, serve stage with Nginx
- **Optimized size**: Final image is < 25MB
- **Production ready**: Nginx with gzip, caching, and security headers
- **React Router support**: Handles client-side routing
- **API proxying**: Forwards /api requests to backend

## Building and Running Locally

### Build Individual Images

```bash
# Build backend
cd backend
docker build -t iai-backend:latest .

# Build frontend
cd frontend
docker build -t iai-frontend:latest .
```

### Run with Docker Compose

```bash
# Build and start all services
docker-compose up --build

# Run in detached mode
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f
```

### Access the Application
- **Frontend**: http://localhost
- **Backend API**: http://localhost:5000/api/users
- **Health Checks**: 
  - Frontend: http://localhost/health
  - Backend: http://localhost:5000/api/health

## AWS ECR Deployment

### Prerequisites
1. AWS CLI installed and configured
2. AWS account with ECR access
3. Docker installed

### Step 1: Create ECR Repositories

```bash
# Set your AWS region
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create repositories
aws ecr create-repository \
    --repository-name iai-backend \
    --region $AWS_REGION

aws ecr create-repository \
    --repository-name iai-frontend \
    --region $AWS_REGION
```

### Step 2: Authenticate Docker to ECR

```bash
# Get ECR login password and authenticate
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

### Step 3: Build, Tag, and Push Backend

```bash
# Navigate to backend directory
cd backend

# Build the image
docker build -t iai-backend:latest .

# Tag for ECR
docker tag iai-backend:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:latest

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:latest

# Optional: Tag with version
docker tag iai-backend:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:v1.0.0

docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:v1.0.0
```

### Step 4: Build, Tag, and Push Frontend

```bash
# Navigate to frontend directory
cd ../frontend

# Build the image
docker build -t iai-frontend:latest .

# Tag for ECR
docker tag iai-frontend:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:latest

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:latest

# Optional: Tag with version
docker tag iai-frontend:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:v1.0.0

docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:v1.0.0
```

### Step 5: Verify Images in ECR

```bash
# List backend images
aws ecr describe-images \
    --repository-name iai-backend \
    --region $AWS_REGION

# List frontend images
aws ecr describe-images \
    --repository-name iai-frontend \
    --region $AWS_REGION
```

## Automated Deployment Script

Create a file named `deploy-to-ecr.sh`:

```bash
#!/bin/bash

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
VERSION="v1.0.0"

echo "🚀 Starting deployment to ECR..."

# Authenticate
echo "🔐 Authenticating with ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Backend
echo "📦 Building and pushing backend..."
cd backend
docker build -t iai-backend:latest .
docker tag iai-backend:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:latest
docker tag iai-backend:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:$VERSION
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:$VERSION
cd ..

# Frontend
echo "🎨 Building and pushing frontend..."
cd frontend
docker build -t iai-frontend:latest .
docker tag iai-frontend:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:latest
docker tag iai-frontend:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:$VERSION
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:$VERSION
cd ..

echo "✅ Deployment complete!"
echo "Backend: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:$VERSION"
echo "Frontend: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:$VERSION"
```

Make it executable and run:

```bash
chmod +x deploy-to-ecr.sh
./deploy-to-ecr.sh
```

## Pull and Run from ECR

```bash
# Pull images
docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:latest
docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:latest

# Run backend
docker run -d -p 5000:5000 \
    --name iai-backend \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-backend:latest

# Run frontend
docker run -d -p 80:80 \
    --name iai-frontend \
    --link iai-backend:backend \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/iai-frontend:latest
```

## Docker Image Optimization

### Backend Image Size
- Base image: python:3.11-slim (~130MB)
- Final image: ~200MB
- Optimizations:
  - Multi-stage build pattern possible
  - Minimal dependencies
  - No dev packages

### Frontend Image Size
- Build stage: node:16-alpine (~120MB during build)
- Final image: nginx:alpine (~24MB)
- Optimizations:
  - Multi-stage build
  - Only static files in final image
  - Gzip compression enabled

## Troubleshooting

### ECR Authentication Issues
```bash
# Re-authenticate
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

### Check Image Vulnerabilities
```bash
# Scan backend image
aws ecr start-image-scan \
    --repository-name iai-backend \
    --image-id imageTag=latest \
    --region $AWS_REGION

# Get scan results
aws ecr describe-image-scan-findings \
    --repository-name iai-backend \
    --image-id imageTag=latest \
    --region $AWS_REGION
```

### Clean Up ECR Images
```bash
# Delete specific image
aws ecr batch-delete-image \
    --repository-name iai-backend \
    --image-ids imageTag=v1.0.0 \
    --region $AWS_REGION

# Delete repository
aws ecr delete-repository \
    --repository-name iai-backend \
    --force \
    --region $AWS_REGION
```

## Cost Optimization

- ECR charges for storage (first 500 GB-month free)
- Use lifecycle policies to delete old images:

```bash
# Create lifecycle policy
cat > lifecycle-policy.json << EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF

# Apply policy
aws ecr put-lifecycle-policy \
    --repository-name iai-backend \
    --lifecycle-policy-text file://lifecycle-policy.json \
    --region $AWS_REGION
```

## Next Steps

After deploying to ECR, you can:
1. Deploy to ECS (Elastic Container Service)
2. Deploy to EKS (Elastic Kubernetes Service)
3. Deploy to AWS App Runner
4. Use with AWS Fargate
5. Create CI/CD pipeline with CodePipeline

## Security Best Practices

1. **Use IAM roles** instead of access keys when possible
2. **Enable image scanning** in ECR
3. **Use private repositories** (default)
4. **Implement lifecycle policies** to remove old images
5. **Tag images with versions** for better tracking
6. **Use secrets management** for sensitive data (AWS Secrets Manager)
