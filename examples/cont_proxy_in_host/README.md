# Development Environment

This directory contains the containerized development environment for the Clojure MCP project.

## Architecture Overview

This setup provides a containerized Clojure development environment where:

- **Container**: Runs the Clojure application and development tools
- **Host System**: Runs the MCP SSE proxy server locally (not containerized)
- **Claude Desktop**: Connects to the local SSE proxy, which communicates with the containerized Clojure application

## Prerequisites

- **Podman** (or Docker) installed on your system
- **Git** for cloning the repository
- **uv package manager** installed locally for MCP proxy
- **mcp-proxy** tool installed locally: `uv tool install mcp-proxy`

## Container Setup

### Building the Image

To build the container image, run the following command from the project root directory:

```bash
podman build -t clojure-mcp-proxy-local devenv/container/
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
- Start the container with name `clojure-mcp-proxy-local`
- Execute the entrypoint script that sets up the development environment

## What Happens When You Run

When the container starts, the entrypoint script will:

1. **Set up logging**: Create `.logs` directory and prepare log files
2. **Start nREPL server**: Launch a Clojure REPL server for development
3. **Keep container running**: Maintain the container in a ready state for MCP communication

The SSE proxy server runs **locally on your host system**, not inside the container.

## Local SSE Proxy Setup

The MCP SSE proxy runs on your host system and communicates with the containerized Clojure application:

## Claude Desktop Integration

To connect Claude Desktop to your development environment, configure the MCP server in Claude Desktop's configuration file.

### Claude Desktop Configuration

#### Option 1: Direct Command (Linux/macOS)

```json
{
  "mcpServers": {
    "clojure-mcp": {
      "command": "bash",
      "args": [
        "-lc",
        "/home/<user>/.local/bin/mcp-proxy --host=127.0.0.1 --port=7081 -- podman exec -i -w /usr/app clojure-mcp-proxy-local clojure -X:mcp >/tmp/mcp-sse.log 2>&1 & for i in {1..50}; do curl -fsS http://127.0.0.1:7081/status >/dev/null && break || sleep 1; done; exec /home/<user>/.local/bin/mcp-proxy http://127.0.0.1:7081/sse"
      ]
    }
  }
}
```

Or with Windows WSL:

```json
{
  "mcpServers": {
    "clojure-mcp": {
      "command": "wsl.exe",
      "args": [
        "bash",
        "-lc",
        "/home/<user>/.local/bin/mcp-proxy --host=127.0.0.1 --port=7081 -- podman exec -i -w /usr/app clojure-mcp-proxy-local clojure -X:mcp >/tmp/mcp-sse.log 2>&1 & for i in {1..50}; do curl -fsS http://127.0.0.1:7081/status >/dev/null && break || sleep 1; done; exec /home/<user>/.local/bin/mcp-proxy http://127.0.0.1:7081/sse"
      ]
    }
  }
}
```

#### Option 2: Bridge Script (Recommended)

```json
{
  "mcpServers": {
    "clojure-mcp": {
      "command": "bash",
      "args": [
        "-lc",
        "/<path_to_project>/clojure_mcp_connection_examples/cont_proxy_local/devenv/claude/clojure-mcp-bridge.sh"
      ]
    }
  }
}
```

Or with Windows WSL:

```json
{
  "mcpServers": {
    "clojure-mcp": {
      "command": "wsl.exe",
      "args": [
        "bash",
        "-lc",
        "/<path_to_project>/clojure_mcp_connection_examples/cont_proxy_local/devenv/claude/clojure-mcp-bridge.sh"
      ]
    }
  }
}
```

### Configuration Details

- **Server Name**: `clojure-mcp` - This is the identifier for your MCP server
- **Host Setup**: The SSE proxy runs locally on port 7081
- **Container Communication**: The proxy communicates with the container via `podman exec`
- **Path**: Update `/home/<yourusername>/` to match your actual username and paths

### Prerequisites for Claude Desktop Integration

1. **Container must be running**: `clojure-mcp-proxy-local` container should be active
2. **uv package manager** must be installed locally
3. **mcp-proxy** must be installed: `uv tool install mcp-proxy`
4. For **Windows**: WSL2 must be installed and configured

### Configuration File Location

The `claude_desktop_config.json` file should be placed in Claude Desktop's configuration directory:

- **Windows**: `%APPDATA%\Roaming\Claude\claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

### Verifying the Connection

Once configured and with the development environment running:

1. Ensure the container `clojure-mcp-proxy-local` is running
2. Restart Claude Desktop
3. The MCP server should appear in Claude's available tools
4. You can interact with the Clojure REPL through Claude's interface

### Troubleshooting Claude Desktop Integration

#### MCP Server Not Appearing

- Verify the container `clojure-mcp-proxy-local` is running: `podman ps`
- Check that `mcp-proxy` is installed and accessible at the specified path
- Restart Claude Desktop after configuration changes
- For Windows: Stop Claude Desktop from Task Manager if needed

#### Connection Errors

- Test container communication: `podman exec -it clojure-mcp-proxy-local clojure -X:mcp`
- Verify the SSE proxy starts correctly by running the command manually
- Check proxy logs: `/.logs/mcp-sse.out` or `/tmp/mcp-sse.log` if running the one-liner config in Claude Desktop

#### Bridge Script Issues

- Ensure the bridge script is executable: `chmod +x devenv/claude/clojure-mcp-bridge.sh`
- Test the script manually before using it in Claude Desktop
- Update paths in the script to match your system configuration
