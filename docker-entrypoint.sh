#!/bin/bash
set -e

echo "🚀 Starting RecordTec API..."

# Check if OpenTelemetry should be enabled
if [ "${OTEL_ENABLED:-false}" = "true" ]; then
    echo "📊 OpenTelemetry: ENABLED"
    echo "   Service Name: ${OTEL_SERVICE_NAME}"
    echo "   Endpoint: ${OTEL_EXPORTER_OTLP_ENDPOINT}"
    echo "   Protocol: ${OTEL_EXPORTER_OTLP_PROTOCOL:-grpc}"
    
    # Run with OpenTelemetry automatic instrumentation
    exec uv run opentelemetry-instrument \
        --traces_exporter "${OTEL_TRACES_EXPORTER}" \
        --metrics_exporter "${OTEL_METRICS_EXPORTER}" \
        --service_name "${OTEL_SERVICE_NAME}" \
        python "$@"
else
    echo "📊 OpenTelemetry: DISABLED"
    # Run normally without instrumentation
    exec uv run python "$@"
fi
