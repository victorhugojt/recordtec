# OpenTelemetry Setup - Docker Image

## What Changed in the Dockerfile

The new Dockerfile includes:

1. ✅ **OpenTelemetry dependencies** - Pre-installed in the image
2. ✅ **Smart entrypoint** - Enables/disables OTel via environment variable
3. ✅ **Backward compatible** - Works without OTel by default

## How It Works

The `docker-entrypoint.sh` checks the `OTEL_ENABLED` environment variable:

- `OTEL_ENABLED=false` (default) → Runs normally
- `OTEL_ENABLED=true` → Runs with automatic instrumentation

## Build and Push New Image

```bash
# Commit changes
git add Dockerfile docker-entrypoint.sh pyproject.toml uv.lock
git commit -m "Add OpenTelemetry support to Docker image"
git push

# Wait for GitHub Actions to build (~2-3 minutes)
# Image will be: ghcr.io/victorhugojt/recordtec:cloud-sql-connection
```

## Usage Scenarios

### Scenario 1: Production WITHOUT OpenTelemetry (Default)

```yaml
# docker-compose.yaml
services:
  recordtec:
    image: ghcr.io/victorhugojt/recordtec:cloud-sql-connection
    environment:
      - OTEL_ENABLED=false  # or omit entirely
```

Runs normally, no overhead.

### Scenario 2: Production WITH OpenTelemetry + Grafana

```yaml
services:
  recordtec:
    image: ghcr.io/victorhugojt/recordtec:cloud-sql-connection
    environment:
      - OTEL_ENABLED=true
      - OTEL_SERVICE_NAME=recordtec
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-lgtm:4317
    depends_on:
      - otel-lgtm

  otel-lgtm:
    image: grafana/otel-lgtm:latest
    ports:
      - "3000:3000"   # Grafana UI
      - "4317:4317"   # OTLP gRPC
```

### Scenario 3: Production WITH External Observability Platform

```yaml
services:
  recordtec:
    image: ghcr.io/victorhugojt/recordtec:cloud-sql-connection
    environment:
      - OTEL_ENABLED=true
      - OTEL_SERVICE_NAME=recordtec-prod
      - OTEL_EXPORTER_OTLP_ENDPOINT=https://your-collector.example.com:4317
      - OTEL_EXPORTER_OTLP_HEADERS=x-api-key=your-api-key
```

For platforms like:
- Grafana Cloud
- Datadog
- New Relic
- Honeycomb
- Elastic APM

## Local Testing with Grafana

```bash
# Test with local build
docker compose -f docker-compose.grafana.yaml up -d

# View traces
open http://localhost:3000
```

## GCP VM Deployment

After the image is built and pushed:

```bash
# On VM, pull latest image
docker compose pull

# Without OpenTelemetry (default)
docker compose up -d

# OR with OpenTelemetry
OTEL_ENABLED=true docker compose up -d
```

## Environment Variables Reference

### Required (when OTEL_ENABLED=true)
- `OTEL_ENABLED` - Set to `true` to enable
- `OTEL_EXPORTER_OTLP_ENDPOINT` - Collector endpoint

### Optional
- `OTEL_SERVICE_NAME` - Service identifier (default: recordtec)
- `OTEL_EXPORTER_OTLP_PROTOCOL` - `grpc` or `http/protobuf` (default: grpc)
- `OTEL_TRACES_EXPORTER` - Trace exporter type (default: otlp)
- `OTEL_METRICS_EXPORTER` - Metrics exporter type (default: otlp)
- `OTEL_LOGS_EXPORTER` - Logs exporter type (default: otlp)
- `OTEL_RESOURCE_ATTRIBUTES` - Extra attributes (e.g., service.version=1.0.0)

## Signals Sent

When `OTEL_ENABLED=true`, the image sends to **port 4317 (gRPC)** by default:

- ✅ **Traces** - HTTP requests, DB queries, spans
- ✅ **Metrics** - Request counts, durations, errors
- ✅ **Logs** - Application logs (if enabled)

Port 4318 (HTTP) is available if you set:
```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-lgtm:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
```

## What Gets Instrumented Automatically

- FastAPI routes
- SQLAlchemy queries
- PyMySQL connections
- HTTP clients
- Logging
- Asyncio
- Threading

## Performance Impact

- **OTel Disabled**: 0% overhead
- **OTel Enabled**: ~1-3% overhead (negligible)

## Example: Deploy with Grafana on GCP VM

Create `docker-compose.prod-otel.yaml` on your VM:

```yaml
services:
  recordtec:
    image: ghcr.io/victorhugojt/recordtec:cloud-sql-connection
    environment:
      - OTEL_ENABLED=true
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-lgtm:4317
    depends_on:
      - cloudsql
      - otel-lgtm

  cloudsql:
    image: gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.13.0
    # ... your cloudsql config

  otel-lgtm:
    image: grafana/otel-lgtm:latest
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  grafana-data:
```

## Quick Reference

| Use Case | OTEL_ENABLED | Image Includes OTel? |
|----------|--------------|---------------------|
| Production (basic) | false | ✅ Yes (but not running) |
| Production (with monitoring) | true | ✅ Yes (running) |
| Local dev | false | ✅ Yes (but not running) |
| Local testing OTel | true | ✅ Yes (running) |

## Next Steps

1. **Push code** - Let GitHub Actions build the new image
2. **Test locally** - `./test-grafana.sh`
3. **Deploy to VM** - Pull new image with `docker compose pull`

---
**Last Updated**: 2026-02-20
