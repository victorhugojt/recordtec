# Quick Reference

Essential commands for RecordTec observability setup.

## 🚀 Startup

### Monitoring VM
```bash
cd ~/monitoring
docker compose -f docker-compose.monitoring.yaml up -d
docker logs -f otel-lgtm
```

### Backend VM
```bash
cd ~/recordtec
docker compose up -d
docker compose logs -f recordtec
```

## 🧪 Testing

### API Test
```bash
curl http://localhost:8000/health
curl http://localhost:8000/generes
```

### Generate Load
```bash
BACKEND_IP="10.10.1.4"
for i in {1..50}; do
  curl -s http://$BACKEND_IP:8000/generes > /dev/null && echo "✅ $i"
  sleep 1
done
```

## 📊 Grafana Access

**URL:** `http://MONITORING_VM_EXTERNAL_IP:3000`  
**Login:** admin / admin

### Key Queries

**Requests per minute:**
```promql
sum by (http_route) (
  rate(http_server_duration_milliseconds_count{service_name="recordtec-prod"}[1m]) * 60
)
```

**P95 Latency:**
```promql
histogram_quantile(0.95, 
  rate(http_server_duration_milliseconds_bucket{service_name="recordtec-prod"}[5m])
)
```

**Traces (Tempo):**
```
{service.name="recordtec-prod"}
```

**Logs (Loki):**
```
{service_name="recordtec-prod"}
```

## 🔧 Troubleshooting

### Check OpenTelemetry Status
```bash
docker compose logs recordtec | grep "OpenTelemetry:"
docker compose exec recordtec env | grep OTEL
```

### Test Connectivity
```bash
ping -c 3 10.10.0.3
nc -zv 10.10.0.3 4317
```

### Restart Services
```bash
# Backend
docker compose down && docker compose up -d

# Monitoring
docker compose -f docker-compose.monitoring.yaml restart
```

### View Logs
```bash
# Backend
docker compose logs -f recordtec

# Monitoring
docker logs -f otel-lgtm

# Cloud SQL Proxy
docker compose logs -f cloudsql
```

## 🌐 Get VM IPs

### Monitoring VM
```bash
# Internal
gcloud compute instances describe vm-monitoring \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].networkIP)'

# External
gcloud compute instances describe vm-monitoring \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

### Backend VM
```bash
gcloud compute instances describe vm-backend \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].networkIP)'
```

## 🔄 Update Backend

```bash
# Pull latest image
docker compose pull

# Recreate containers
docker compose down && docker compose up -d
```

## 📝 Configuration Files

- `.env` - Environment variables (backend)
- `docker-compose.yaml` - Backend + Cloud SQL Proxy
- `docker-compose.monitoring.yaml` - Monitoring stack

## ⚠️ Common Issues

**OpenTelemetry shows DISABLED:**
```bash
# Must use .env (not .env.prod)
cp .env.prod .env
docker compose down && docker compose up -d
```

**No data in Grafana:**
1. Check backend logs: `docker compose logs recordtec | grep OTEL`
2. Should show: "OpenTelemetry: ENABLED"
3. Test connectivity: `nc -zv 10.10.0.3 4317`
4. Generate traffic: `curl http://localhost:8000/health`
5. Wait 30-60 seconds for data to appear

**Can't access Grafana:**
1. Check firewall rules allow port 3000
2. Use external IP, not internal
3. Check container is running: `docker ps | grep otel-lgtm`
