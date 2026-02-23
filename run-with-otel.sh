#!/bin/bash
# Run the app with OpenTelemetry automatic instrumentation

echo "🚀 Starting with OpenTelemetry automatic instrumentation..."

export OTEL_METRIC_EXPORT_INTERVAL="5000" # so we don't have to wait 60s for metrics
export OTEL_RESOURCE_ATTRIBUTES="service.name=recordtec,service.instance.id=127.0.0.1:8000"

export OTEL_SERVICE_NAME=recordtec
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_TRACES_EXPORTER=otlp
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED=true


# Run with automatic instrumentation
uv run opentelemetry-instrument \
  --traces_exporter otlp \
  --metrics_exporter otlp \
  --service_name recordtec \
  python src/main.py
