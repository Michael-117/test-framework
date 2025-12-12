# Selenium Side Runner Docker Setup

This setup creates two Docker containers:
1. **selenium-browser**: A standalone Chrome browser container using SeleniumHQ's official image
2. **selenium-side-runner**: A container that runs Selenium IDE test files (.side) against the browser container

## Prerequisites

- Docker and Docker Compose installed
- Selenium IDE test files (.side format)

## Setup

### 1. Create Environment File

Create a `.env` file in the project root directory with your test configuration:

```bash
# Copy the example and edit with your values
cp .env.example .env
```

Or create a `.env` file manually with the following content:

```env
# Application URL
TEST_URL=http://cvlueitapp1.cscdev.com:17991/cms/

# Test Username
TEST_USERNAME=vbindiga
```

**Important**: Update the values in `.env` with your actual test URL and username. The `.env` file is used by the test files to substitute variables.

### 2. Place your .side files

Place your Selenium IDE test files (`.side` files) in the `side` directory:

```
side/
  ├── login-test.side
  ├── test2.side
  └── ...
```

## Usage

### 1. Start the containers

Start the Docker containers in detached mode:

```bash
docker-compose up -d
```

This will:
- Start the browser container (selenium-browser)
- Wait for it to be healthy
- Start the selenium-side-runner container

### 2. Run a specific test file

To run a specific test file, set the `TEST_FILE` environment variable:

```bash
docker-compose run --rm selenium-side-runner -e TEST_FILE=login-test.side
```

Or run directly with selenium-side-runner:

```bash
docker-compose exec selenium-side-runner selenium-side-runner -w 10 --server http://selenium-browser:4444/wd/hub /app/side/login-test.side
```

**Note**: The test will automatically use the `TEST_URL` and `TEST_USERNAME` values from your `.env` file.

### 3. View browser (optional)

If you want to watch the browser in action, you can access the VNC viewer at:
- URL: `http://localhost:7900`
- Password: (none, as VNC_NO_PASSWORD=1)

### 4. Stop the containers

```bash
docker-compose down
```

## Configuration

### Environment Variables

The following environment variables are loaded from the `.env` file:

- `TEST_URL`: The base URL for your application (e.g., `http://cvlueitapp1.cscdev.com:17991/cms/`)
- `TEST_USERNAME`: The username to use in login tests (e.g., `vbindiga`)

Additional environment variables:

- `SELENIUM_SERVER`: The Selenium Grid hub URL (default: `http://selenium-browser:4444/wd/hub`)
- `TEST_FILE`: Name of the .side file to run (should be in the `side` directory)

### Volumes

- `./side:/app/side`: Maps your local `side` directory to the container's `/app/side` directory

### Ports

- `4444`: Selenium Grid hub port
- `7900`: VNC port for viewing the browser (optional)

## Architecture

The setup follows the recommended architecture from [Stack Overflow](https://stackoverflow.com/questions/61496129/how-to-run-selenium-side-runner-in-docker):

- **Separation of concerns**: Browser and test runner are in separate containers
- **Network communication**: Both containers communicate through a custom Docker network (`selenium-tests`)
- **Health checks**: The runner waits for the browser to be healthy before starting

## How Environment Variables Work

The test files (`.side`) use variable substitution syntax `${VARIABLE_NAME}` to reference environment variables. When selenium-side-runner executes the tests, it automatically substitutes these variables with values from the environment.

For example, in `login-test.side`:
- `${TEST_URL}` is replaced with the value from your `.env` file
- `${TEST_USERNAME}` is replaced with the value from your `.env` file

This allows you to:
- Run the same tests against different environments by changing the `.env` file
- Use different usernames without modifying the test files
- Keep sensitive or environment-specific data out of version control

## Troubleshooting

1. **Browser container not starting**: Check logs with `docker-compose logs selenium-browser`
2. **Tests not connecting**: Verify the network is created: `docker network ls | grep selenium-tests`
3. **No .side files found**: Ensure your test files are in the `side` directory with `.side` extension
4. **Environment variables not working**: 
   - Ensure you have a `.env` file in the project root
   - Verify the variable names match exactly (case-sensitive)
   - Check that the `.env` file is not in `.gitignore` if you need it (though typically `.env` should be gitignored)
5. **Variable substitution errors**: Make sure your `.env` file has both `TEST_URL` and `TEST_USERNAME` defined
