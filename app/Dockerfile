# Stage 1: Builder
FROM python:3.12-slim AS builder

WORKDIR /app

# Install Python dependencies only

RUN pip install --no-cache-dir flask prometheus_flask_exporter

# Copy the entire app directory (as in your original Dockerfile)
COPY . .

# Stage 2: Runtime
FROM python:3.12-slim

WORKDIR /app

# Install runtime OS dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages

# Copy the entire app directory from builder stage
COPY --from=builder /app /app

# Clean up Python cache
RUN find /usr/local/lib/python3.12/ -name '__pycache__' -exec rm -r {} + || true && \
    find /usr/local/lib/python3.12/ -name '*.pyc' -delete || true

EXPOSE 3000

CMD ["python", "app.py"]