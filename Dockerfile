FROM node:18-slim

# Install dependencies for Chrome/Chromium (if needed for any tools)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install selenium-side-runner globally
RUN npm install -g selenium-side-runner

# Set working directory
WORKDIR /app

# Create directory for .side files
RUN mkdir -p /app/side

# Default entrypoint
ENTRYPOINT ["selenium-side-runner"]
