# RecordTec - OpenTelemetry Observability Setup

Complete guide for deploying a FastAPI application with OpenTelemetry metrics, traces, and logs to Grafana OTEL-LGTM stack.

## 🏗️ Architecture

```
┌─────────────────────┐         ┌─────────────────────────┐
│  Backend VM         │         │  Monitoring VM          │
│  (10.10.1.4)        │──gRPC──>│  (10.10.0.3)            │
├─────────────────────┤  4317   ├─────────────────────────┤
│ • RecordTec API     │         │ • Grafana (port 3000)   │
│ • Cloud SQL Proxy   │         │ • Tempo (traces)        │
│ • OpenTelemetry     │         │ • Loki (logs)           │
│   Auto-Instrument   │         │ • Mimir (metrics)       │
└─────────────────────┘         └─────────────────────────┘
```

## 📋 Prerequisites

- 2 GCP VMs (backend + monitoring)
- Docker installed on both
- Cloud SQL instance (MySQL)
- GitHub Container Registry access

## 🚀 Quick Setup

### 1. Monitoring VM Setup

```bash
# SSH into monitoring VM
gcloud compute ssh vm-monitoring --zone=us-central1-a

# Create directory
mkdir ~/monitoring
cd ~/monitoring

# Create docker-compose.monitoring.yaml
cat > docker-compose.monitoring.yaml << 'EOF'
services:
  otel-lgtm:
    image: grafana/otel-lgtm:latest
    container_name: otel-lgtm
    ports:
      - "3000:3000"   # Grafana UI
      - "4317:4317"   # OTLP gRPC
      - "4318:4318"   # OTLP HTTP
    volumes:
      - grafana-data:/data/grafana
      - tempo-data:/data/tempo
      - loki-data:/data/loki
      - mimir-data:/data/mimir
    restart: unless-stopped

volumes:
  grafana-data:
  tempo-data:
  loki-data:
  mimir-data:
EOF

# Start monitoring stack
docker compose -f docker-compose.monitoring.yaml up -d

# Check logs
docker logs -f otel-lgtm
```

**Get Monitoring VM IPs:**
```bash
# Internal IP (for backend to send data)
gcloud compute instances describe vm-monitoring \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].networkIP)'
# Output: 10.10.0.3

# External IP (for accessing Grafana)
gcloud compute instances describe vm-monitoring \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
# Output: 35.209.134.148
```

### 2. Backend VM Setup

```bash
# SSH into backend VM
gcloud compute ssh vm-backend --zone=us-central1-a

# Clone repository
git clone https://github.com/victorhugojt/recordtec.git
cd recordtec

# Create .env file (use .env for docker-compose variable substitution)
cat > .env << EOF
# Database Configuration
DB_NAME=recordtec-mysql-db
DB_HOST=cloudsql
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_CONNECTION_TYPE=proxy

# Google Cloud Configuration
GOOGLE_CLOUD_PROJECT=project-2c268745-0c2f-477a-b6a
CLOUDSQL_CONNECTION_NAME=project-2c268745-0c2f-477a-b6a:us-central1:poc-mysql-instance

# OpenTelemetry Configuration
OTEL_ENABLED=true
OTEL_SERVICE_NAME=recordtec-prod
OTEL_EXPORTER_OTLP_ENDPOINT=http://10.10.0.3:4317

# Application Configuration
APP_ENV=production
LOG_LEVEL=info
EOF

# Login to GitHub Container Registry
docker login ghcr.io -u victorhugojt

# Start services
docker compose up -d

# Check logs
docker compose logs -f recordtec
```

**You should see:**
```
🚀 Starting RecordTec API...
📊 OpenTelemetry: ENABLED
   Service Name: recordtec-prod
   Endpoint: http://10.10.0.3:4317
```

### 3. Firewall Rules

```bash
# Allow Grafana access from your IP
gcloud compute firewall-rules create allow-grafana-from-my-ip \
  --network=default \
  --allow=tcp:3000 \
  --source-ranges=YOUR_PUBLIC_IP/32 \
  --target-tags=monitoring-vm

# Allow OTLP from backend to monitoring
gcloud compute firewall-rules create allow-otlp-from-backend \
  --network=default \
  --allow=tcp:4317,tcp:4318 \
  --source-tags=backend-vm \
  --target-tags=monitoring-vm
```

## ✅ Testing

### 1. Test Backend API

```bash
# From backend VM
curl http://localhost:8000/health
curl http://localhost:8000/generes
```

### 2. Generate Load

```bash
# From any VM with access to backend
BACKEND_IP="10.10.1.4"

for i in {1..50}; do
  curl -s http://$BACKEND_IP:8000/generes > /dev/null && echo "✅ $i"
  sleep 1
done
```

### 3. Access Grafana

Open: `http://MONITORING_VM_EXTERNAL_IP:3000`
- **Username:** admin
- **Password:** admin

### 4. View Traces (Tempo)

1. Go to **Explore** → Select **Tempo**
2. Search: `{service.name="recordtec-prod"}`
3. You'll see request traces!

### 5. View Logs (Loki)

1. Go to **Explore** → Select **Loki**
2. Query: `{service_name="recordtec-prod"}`
3. You'll see application logs!

### 6. View Metrics (Mimir)

1. Go to **Explore** → Select **Mimir**
2. Try these queries:

```promql
# Requests per minute
sum by (http_route) (
  rate(http_server_duration_milliseconds_count{service_name="recordtec-prod"}[1m]) * 60
)

# Average latency
rate(http_server_duration_milliseconds_sum{service_name="recordtec-prod"}[5m]) 
/ 
rate(http_server_duration_milliseconds_count{service_name="recordtec-prod"}[5m])

# P95 latency
histogram_quantile(0.95, 
  rate(http_server_duration_milliseconds_bucket{service_name="recordtec-prod"}[5m])
)
```

## 🔧 Troubleshooting

### No Data in Grafana?

**Check backend is sending data:**
```bash
# On backend VM
docker compose logs recordtec | grep -i "otel\|error"

# Should show: "OpenTelemetry: ENABLED"
```

**Check connectivity:**
```bash
# From backend VM
ping -c 3 10.10.0.3
nc -zv 10.10.0.3 4317
```

**Check monitoring stack:**
```bash
# On monitoring VM
docker logs otel-lgtm | tail -50
docker exec otel-lgtm netstat -tuln | grep 4317
```

### OpenTelemetry Shows DISABLED?

**Issue:** Docker Compose isn't reading the `.env` file for variable substitution.

**Solution:**
```bash
# Must use .env (not .env.prod) for variable substitution
cp .env.prod .env

# Recreate containers
docker compose down
docker compose up -d
```

### Environment Variable Not Applied?

**Issue:** `docker compose restart` doesn't re-read environment files.

**Solution:**
```bash
# Always use down + up (not restart)
docker compose down
docker compose up -d
```

## 📊 Key Files

### Docker Setup
- `Dockerfile` - Container image with OpenTelemetry
- `docker-entrypoint.sh` - Conditionally enables OTel
- `docker-compose.yaml` - Backend + Cloud SQL Proxy
- `docker-compose.monitoring.yaml` - Grafana OTEL-LGTM stack

### Configuration
- `.env` - Environment variables (for docker-compose)
- `pyproject.toml` - Python dependencies including OTel libraries

### Application
- `src/main.py` - FastAPI application
- `src/controllers/generes.py` - API endpoints
- `src/services/genere_service.py` - Business logic
- `src/db/` - Database models and repositories

## 🎯 Key Metrics Available

| Metric | Description |
|--------|-------------|
| `http_server_duration_milliseconds_count` | Total HTTP requests |
| `http_server_duration_milliseconds_sum` | Total request duration |
| `http_server_duration_milliseconds_bucket` | Latency distribution |
| `process_runtime_cpython_memory_bytes` | Python memory usage |
| `process_runtime_cpython_cpu_time_seconds` | CPU time |
| `db_client_connections_*` | Database connection metrics |

## 🔐 Security

1. **Change Grafana password:**
```bash
docker exec -it otel-lgtm grafana-cli admin reset-admin-password NewPassword123
```

2. **Restrict Grafana access** to your IP only (firewall rule above)

3. **Keep ports 4317/4318 internal** (only accessible from backend VM)

## 📝 Important Notes

### Why `.env` Instead of `.env.prod`?

Docker Compose reads `.env` by default for variable substitution in `docker-compose.yaml`:

```yaml
environment:
  - OTEL_ENABLED=${OTEL_ENABLED:-false}  # Reads from .env file
  - OTEL_EXPORTER_OTLP_ENDPOINT=${OTEL_EXPORTER_OTLP_ENDPOINT}
```

The `env_file: .env.prod` loads variables **into the container**, but substitution happens **before** that.

### Why `_count` Instead of `_total`?

OpenTelemetry uses histogram metrics that include:
- `_count` suffix = number of requests (this is the counter!)
- `_sum` suffix = total duration
- `_bucket` suffix = latency distribution

One histogram gives you count + duration + percentiles efficiently.

### Automatic Instrumentation

These libraries auto-generate metrics/traces with zero code changes:
- `opentelemetry-instrumentation-fastapi` → HTTP metrics
- `opentelemetry-instrumentation-sqlalchemy` → Database metrics
- `opentelemetry-instrumentation-pymysql` → DB driver metrics

## 🎨 Sample Dashboard Queries

### Request Rate Panel
```promql
sum by (http_route) (
  rate(http_server_duration_milliseconds_count[1m]) * 60
)
```

### Error Rate Panel
```promql
sum by (http_status_code) (
  rate(http_server_duration_milliseconds_count{http_status_code=~"5.."}[5m])
) / sum(rate(http_server_duration_milliseconds_count[5m]))
```

### Latency Panel (P50, P95, P99)
```promql
histogram_quantile(0.50, rate(http_server_duration_milliseconds_bucket[5m]))
histogram_quantile(0.95, rate(http_server_duration_milliseconds_bucket[5m]))
histogram_quantile(0.99, rate(http_server_duration_milliseconds_bucket[5m]))
```

## ✅ Success Checklist

- [ ] Monitoring VM running with Grafana accessible
- [ ] Backend VM sending telemetry (logs show "ENABLED")
- [ ] Traces visible in Tempo
- [ ] Logs visible in Loki
- [ ] Metrics visible in Mimir
- [ ] Dashboard created with key metrics
- [ ] Grafana password changed

---

**Need Help?** Check the troubleshooting section or logs:
```bash
# Backend logs
docker compose logs -f recordtec

# Monitoring logs
docker logs -f otel-lgtm
```
