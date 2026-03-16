# RecordTec API

FastAPI application for music genre management with OpenTelemetry observability.

## 🚀 Quick Start

See **[OBSERVABILITY-SETUP.md](./OBSERVABILITY-SETUP.md)** for complete setup guide.

## 📚 What's Inside

- **FastAPI** REST API
- **SQLAlchemy** ORM with MySQL
- **OpenTelemetry** automatic instrumentation
- **Docker** containerization
- **Grafana OTEL-LGTM** stack for observability

## 🏗️ Architecture

- **Backend VM**: FastAPI app + Cloud SQL Proxy
- **Monitoring VM**: Grafana + Tempo + Loki + Mimir

## 🔗 Documentation

- **[OBSERVABILITY-SETUP.md](./OBSERVABILITY-SETUP.md)** - Main setup guide (START HERE!)
- **[SECURITY.md](./SECURITY.md)** - Security policy and vulnerability management

## 🧪 Local Development

```bash
# Install dependencies
uv sync

# Run tests
uv run pytest

# Run locally
uv run python src/main.py
```

## 📊 Observability

Automatic instrumentation provides:
- **Traces** - Request flow and timing
- **Logs** - Application logs with context
- **Metrics** - HTTP requests, latency, database connections

All sent to Grafana OTEL-LGTM stack via OTLP protocol (gRPC port 4317).

## 🐳 Docker

```bash
# Build
docker build -t recordtec:local .

# Run
docker run -p 8000:8000 --env-file .env recordtec:local

# Test
curl http://localhost:8000/health
```

## 📝 API Endpoints

- `GET /health` - Health check
- `GET /generes` - List music genres

## 🔐 Security

See [SECURITY.md](./SECURITY.md) for vulnerability reporting and management.

## 📄 License

MIT
