# Containerized Selenium Side Runner Testing Platform

A Docker-based end-to-end testing platform using `selenium-side-runner` to execute Selenium IDE test files (.side) against locally hosted applications.

## Overview

This platform provides a containerized environment for running Selenium IDE test suites. It automatically discovers and executes all `.side` files in a specified directory, making it ideal for CI/CD pipelines or local testing workflows.

## Features

- 🐳 Fully containerized with Docker
- 🔍 Automatic discovery of all `.side` files in a directory
- 🌐 Network access to locally hosted applications
- 📊 Test execution summary with pass/fail counts
- ⚙️ Configurable via environment variables
- 🔒 Version-pinned dependencies for predictable test environments

## Prerequisites

- Docker and Docker Compose installed
- Selenium IDE test files (.side format)
- A locally hosted application to test (or accessible via network)

## Quick Start

### 1. Build the Docker Image

```bash
docker build -t selenium-test-runner .
```

Or build with specific versions:

```bash
docker build \
  --build-arg SELENIUM_NODE_CHROME_VERSION=4.27.0-20241218 \
  --build-arg SELENIUM_SIDE_RUNNER_VERSION=4.0.0 \
  -t selenium-test-runner .
```

Or using Docker Compose:

```bash
docker-compose build
```

### 2. Prepare Your Test Files

Create a directory containing your `.side` files:

```bash
mkdir tests
# Copy your .side files to the tests directory
cp /path/to/your/tests/*.side tests/
```

### 3. Run Tests

#### Option A: Using Docker Run

```bash
docker run --rm \
  --shm-size=2g \
  -e TEST_PATH=/tests \
  -v "$(pwd)/tests:/tests:ro" \
  --network host \
  selenium-test-runner
```

#### Option B: Using Docker Compose

1. Create a `.env` file (or copy from `.env.example`):

```bash
cp .env.example .env
```

2. Edit `.env` and set your `TEST_PATH` and optionally `BASE_URL`:

```env
TEST_PATH=./tests
BASE_URL=http://localhost:3000
```

3. Run the tests:

```bash
docker-compose up
```

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `TEST_PATH` | Path to directory containing .side files | `/tests` | Yes |
| `BASE_URL` | Base URL of the application being tested (e.g., `http://localhost:3000`) | None | No |

### Application URL Configuration

The hostname and port of your application can be configured in two ways:

#### Option 1: Using BASE_URL Environment Variable (Recommended)

Set the `BASE_URL` environment variable to override the base URL for all tests:

```bash
# Using Docker Run
docker run --rm \
  -e TEST_PATH=/tests \
  -e BASE_URL=http://localhost:3000 \
  -v "$(pwd)/tests:/tests:ro" \
  --network host \
  selenium-test-runner
```

```bash
# Using Docker Compose (.env file)
TEST_PATH=./tests
BASE_URL=http://localhost:3000
```

#### Option 2: Defined in .side Files

The base URL can also be defined directly in your Selenium IDE test files (.side). When you create tests in Selenium IDE, you specify the base URL. This URL will be used unless overridden by the `BASE_URL` environment variable.

**Note**: If `BASE_URL` is set, it will override any base URL defined in the .side files.

### Network Configuration

The platform uses `host` network mode by default to access applications running on `localhost`. This allows you to test applications running on your local machine.

#### Testing Local Applications

If your application runs on `localhost:3000`, the container can access it directly when using `network_mode: host`.

#### Testing Applications in Other Containers

If your application runs in another Docker container:

1. **Option 1**: Use Docker Compose with a shared network:

```yaml
version: '3.8'

services:
  selenium-tests:
    # ... existing config ...
    networks:
      - test-network
  
  your-app:
    # ... your app config ...
    networks:
      - test-network

networks:
  test-network:
    driver: bridge
```

2. **Option 2**: Use `extra_hosts` to access host machine:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

Then access your app via `http://host.docker.internal:PORT`.

## Directory Structure

```
optimum-test-framework/
├── Dockerfile              # Container definition
├── docker-compose.yml      # Docker Compose configuration
├── entrypoint.sh          # Test execution script
├── .dockerignore          # Files to exclude from build
├── .env.example           # Example environment variables
├── README.md              # This file
└── tests/                 # Your .side test files (create this)
    ├── login-test.side
    ├── checkout-test.side
    └── ...
```

## How It Works

1. **Container Build**: The Dockerfile sets up Node.js, Chrome browser, and selenium-side-runner
2. **Test Discovery**: The entrypoint script scans `TEST_PATH` for all `.side` files
3. **Test Execution**: Each `.side` file is executed sequentially using selenium-side-runner
4. **Results**: A summary is displayed showing passed/failed test counts

## Example Usage

### Basic Test Run

```bash
# Set your test directory
export TEST_PATH=/path/to/my/tests

# Run tests
docker run --rm \
  --shm-size=2g \
  -e TEST_PATH=$TEST_PATH \
  -e BASE_URL=http://localhost:3000 \
  -v "$TEST_PATH:$TEST_PATH:ro" \
  --network host \
  selenium-test-runner
```

### With Docker Compose

```bash
# Edit .env file
echo "TEST_PATH=./my-tests" > .env

# Run tests
docker-compose up
```

### CI/CD Integration

```yaml
# Example GitHub Actions workflow
name: E2E Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build test image
        run: docker build -t selenium-test-runner .
      
      - name: Run tests
        run: |
          docker run --rm \
            --shm-size=2g \
            -e TEST_PATH=/tests \
            -v ${{ github.workspace }}/tests:/tests:ro \
            --network host \
            selenium-test-runner
```

## Troubleshooting

### Tests Can't Connect to Local Application

**Problem**: Container can't reach your localhost application.

**Solutions**:
- Ensure `network_mode: host` is set in docker-compose.yml
- Verify your application is running and accessible
- Check firewall settings
- Try using `host.docker.internal` instead of `localhost` in your test files

### No .side Files Found

**Problem**: Script reports no .side files found.

**Solutions**:
- Verify `TEST_PATH` is correctly set
- Check that the directory is mounted correctly (`-v` flag)
- Ensure files have `.side` extension
- Check file permissions

### Chrome/Chromium Issues

**Problem**: Chrome fails to start in container.

**Solutions**:
- Ensure all required dependencies are installed (handled in Dockerfile)
- Check if running in headless mode is needed (selenium-side-runner handles this)
- Verify sufficient memory allocation for Docker

### Permission Denied

**Problem**: Entrypoint script can't execute.

**Solutions**:
- Ensure `entrypoint.sh` has execute permissions (handled in Dockerfile)
- Check Docker volume mount permissions

### Chrome Version Not Available

**Problem**: Docker build fails with image version issues.

**Solutions**:
- Check available Selenium Node Chrome image versions at [Docker Hub](https://hub.docker.com/r/selenium/node-chrome/tags)
- Each Selenium image version includes a specific Chrome and ChromeDriver version
- Use a valid image tag version in the `SELENIUM_NODE_CHROME_VERSION` build argument

## Version Pinning & Predictable Environments

### Why Version Pinning Matters

To ensure consistent and reproducible test results, all dependencies are pinned to specific versions:

- **Chrome & ChromeDriver**: Pinned via `selenium/node-chrome` image version (default: `4.27.0-20241218`)
- **Node.js**: Pinned to version 18 (installed on top of Selenium image)
- **selenium-side-runner**: Pinned to a specific version (default: `4.0.0`)

### Using Pre-built Images

This Dockerfile uses the official `selenium/node-chrome` image as a base, which includes:
- ✅ Chrome browser pre-installed
- ✅ ChromeDriver pre-installed and matched to Chrome version
- ✅ All required dependencies and libraries
- ✅ Version-pinned via image tag

**Benefits:**
- Faster builds (no Chrome download/installation)
- More reliable (Chrome and ChromeDriver versions are guaranteed to match)
- Less maintenance (Selenium team manages Chrome compatibility)

### Customizing Versions

You can override versions at build time using build arguments:

```bash
docker build \
  --build-arg SELENIUM_NODE_CHROME_VERSION=4.27.0-20241218 \
  --build-arg SELENIUM_SIDE_RUNNER_VERSION=4.0.0 \
  -t selenium-test-runner .
```

### Finding Available Versions

- **Selenium Node Chrome images**: Check [Docker Hub tags](https://hub.docker.com/r/selenium/node-chrome/tags)
  - Each tag includes specific Chrome and ChromeDriver versions
  - Format: `MAJOR.MINOR.PATCH-DATE` (e.g., `4.27.0-20241218`)
  - Check release notes for Chrome/ChromeDriver versions included

- **selenium-side-runner versions**: Check [npm registry](https://www.npmjs.com/package/selenium-side-runner?activeTab=versions)

### Ensuring Consistent Test Environments

1. **Use the same image tag**: Always use the same Docker image tag in your CI/CD pipeline
2. **Pin versions explicitly**: Use build arguments to pin versions when building
3. **Document versions**: Keep track of which versions work with your tests
4. **Test version upgrades**: When updating versions, test thoroughly before deploying
5. **Tag your images**: Build once and tag with a version number

**Best Practice**: Build your image once with specific versions, tag it with a version (e.g., `selenium-test-runner:v1.0.0`), and reuse that exact image for all test runs:

```bash
# Build with specific versions
docker build \
  --build-arg SELENIUM_NODE_CHROME_VERSION=4.27.0-20241218 \
  --build-arg SELENIUM_SIDE_RUNNER_VERSION=4.0.0 \
  -t selenium-test-runner:v1.0.0 \
  -t selenium-test-runner:latest .

# Use the tagged version in your CI/CD
docker run --rm --shm-size=2g selenium-test-runner:v1.0.0
```

**Note**: The `--shm-size=2g` flag is required when using `docker run` directly (it's already configured in docker-compose.yml). This prevents Chrome from crashing due to insufficient shared memory.

This ensures that every test run uses the exact same browser version and selenium-side-runner version, eliminating environment-related test failures.

## Advanced Configuration

### Custom Selenium Side Runner Options

You can modify `entrypoint.sh` to pass additional options to selenium-side-runner:

```bash
selenium-side-runner --server http://selenium-hub:4444 "$side_file"
```

### Parallel Execution

For parallel test execution, you can modify the entrypoint script to use background processes or use multiple containers with different test subsets.

### Test Reports

To generate test reports, you can mount a volume for output:

```bash
docker run --rm \
  --shm-size=2g \
  -e TEST_PATH=/tests \
  -v "$(pwd)/tests:/tests:ro" \
  -v "$(pwd)/reports:/reports" \
  --network host \
  selenium-test-runner
```

Then modify `entrypoint.sh` to output results to `/reports`.

## License

This project is provided as-is for testing purposes.

## Support

For issues related to:
- **Selenium IDE**: [Selenium IDE Documentation](https://www.selenium.dev/selenium-ide/)
- **selenium-side-runner**: [selenium-side-runner GitHub](https://github.com/SeleniumHQ/selenium-ide/tree/master/packages/side-runner)
- **Docker**: [Docker Documentation](https://docs.docker.com/)
