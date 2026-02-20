# Deployment Guide

## Overview

This guide covers deploying the recordtec application locally and on GCP VM without needing service account keys.

## Architecture

### Local Development
```
Your App → Cloud SQL Public IP (with SSL)
```

### GCP VM Production
```
Your App → Cloud SQL Proxy → Cloud SQL
           (uses VM service account - NO KEYS NEEDED!)
```

## Local Development

### Prerequisites
- Docker installed
- GCP Cloud SQL instance with public IP
- Your IP whitelisted in Cloud SQL authorized networks

### Setup

1. **Use local configuration:**
   ```bash
   cp .env.example .env
   ```

2. **Update `.env` with your values:**
   ```bash
   DB_HOST=34.58.206.128        # Your Cloud SQL public IP
   DB_CONNECTION_TYPE=direct
   DB_NAME=recordtec-mysql-db
   DB_USER=root
   DB_PASSWORD=your_password
   ```

3. **Run locally:**
   ```bash
   # Build and run (with hot reload)
   docker compose -f docker-compose.local.yaml up -d
   
   # Or run without Docker
   uv run src/main.py
   ```

4. **Test:**
   ```bash
   curl http://localhost:8000/health
   curl http://localhost:8000/generes
   ```

## GCP VM Deployment (Production)

### Prerequisites
- GCP Compute Engine VM
- VM has Cloud SQL Client role attached
- Docker and Docker Compose installed on VM

### Why No Service Account Keys?

**GCP VMs have built-in authentication!**
- Every VM has an attached service account
- Cloud SQL Proxy uses the VM's metadata service
- No manual authentication needed
- More secure than keys

### Setup on GCP VM

1. **SSH into your VM:**
   ```bash
   gcloud compute ssh your-vm-name --zone=us-central1-a
   ```

2. **Install Docker (if not installed):**
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   
   # Install Docker Compose
   sudo apt-get update
   sudo apt-get install docker-compose-plugin
   ```

3. **Clone your repository:**
   ```bash
   git clone https://github.com/victorhugojt/recordtec.git
   cd recordtec
   ```

4. **Setup environment:**
   ```bash
   cp .env.prod .env
   # Edit if needed, but defaults should work
   ```

5. **Login to GitHub Container Registry:**
   ```bash
   # Create a GitHub Personal Access Token (PAT) with read:packages scope
   # Then login:
   docker login ghcr.io -u victorhugojt
   # Enter your PAT when prompted
   ```

6. **Start the application:**
   ```bash
   docker compose pull
   docker compose up -d
   ```

7. **Verify it's running:**
   ```bash
   docker compose ps
   docker compose logs -f
   curl http://localhost:8000/health
   ```

### VM Service Account Permissions

Your VM needs these IAM roles:
```bash
# Add Cloud SQL Client role to VM service account
gcloud projects add-iam-policy-binding project-2c268745-0c2f-477a-b6a \
  --member="serviceAccount:VM-SERVICE-ACCOUNT@project-2c268745-0c2f-477a-b6a.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"
```

Or via Console:
1. Go to IAM & Admin → Service Accounts
2. Find your VM's service account
3. Add role: **Cloud SQL Client**

## Configuration Files

### For Local Development
- Use: `docker-compose.local.yaml`
- Env: `.env` (with public IP)
- Connection: Direct to public IP

### For GCP VM Production
- Use: `docker-compose.yaml` (default)
- Env: `.env.prod`
- Connection: Cloud SQL Proxy

## Quick Commands

### Local
```bash
# Start
docker compose -f docker-compose.local.yaml up -d

# Stop
docker compose -f docker-compose.local.yaml down
```

### GCP VM
```bash
# Start
docker compose up -d

# Stop
docker compose down

# Update to latest image
docker compose pull
docker compose up -d
```

## Troubleshooting

### Cloud SQL Proxy Connection Issues on VM

**Check VM service account:**
```bash
# On the VM
curl -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email
```

**Check proxy logs:**
```bash
docker compose logs cloudsql
```

**Common issues:**
- VM service account doesn't have Cloud SQL Client role
- Cloud SQL instance connection name is incorrect
- Firewall blocking internal connections

### Local Connection Issues

**Check public IP access:**
```bash
# Test connectivity
telnet 34.58.206.128 3306

# Or with mysql client
mysql -h 34.58.206.128 -u root -p
```

**Common issues:**
- Your IP not whitelisted in Cloud SQL authorized networks
- Firewall blocking port 3306
- Incorrect credentials

## Security Notes

✅ **No service account keys stored** - Uses Application Default Credentials  
✅ **VM authenticates automatically** - Via metadata service  
✅ **Production uses proxy** - More secure than public IP  
✅ **SSL enforced** - For direct connections  

## Cost Optimization

- **Local**: Direct connection (no proxy cost)
- **GCP VM**: Cloud SQL Proxy (minimal cost, included in free tier)

---
**Last Updated**: 2026-02-19
