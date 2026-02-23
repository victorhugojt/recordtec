# OpenTelemetry Endpoints Explained

## Quick Answer

When running app + collector on the same VM with Docker Compose:

**YES, you MUST specify the endpoint!**

```yaml
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-lgtm:4317
```

## Why?

### Container Networking

```
Same VM, Different Containers:
┌─────────────────────────────────┐
│  VM                             │
│  ├─ recordtec container         │
│  │  └─ localhost = itself! ❌   │
│  │                              │
│  └─ otel-lgtm container         │
│     └─ listening on 4317        │
└─────────────────────────────────┘
```

Containers have **isolated networks**. To communicate, use **service names**.

## Current Configuration

### Your Script Uses gRPC (Port 4317)

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
# By default, this uses gRPC protocol
```

### Signals Sent to Port 4317 (gRPC)

✅ **Traces** - Request spans, DB queries  
✅ **Metrics** - Request counts, durations  
✅ **Logs** - Application logs (if enabled)  

### Port 4318 (HTTP) Available But Not Used

The collector listens on both:
- **4317** - gRPC (your app uses this)
- **4318** - HTTP (available, not used)

## Protocol Comparison

| Port | Protocol | Default? | Your Setup |
|------|----------|----------|------------|
| 4317 | gRPC | ✅ Yes | ✅ **Using** |
| 4318 | HTTP | ❌ No | ❌ Not using |

## Complete Flow

```
Your App (recordtec container)
  ↓
Automatic instrumentation wraps app
  ↓
Sends via gRPC to: http://otel-lgtm:4317
  ↓
Grafana OTEL-LGTM receives on port 4317
  ↓
Stores signals:
  - Traces → Tempo
  - Metrics → Mimir  
  - Logs → Loki
  ↓
View in Grafana UI (port 3000)
```

## Deployment Scenarios

### Scenario 1: Same VM with Docker Compose (Your Setup)

```yaml
services:
  recordtec:
    environment:
      - OTEL_ENABLED=true
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-lgtm:4317  # ✅ Service name
  
  otel-lgtm:
    ports:
      - "3000:3000"
      - "4317:4317"
```

Access Grafana: `http://VM-EXTERNAL-IP:3000`

### Scenario 2: App on VM, Collector External

```yaml
services:
  recordtec:
    environment:
      - OTEL_ENABLED=true
      - OTEL_EXPORTER_OTLP_ENDPOINT=https://external-collector.com:4317
```

### Scenario 3: Running App Locally (Not in Docker)

```bash
# Collector in Docker
docker run -d -p 4317:4317 grafana/otel-lgtm

# App running directly on host
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317  # ✅ localhost works
./run-with-otel.sh
```

## Default vs Explicit Configuration

### If You DON'T Specify
```python
# Defaults to localhost:4317
OTEL_EXPORTER_OTLP_ENDPOINT not set
  ↓
Tries http://localhost:4317
  ↓
❌ Fails in container (connects to itself)
```

### If You DO Specify (Correct!)
```yaml
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-lgtm:4317
  ↓
Uses Docker network DNS
  ↓
✅ Connects to otel-lgtm container
```

## gRPC vs HTTP - Which Port?

Your current setup uses **gRPC (4317)** by default:

```bash
# gRPC (default, faster)
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-lgtm:4317

# HTTP (if needed, simpler for debugging)
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-lgtm:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
```

**Recommendation:** Stick with gRPC (4317) - it's faster and the default.

## Summary

| Setup | Endpoint Needed? | Value |
|-------|------------------|-------|
| **Docker Compose (your case)** | ✅ YES | `http://otel-lgtm:4317` |
| App + Collector on host | ✅ YES | `http://localhost:4317` |
| App in container, collector on host | ✅ YES | `http://host.docker.internal:4317` |

## Your Production docker-compose.yaml

I've already configured it correctly:

```yaml
recordtec:
  environment:
    - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-lgtm:4317  # ✅ Correct!
  depends_on:
    - otel-lgtm

otel-lgtm:
  ports:
    - "4317:4317"  # Collector listening
```

## To Enable on Your VM

Just add to `.env.prod`:

```bash
OTEL_ENABLED=true
```

Then:

```bash
docker compose pull
docker compose up -d
```

**The endpoint is already configured in the docker-compose.yaml!** ✅

You don't need to change anything - it's already set to use the service name. Just enable it and it will work! 🎯