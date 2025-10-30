# IAI Project - User Management System

A full-stack web application with a **Python Flask** backend and **React** frontend for managing and searching users. Fully containerized and deployable to AWS EKS with automated CI/CD.

## 📋 Table of Contents
- [Project Structure](#project-structure)
- [Features](#features)
- [Quick Start](#quick-start)
- [Deployment](#deployment)
- [API Documentation](#api-documentation)
- [Technologies Used](#technologies-used)

## Project Structure

```
IAI Project/
├── backend/              # Flask API server
│   ├── app.py           # Main Flask application
│   ├── Dockerfile       # Backend container
│   ├── requirements.txt
│   └── data/
│       └── users.json   # Sample users data
├── frontend/            # React application
│   ├── Dockerfile       # Frontend container
│   ├── nginx.conf       # Nginx configuration
│   ├── src/
│   │   ├── components/  # React components
│   │   ├── services/    # API service
│   │   └── App.js
│   └── package.json
├── k8s/                 # Kubernetes manifests
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── ingress.yaml
│   └── configmap.yaml
├── .github/workflows/   # CI/CD pipeline
│   └── deploy-eks.yml
├── docker-compose.yml   # Local development
├── deploy-to-ecr.sh     # ECR deployment script
└── deploy-to-eks.sh     # EKS deployment script
```

## Features

### Backend (Flask)
- ✅ RESTful API with CORS support
- ✅ User management endpoints (list, get by ID, search)
- ✅ Production-ready with Gunicorn
- ✅ Health check endpoint
- ✅ Docker containerized
- ✅ Non-root security

### Frontend (React)
- ✅ Modern card-based user interface
- ✅ Real-time search and filtering by ID
- ✅ Responsive design (mobile, tablet, desktop)
- ✅ Nginx reverse proxy to backend
- ✅ Docker multi-stage build
- ✅ Optimized static assets

### DevOps & Infrastructure
- ✅ Docker Compose for local development
- ✅ Production-optimized Dockerfiles
- ✅ AWS ECR image storage with lifecycle policies
- ✅ Kubernetes deployment manifests
- ✅ AWS EKS deployment scripts
- ✅ GitHub Actions CI/CD pipeline
- ✅ Automated testing and deployment

## Quick Start

### Option 1: Docker Compose (Recommended for Local Development)

```bash
# Start both services
docker-compose up -d

# Access the application
# Frontend: http://localhost:8080
# Backend API: http://localhost:5000/api/users

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Option 2: Manual Setup

**Backend:**
```bash
cd backend
pip install -r requirements.txt
python app.py
```

**Frontend:**
```bash
## Deployment

### 🚀 Deploy to AWS

#### 1. Deploy Images to ECR
```bash
chmod +x deploy-to-ecr.sh
./deploy-to-ecr.sh
```

Features:
- ✅ Free tier protection (500 MB limit monitoring)
- ✅ Automatic lifecycle policy (keeps last 3 images)
- ✅ Image scanning enabled
- ✅ Encrypted storage

#### 2. Deploy to EKS
```bash
chmod +x deploy-to-eks.sh
./deploy-to-eks.sh
```

#### 3. Automated CI/CD with GitHub Actions

Push to `main` branch automatically:
1. Builds Docker images
2. Pushes to AWS ECR
3. Deploys to EKS cluster
4. Verifies deployment

**Setup Required:**
1. Create EKS cluster
2. Add GitHub secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. Push to `main` branch

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions.

## API Documentation

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users` | Get all users |
| GET | `/api/users/<id>` | Get a specific user by ID |
| GET | `/api/users/search/<id>` | Search users by ID (partial match) |
| GET | `/api/health` | Health check endpoint |

### Example Response

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john.doe@example.com",
      "phone": "+1-555-0101",
      "role": "Developer"
    }
  ],
  "count": 1
}
```

## Technologies Used

### Backend
- Python 3.11
- Flask - Web framework
- Flask-CORS - Cross-origin resource sharing
- Gunicorn - WSGI server

### Frontend
- React 17 - UI library
- Axios - HTTP client
- Nginx - Web server
- CSS3 - Styling

### DevOps & Infrastructure
- Docker & Docker Compose
- AWS ECR - Container registry
- AWS EKS - Kubernetes service
- GitHub Actions - CI/CD
- Kubernetes - Container orchestration

## Architecture

```
┌─────────────┐
│   GitHub    │
│   Actions   │ Push to main → Build → Push to ECR → Deploy to EKS
└──────┬──────┘
       │
┌──────▼──────────────────────────────────────────┐
│             AWS Cloud                            │
│                                                  │
│  ┌────────────────────────────────────────┐   │
│  │          EKS Cluster                   │   │
│  │                                        │   │
│  │  ┌──────────┐      ┌──────────┐      │   │
│  │  │ Frontend │──API─▶│ Backend  │      │   │
│  │  │  React   │      │  Flask   │      │   │
│  │  │  Nginx   │      │ Gunicorn │      │   │
│  │  └────┬─────┘      └──────────┘      │   │
│  │       │                               │   │
│  └───────┼───────────────────────────────┘   │
│          │                                    │
│   ┌──────▼──────┐                           │
│   │ Load        │                           │
│   │ Balancer    │                           │
│   └──────┬──────┘                           │
│          │                                    │
└──────────┼────────────────────────────────────┘
           │
      ┌────▼────┐
      │  Users  │
      └─────────┘
```

## Development

### Adding New Users

Edit `backend/data/users.json` to add or modify users.

### Modifying the API

Edit `backend/app.py` to add new endpoints or modify existing ones.

### Customizing the UI

- Component files are in `frontend/src/components/`
- Styling files are in `frontend/src/components/*.css`

## Troubleshooting

### Backend not connecting
- Make sure Flask is running on port 5000
- Check for any Python dependency errors

### Frontend API errors
- Verify the backend is running
- Check the API URL in `frontend/src/services/api.js`
- Ensure CORS is properly configured

### Port conflicts
- Backend: Change port in `backend/app.py`
- Frontend: Set `PORT=3001` in environment or `.env` file

### Docker issues
- Ensure Docker is running
- Check Docker logs: `docker-compose logs -f`
- Rebuild images: `docker-compose up --build`

## Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Detailed deployment guide with GitHub Actions setup
- [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md) - Docker and container documentation
- [k8s/README.md](k8s/README.md) - Kubernetes configuration guide

## License

This project is for educational purposes (IAI Project).

## Author

Created for IAI Project requirements.
