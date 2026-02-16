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

# Install dependencies
RUN uv sync --frozen --no-dev

# Copy application code
COPY src ./src

# Expose port
EXPOSE 8000

# Run the application
CMD ["uv", "run", "src/main.py"]