# Stage 1: Build stage #
FROM python:3.12-slim AS base

WORKDIR /app

# Install only the necessary dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install dependencies
RUN pip install --no-cache-dir flask


# Stage 2: Final stage #
FROM python:3.12-slim

WORKDIR /app

# Install only the runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy only necessary files from build stage
COPY --from=base /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=base /app /app

# Expose the application port
EXPOSE 3000

# Run the app
CMD ["python", "app.py"]
