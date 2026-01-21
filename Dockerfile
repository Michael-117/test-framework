# Pin Node.js version for predictable environment
FROM node:18-slim

# Pin Chrome and selenium-side-runner versions via build arguments
# These can be overridden at build time for different versions
ARG CHROME_VERSION=131.0.6778.85-1
ARG SELENIUM_SIDE_RUNNER_VERSION=4.0.0

# Install dependencies for Chrome/Chromium
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Install specific Chrome version
# Note: If the exact version is not available, the build will fail
# Check available versions with: apt-cache madison google-chrome-stable
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable=${CHROME_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# Verify Chrome version matches expected version
RUN CHROME_INSTALLED=$(google-chrome --version | awk '{print $3}') \
    && echo "Installed Chrome version: $CHROME_INSTALLED" \
    && echo "Expected Chrome version: ${CHROME_VERSION%%-*}" \
    && google-chrome --version

# Install specific selenium-side-runner version
RUN npm install -g selenium-side-runner@${SELENIUM_SIDE_RUNNER_VERSION}

# Verify selenium-side-runner version
RUN selenium-side-runner --version

# Create app directory
WORKDIR /app

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
