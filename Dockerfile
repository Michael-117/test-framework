# Use Selenium Node Chrome image which includes Chrome and ChromeDriver pre-installed
# Pin the image version for predictable Chrome/ChromeDriver versions
# Check available versions at: https://hub.docker.com/r/selenium/node-chrome/tags
ARG SELENIUM_NODE_CHROME_VERSION=4.27.0-20241218
FROM selenium/node-chrome:${SELENIUM_NODE_CHROME_VERSION}

# Switch to root to install Node.js and selenium-side-runner
USER root

# Install Node.js 18 (selenium/node-chrome doesn't include Node.js)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Pin selenium-side-runner version via build argument
ARG SELENIUM_SIDE_RUNNER_VERSION=4.0.0

# Install specific selenium-side-runner version
RUN npm install -g selenium-side-runner@${SELENIUM_SIDE_RUNNER_VERSION}

# Verify versions
RUN echo "Chrome version:" && google-chrome --version \
    && echo "ChromeDriver version:" && chromedriver --version \
    && echo "Node.js version:" && node --version \
    && echo "selenium-side-runner version:" && selenium-side-runner --version

# Create app directory
WORKDIR /app

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Note: Running as root is fine for selenium-side-runner
# The selenium/node-chrome image runs as 'selenium' user by default,
# but we need root to install Node.js and npm packages
# selenium-side-runner will work correctly as root

# Set the entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
