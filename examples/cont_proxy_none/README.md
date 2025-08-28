# Development Environment

This directory contains the containerized development environment for the Clojure MCP project.

## Architecture Overview

This setup provides a containerized Clojure development environment where:

- **Container**: Runs the Clojure application and MCP server
- **Claude Desktop**: Connects directly to the containerized Clojure MCP server

## Prerequisites

- **Podman** (or Docker) installed on your system
- **Git** for cloning the repository

## Container Setup

### Building the Image

To build the container image, run the following command from the project root directory:

```bash
podman build -t clojure-mcp-proxy-none-image devenv/container/
```

This will:

- Use the official Clojure tools-deps image with Temurin JDK 21
- Set up the working directory at `/usr/app`

### Running the Container

After building the image, you can run the container using the provided script:

```bash
./devenv/container/run-container.sh
```

This script will:

- Mount the project directory to `/usr/app/` inside the container
- Mount your local Maven repository (`~/.m2`) to `/root/.m2` for dependency caching
- Start the container with name `clojure-mcp-proxy-none`
- Execute the entrypoint script that sets up the development environment

## What Happens When You Run

When the container starts, the entrypoint script will:

1. **Set up logging**: Create `.logs` directory and prepare log files
2. **Start nREPL server**: Launch a Clojure REPL server for development
3. **Keep container running**: Maintain the container in a ready state for MCP communication

## Claude Desktop Integration

To connect Claude Desktop to your development environment, configure the MCP server in Claude Desktop's configuration file.

### Claude Desktop Configuration

```json
{
  "mcpServers": {
    "clojure-mcp": {
      "command": "wsl.exe",
      "args": [
        "bash",
        "-lc",
        "exec /usr/bin/podman exec -i -w /usr/app clojure-mcp-proxy-none clojure -X:mcp"
      ]
    }
  }
}
```

For Linux/macOS (without WSL):

```json
{
  "mcpServers": {
    "clojure-mcp": {
      "command": "bash",
      "args": [
        "-lc",
        "exec /usr/bin/podman exec -i -w /usr/app clojure-mcp-proxy-none clojure -X:mcp"
      ]
    }
  }
}
```

### Configuration Details

- **Server Name**: `clojure-mcp` - This is the identifier for your MCP server
- **Direct Connection**: Claude Desktop connects directly to the containerized MCP server
- **Container Communication**: Direct communication with the container via `podman exec`

### Prerequisites for Claude Desktop Integration

1. **Container must be running**: `clojure-mcp-proxy-none` container should be active
2. For **Windows**: WSL2 must be installed and configured

### Configuration File Location

The `claude_desktop_config.json` file should be placed in Claude Desktop's configuration directory:

- **Windows**: `%APPDATA%\Roaming\Claude\claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

### Verifying the Connection

Once configured and with the development environment running:

1. Ensure the container `clojure-mcp-proxy-none` is running
2. Restart Claude Desktop
3. The MCP server should appear in Claude's available tools
4. You can interact with the Clojure REPL through Claude's interface

### Troubleshooting Claude Desktop Integration

#### MCP Server Not Appearing

- Verify the container `clojure-mcp-proxy-none` is running: `podman ps`
- Restart Claude Desktop after configuration changes
- For Windows: Stop Claude Desktop from Task Manager if needed

#### Connection Errors

- Test container communication: `podman exec -it clojure-mcp-proxy-none clojure -X:mcp`
- Check container logs: `podman logs clojure-mcp-proxy-none`
