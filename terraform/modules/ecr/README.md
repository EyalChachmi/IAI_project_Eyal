# ECR Module

This module creates Amazon ECR (Elastic Container Registry) repositories for storing Docker images.

## Resources Created

- ECR Repository for Backend
- ECR Repository for Frontend
- Lifecycle policies for both repositories

## Features

- **Image Scanning**: Automatic vulnerability scanning on push
- **Encryption**: AES256 encryption at rest
- **Lifecycle Policies**: Automatic cleanup of old images
- **Immutable Tags**: Configurable (currently set to MUTABLE)

## Lifecycle Policy

The module configures automatic image cleanup:
- Keeps the last N images (default: 3)
- Automatically removes older images
- Helps manage ECR storage costs
- Applies to all tagged and untagged images

## Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `backend_repository_name` | Name of backend ECR repository | string | `iai-backend` | no |
| `frontend_repository_name` | Name of frontend ECR repository | string | `iai-frontend` | no |
| `max_image_count` | Max images to keep | number | `3` | no |
| `tags` | Tags to apply to resources | map(string) | `{}` | no |

## Outputs

| Output | Description |
|--------|-------------|
| `backend_repository_url` | ECR repository URL for backend |
| `frontend_repository_url` | ECR repository URL for frontend |
| `backend_repository_name` | ECR repository name for backend |
| `frontend_repository_name` | ECR repository name for frontend |
| `backend_repository_arn` | ECR repository ARN for backend |
| `frontend_repository_arn` | ECR repository ARN for frontend |

## Usage

```hcl
module "ecr" {
  source = "./modules/ecr"

  backend_repository_name  = "my-backend"
  frontend_repository_name = "my-frontend"
  max_image_count         = 5
  
  tags = {
    Environment = "production"
    Project     = "IAI"
  }
}
```

## Pushing Images

After creating repositories, authenticate and push images:

```bash
# Get authentication token
aws ecr get-login-password --region eu-north-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-north-1.amazonaws.com

# Tag image
docker tag my-backend:latest <backend-repo-url>:latest

# Push image
docker push <backend-repo-url>:latest
```

## Storage Costs

ECR charges for:
- Storage: $0.10 per GB-month
- Data transfer out to internet

The lifecycle policy helps minimize storage costs by:
- Removing old images automatically
- Keeping only recent versions
- Cleaning up untagged images

With the default policy (keep 3 images):
- Estimated storage per repo: ~1 GB
- Monthly cost: ~$0.20 per repository
- Total for both repos: ~$0.40/month

## Security

- **Encryption**: All images encrypted at rest with AES256
- **Image Scanning**: Automatic vulnerability scanning on push
- **Access Control**: Use IAM policies to control access
- **Private**: Repositories are private by default
