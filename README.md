# User Management System

A production-ready full-stack web application for user management and search functionality. The system consists of a RESTful API backend built with Python Flask and a responsive React frontend, both containerized and deployed to AWS EKS with automated CI/CD pipeline.

## Table of Contents
- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Technologies](#technologies)
- [Features](#features)
- [Project Structure](#project-structure)
- [Local Development](#local-development)
- [Deployment](#deployment)
- [Component Details](#component-details)
- [Monitoring and Health Checks](#monitoring-and-health-checks)
- [License](#license)
- [Author](#author)

## Project Overview

This application provides a user management interface with search capabilities. The backend exposes a RESTful API for user data operations, while the frontend provides an intuitive card-based interface for browsing and searching users. The entire system is containerized using Docker and can be deployed to Kubernetes clusters on AWS EKS.

## Architecture

The application follows a microservices architecture with clear separation between frontend and backend services:

```
User Browser
    |
    v
Application Load Balancer (AWS ALB)
    |
    v
Kubernetes Ingress Controller
    |
    +-- /api/* --> Backend Service (Flask + Gunicorn)
    |                   |
    |                   v
    |              users.json data
    |
    +-- /* ------> Frontend Service (React + Nginx)
```

**Request Flow:**
1. User accesses the application through AWS Application Load Balancer
2. ALB routes traffic to Kubernetes cluster ingress
3. Ingress controller distributes requests based on path:
   - API requests (/api/*) go to backend pods
   - Static assets and pages (/*) are served by frontend pods
4. Frontend communicates with backend via Nginx reverse proxy
5. Backend reads user data from JSON file and returns responses

**Infrastructure Components:**
- AWS VPC with public and private subnets across 2 availability zones
- EKS cluster with managed node groups (t3.small instances)
- ECR repositories for Docker images with lifecycle policies
- Application Load Balancer for external traffic
- Separate Kubernetes namespaces for backend and frontend isolation

## Technologies

### Backend Stack
- **Python 3.11**: Programming language
- **Flask 3.0.0**: Lightweight web framework for REST API
- **Flask-CORS 4.0.0**: Cross-Origin Resource Sharing support
- **Gunicorn 21.2.0**: Production WSGI HTTP server (4 workers, 2 threads each)
- **Requests 2.31.0**: HTTP library for health checks

### Frontend Stack
- **React 17.0.2**: JavaScript library for building user interfaces
- **React-DOM 17.0.2**: DOM rendering for React
- **Axios 0.27.2**: Promise-based HTTP client for API communication
- **React Scripts 4.0.3**: Build tooling and development server
- **Nginx 1.25-alpine**: Production web server and reverse proxy

### Infrastructure & DevOps
- **Docker**: Containerization with multi-stage builds
- **Docker Compose**: Local development orchestration
- **Kubernetes**: Container orchestration platform
- **AWS EKS**: Managed Kubernetes service (version 1.28)
- **AWS ECR**: Container image registry with encryption
- **AWS VPC**: Network isolation with NAT gateways
- **AWS ALB**: Application Load Balancer with health checks
- **Terraform**: Infrastructure as Code for AWS resources
- **GitHub Actions**: CI/CD automation pipeline

### Kubernetes Components
- **Deployments**: Replica management for frontend (2 pods) and backend (2 pods)
- **Services**: ClusterIP services for internal communication
- **Ingress**: ALB-based ingress with path routing
- **ConfigMaps**: Environment configuration for backend
- **Namespaces**: Logical separation (backend, frontend, default)

## Features

### Backend API Features
- RESTful API design with JSON responses
- CORS enabled for cross-origin requests
- Multiple endpoints: list all users, get user by ID, search by ID
- Health check endpoint for monitoring
- Error handling with appropriate HTTP status codes
- Structured JSON response format with success flags
- Production-ready with Gunicorn (handles concurrent requests)
- Non-root container execution for security
- Request timeout configuration (60 seconds)
- Access and error logging to stdout/stderr

### Frontend Application Features
- Card-based user interface displaying user information
- Real-time search functionality (filter users by ID)
- Search input with clear button
- Result count display
- Empty state handling for no results
- Responsive design (mobile, tablet, desktop breakpoints)
- Loading states with spinner animations
- Error handling with user-friendly messages
- Nginx reverse proxy for backend API requests
- Static asset caching (1 year expiration)
- Gzip compression for faster page loads
- Security headers (X-Frame-Options, X-Content-Type-Options, XSS-Protection)
- React Router support (SPA routing)

### DevOps & Infrastructure Features
- Multi-stage Docker builds for optimized image sizes (frontend: 50MB)
- Docker health checks for both services
- Kubernetes readiness and liveness probes
- Automated deployment via GitHub Actions on push to main branch
- ECR lifecycle policies (keep last 3 images per repository)
- Infrastructure provisioned via Terraform modules
- Automated aws-auth ConfigMap configuration
- Namespace-based service isolation
- Cross-namespace communication via proxy services
- Automated cleanup scripts for resource destruction
- ALB provisioning with retry logic
- Non-privileged container execution (UID 1000)

## Project Structure

```
.
├── backend/                          # Python Flask API
│   ├── app.py                       # Main application with route handlers
│   ├── Dockerfile                   # Backend container image definition
│   ├── requirements.txt             # Python dependencies
│   └── data/
│       └── users.json              # User data storage (JSON format)
│
├── frontend/                        # React application
│   ├── Dockerfile                   # Multi-stage build for frontend
│   ├── nginx.conf                   # Nginx configuration (reverse proxy, caching)
│   ├── package.json                 # Node.js dependencies
│   ├── public/
│   │   └── index.html              # HTML entry point
│   └── src/
│       ├── App.js                   # Main React component
│       ├── App.css                  # Application styles
│       ├── index.js                 # React DOM render
│       ├── components/              # React components
│       │   ├── SearchBar.js         # Search input component
│       │   ├── UserCard.js          # Individual user card
│       │   └── UserList.js          # User list container
│       └── services/
│           └── api.js               # Axios API client
│
├── k8s/                             # Kubernetes manifests
│   ├── namespaces.yaml              # Backend and frontend namespaces
│   ├── backend-deployment.yaml      # Backend deployment and service
│   ├── frontend-deployment.yaml     # Frontend deployment and service
│   ├── configmap.yaml               # Backend environment configuration
│   ├── ingress.yaml                 # ALB ingress with path routing
│   └── proxy-services.yaml          # Cross-namespace service proxies
│
├── terraform/                       # Infrastructure as Code
│   ├── main.tf                      # Root module configuration
│   ├── variables.tf                 # Input variables
│   ├── outputs.tf                   # Output values
│   └── modules/
│       ├── vpc/                     # VPC, subnets, NAT gateways
│       ├── eks/                     # EKS cluster and node groups
│       ├── ecr/                     # Container registries
│       └── load-balancer/           # ALB controller IAM and installation
│
├── .github/workflows/
│   └── deploy-eks.yml               # CI/CD pipeline definition
│
├── docker-compose.yml               # Local development environment
└── destroy-eks-resources.sh         # Cleanup script for AWS resources
```

## Local Development

### Prerequisites
- Docker and Docker Compose installed
- Python 3.11+ (for local backend development)

### Using Docker Compose (Recommended)

Start both services with a single command:

```bash
docker-compose up -d
```

Access the application:
- Frontend: http://localhost:8080
- Backend API: http://localhost:5000/api/users
- Health check: http://localhost:5000/api/health

View logs:
```bash
docker-compose logs -f backend    # Backend logs
docker-compose logs -f frontend   # Frontend logs
docker-compose logs -f            # All logs
```

Stop services:
```bash
docker-compose down
```

Rebuild after code changes:
```bash
docker-compose up --build
```

### Manual Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate 
pip install -r requirements.txt
python app.py
```

Backend runs on http://localhost:5000

### Manual Frontend Setup

```bash
cd frontend
npm install
npm start
```

Frontend runs on http://localhost:3000

Note: When running manually, update `frontend/src/services/api.js` to point to `http://localhost:5000/api`

## Deployment

### Infrastructure Setup with Terraform

cd terraform
terraform init
terraform plan
terraform apply
```

This creates:
- VPC with 2 public and 2 private subnets
- EKS cluster with managed node group (2 t3.small instances)
- ECR repositories for backend and frontend images
- IAM roles and policies for EKS and ALB controller
- Load Balancer Controller installed via Helm

3. Configure kubectl:
```bash
aws eks update-kubeconfig --region eu-north-1 --name iai-cluster
```

### Automated Deployment with GitHub Actions

The repository includes a GitHub Actions workflow that automatically builds and deploys on push to main branch.

**Setup:**

1. Create GitHub repository secrets:
   - `AWS_ACCESS_KEY_ID`: AWS access key for github-actions-deployer IAM user
   - `AWS_SECRET_ACCESS_KEY`: AWS secret key

2. The workflow will:
   - Build Docker images with commit SHA tags
   - Push images to ECR
   - Update Kubernetes manifests with new image tags
   - Deploy to EKS cluster
   - Wait for rollout to complete
   - Output application URL

### Cleanup

To destroy all AWS resources:

```bash
./destroy-eks-resources.sh
```

This script:
- Deletes Kubernetes ingresses (removes ALB)
- Waits for load balancers to be deleted
- Checks for orphaned security groups
- Runs terraform destroy to remove all infrastructure

## Component Details

### Backend (app.py)

The Flask application provides a RESTful API with the following structure:

- **CORS Configuration**: Enabled for all routes to allow frontend communication
- **Data Storage**: JSON file-based storage (`data/users.json`)
- **Error Handling**: Try-catch blocks with appropriate HTTP status codes
- **Response Format**: Consistent JSON structure with success flags

### Frontend Components

**App.js**
- Main application component
- Manages global state (users, loading, error, searchId)
- Handles API calls via axios service
- Implements search and load functionality

**SearchBar.js**
- Controlled input component for user ID search
- Search button and clear functionality
- Displays active search query

**UserList.js**
- Container component for user cards
- Displays user count
- Handles empty states

**UserCard.js**
- Displays individual user information
- Card-based layout with user details

**api.js**
- Axios HTTP client configuration
- API endpoint functions (fetchUsers, fetchUserById, searchUserById)
- Centralized error handling

### Nginx Configuration

The nginx.conf file handles:

**Static File Serving:**
- Serves React build files from `/usr/share/nginx/html`
- React Router support (all routes serve index.html)
- 1-year caching for static assets

**Reverse Proxy:**
- Proxies `/api/*` requests to backend service
- Cross-namespace routing: `iai-backend.backend.svc.cluster.local:5000`
- Timeout configuration (60 seconds)
- Header forwarding (X-Real-IP, X-Forwarded-For, X-Forwarded-Proto)
### Docker Configuration

**Backend Dockerfile:**
- Base image: python:3.11-slim (122MB)
- System dependencies: gcc for C extension compilation
- Application runs as non-root user (UID 1000)
- Gunicorn with 4 workers and 2 threads per worker
- Health check via requests library to /api/health endpoint

**Frontend Dockerfile:**
- Multi-stage build for minimal image size
- Stage 1: Node.js build (npm ci, npm run build)
- Stage 2: Nginx serving (only copies build artifacts)
- Final image: 50MB (vs 500MB with Node.js included)
- Non-root user execution (UID 1000)

### Kubernetes Configuration

**Namespaces:**
- `backend`: Contains backend deployment, service, and configmap
- `frontend`: Contains frontend deployment and service  
- `default`: Contains ingress and proxy services

**Deployments:**
- 2 replicas each for high availability
- Resource limits: 500m CPU, 512Mi memory
- Readiness probe: HTTP GET to health endpoints
- Liveness probe: HTTP GET with longer timeout
- Rolling update strategy (maxSurge: 1, maxUnavailable: 0)

**Services:**
- ClusterIP type for internal communication
- Backend: Port 5000
- Frontend: Port 80
- Proxy services in default namespace for cross-namespace routing

**Ingress:**
- Two ingress resources (backend and frontend namespaces)
- Group annotation: Share single ALB (alb.ingress.kubernetes.io/group.name)
- Path-based routing: /api/* to backend, /* to frontend
- Health check path configured per service
- Target type: IP (for pod direct routing)

### Terraform Modules

**VPC Module:**
- CIDR: 10.0.0.0/16
- 2 public subnets (10.0.0.0/24, 10.0.1.0/24)
- 2 private subnets (10.0.10.0/24, 10.0.11.0/24)
- Internet gateway for public subnets
- 2 NAT gateways with Elastic IPs for private subnets

**EKS Module:**
- Kubernetes version: 1.28
- Managed node group: t3.small instances (2 nodes)
- OIDC provider for IAM role integration
- aws-auth ConfigMap automated configuration
- Security groups for cluster and node communication

**ECR Module:**
- Two repositories: iai-backend, iai-frontend
- Image scanning enabled
- Encryption at rest
- Lifecycle policy: Keep last 3 images

**Load Balancer Module:**
- IAM role for ALB controller with OIDC federation
- IAM policy with required ELB permissions
- Helm chart installation of AWS Load Balancer Controller v1.6.2
- Service account with IAM role annotation

## Monitoring and Health Checks

**Kubernetes Liveness Probes:**
- Backend: GET /api/health every 10 seconds
- Frontend: GET /health every 10 seconds
- Restart pod if 3 consecutive failures

**Kubernetes Readiness Probes:**
- Same endpoints as liveness
- Remove pod from service if unhealthy
- Initial delay: 5 seconds for backend, 10 seconds for frontend

**Docker Health Checks:**
- Backend: Python requests to localhost:5000/api/health
- Frontend: wget spider to localhost:8080/health
- Check interval: 30 seconds
- Timeout: 3 seconds
- Unhealthy threshold: 3 retries

**Application Logs:**
- Backend: Gunicorn access and error logs to stdout/stderr
- Frontend: Nginx access and error logs to stdout/stderr
- View with: `kubectl logs -n <namespace> <pod-name>`

## License

This project is for educational purposes.

## Author

Eyal Chachmishvily