FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/home/appuser \
    PATH=$PATH:/usr/local/bin

WORKDIR /app

# Install OS-level dependencies, Node.js, and build tools
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        gcc python3-dev libssl-dev curl gnupg \
        libnss3 libatk-bridge2.0-0 libatk1.0-0 libcups2 libdrm2 libxcomposite1 \
        libxdamage1 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 libasound2 \
        libxss1 libgconf-2-4 libxrandr2 libasound2 libpangocairo-1.0-0 \
        libatk1.0-0 libcairo-gobject2 libgtk-3-0 libgdk-pixbuf2.0-0 \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip & setuptools
RUN python -m pip install --upgrade pip setuptools>=70.0.0 wheel

# Create a proper non-root user
RUN groupadd -r appgroup && \
    useradd -m -d /home/appuser -s /bin/bash -g appgroup appuser

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright CLI and browsers (as root for system-wide installation)
RUN npm install -g playwright && \
    playwright install --with-deps

# Copy app code and set ownership
COPY . .
RUN chown -R appuser:appgroup /app

# Set up user directories and permissions before switching users
RUN mkdir -p /home/appuser/.cache && \
    chown -R appuser:appgroup /home/appuser/.cache

# Switch to appuser
USER appuser

# Health check with proper curl installation check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health', timeout=5)" || exit 1

# Expose port
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]