# DevOps QR Code Generator

A full-stack QR code generator application built with Next.js (frontend), FastAPI (backend), Google Cloud Storage, and Terraform-managed GKE infrastructure.

## Features

- Generate QR codes for any URL
- Stores generated QR codes in Google Cloud Storage
- Frontend built with Next.js, styled with Tailwind CSS
- Backend API built with FastAPI and Python
- Infrastructure as Code with Terraform for GKE, IAM, and networking
- Dockerized for easy deployment

## Project Structure

```
.
├── api/         # FastAPI backend for QR code generation
├── qr-front/    # Next.js frontend
├── Infra/       # Terraform configs for GKE and GCP resources
└── .github/     # CI/CD workflows
```

## Getting Started

### Prerequisites

- Docker
- Node.js (for local frontend dev)
- Python 3.10+ (for local backend dev)
- Google Cloud account (for production)
- Terraform

### Local Development

#### 1. Backend (API)

Ensure gcloud CLI is installed with reachable ADC.

```sh
cd api
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

#### 2. Frontend

```sh
cd qr-front
npm install
npm run dev
```

Visit [http://localhost:3000](http://localhost:3000).

#### 3. Docker Compose (optional)

You can build and run both services using Docker:

```sh
docker build -t qr-back ./api
docker build -t qr-front ./qr-front
docker run -p 8000:80 qr-back
docker run -p 3000:3000 qr-front
```

### Infrastructure

Terraform scripts in `Infra/` provision a GKE cluster, networking, and IAM for the app.

```sh
cd Infra
terraform init
terraform plan
terraform apply
```

### Deployment

CI/CD is configured in `.github/workflows/ci.yml` to build and push Docker images on every push to `main`.
