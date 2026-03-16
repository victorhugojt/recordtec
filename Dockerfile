FROM python:3.11-slim

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# Update system packages and fix glibc vulnerabilities
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends libc6 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --upgrade pip wheel setuptools

# Copy dependency files first for better caching
COPY pyproject.toml uv.lock ./

# Install dependencies (includes OpenTelemetry)
RUN uv sync --frozen --no-dev

# Copy application code
COPY src ./src

# Copy entrypoint script
COPY docker-entrypoint.sh ./

# Make entrypoint executable
RUN chmod +x docker-entrypoint.sh

# Expose port
EXPOSE 8000

# Set default environment variables
ENV OTEL_SERVICE_NAME=recordtec \
    OTEL_EXPORTER_OTLP_PROTOCOL=grpc \
    OTEL_TRACES_EXPORTER=otlp \
    OTEL_METRICS_EXPORTER=otlp \
    OTEL_LOGS_EXPORTER=otlp \
    OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED=true

# Use entrypoint to support both with/without OpenTelemetry
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["src/main.py"]