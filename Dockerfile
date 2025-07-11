FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install OS-level dependencies, Node.js, and build tools
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        gcc python3-dev libssl-dev curl gnupg \
        libnss3 libatk-bridge2.0-0 libatk1.0-0 libcups2 libdrm2 libxcomposite1 \
        libxdamage1 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 libasound2 \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip & setuptools
RUN python -m pip install --upgrade pip setuptools>=70.0.0 wheel

# Create non-root user properly
RUN groupadd -r appgroup && \
    useradd -m -d /home/appuser -s /bin/bash -g appgroup appuser

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright CLI (as root)
RUN npm install -g playwright

# Copy app code
COPY . .
RUN chown -R appuser:appgroup /app

# Switch to appuser
USER appuser

# Install Playwright browsers *as appuser*
RUN playwright install --with-deps

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD
