# Clojure MCP Development Environment

A containerized Clojure development environment that provides MCP (Model Context Protocol) server functionality for seamless integration with Claude Desktop through direct container communication.

## Overview

This project demonstrates how to create a Clojure-based MCP server that runs in a containerized development environment with direct integration to Claude Desktop. The setup includes:

- **Clojure MCP Server**: A simple Clojure application with example functions exposed as MCP tools
- **nREPL Development Environment**: Interactive Clojure development with REPL access
- **Direct Container Integration**: Claude Desktop connects directly to the containerized MCP server
- **Containerized Setup**: Complete development environment packaged in a container

## Project Structure

```bash
.
├── deps.edn                 # Clojure project dependencies and aliases
├── src/
│   └── mcp/
│       └── mcp.clj          # Main Clojure application with MCP functions
└── devenv/
    ├── entrypoint.sh        # Container startup script
    └── container/
        ├── Containerfile    # Container image definition
        ├── image-build.sh   # Container build script
        └── run-container.sh # Container run script
```

## Clojure Application

The main Clojure application (`src/mcp/mcp.clj`) provides example MCP functionality:

### Dependencies

The project uses:

- **Clojure 1.12.1**: Core language
- **clojure-mcp**: Library for MCP server functionality (from [bhauman/clojure-mcp](https://github.com/bhauman/clojure-mcp))
- **nREPL**: Interactive development environment with CIDER middleware

## Prerequisites

- **Podman** (or Docker) installed on your system
- **Git** for cloning the repository

## Quick Start

### 1. Build the Container Image

From the project root directory:

```bash
podman build -t clojure-mcp-proxy-direct-image devenv/container/
```

Or use the provided script:

```bash
./devenv/container/image-build.sh
```

### 2. Run the Container

```bash
./devenv/container/run-container.sh
```

This will:

- Mount the project directory to `/usr/app/` inside the container
- Mount your local Maven repository (`~/.m2`) for dependency caching
- Start the container with name `clojure-mcp-proxy-direct`
- Set up the development environment with nREPL server
- Keep the container running and ready for MCP communication

### 3. Verify the Setup

The container provides:

- **nREPL server** on port 7888 for interactive development
- **MCP server** accessible via `clojure -X:mcp` for Claude Desktop integration
- **Development logs** in `.logs/` directory

## Claude Desktop Integration

### Configuration

Add this configuration to your `claude_desktop_config.json`:

**Non-Windows (Linux/macOS):**

```json
{
  "mcpServers": {
    "clojure-mcp": {
      "command": "bash",
      "args": [
        "-c",
        "exec /usr/bin/podman exec -i -w /usr/app clojure-mcp-proxy-direct clojure -X:mcp"
      ]
    }
  }
}
```

**Windows via WSL:**

```json
{
  "mcpServers": {
    "clojure-mcp": {
      "command": "wsl.exe",
      "args": [
        "bash",
        "-c",
        "exec /usr/bin/podman exec -i -w /usr/app clojure-mcp-proxy-direct clojure -X:mcp"
      ]
    }
  }
}
```

### Configuration File Locations

- **Windows**: `%APPDATA%\Roaming\Claude\claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

### Prerequisites for Integration

1. **Container running** with name `clojure-mcp-proxy-direct`
2. **WSL2** (Windows only) properly configured
3. **Podman/Docker** accessible from the command line

### Testing the Integration

Once configured:

1. Restart Claude Desktop
2. The MCP server should appear in Claude's available tools
3. Test by asking Claude to use the greeting or math functions from the Clojure application

## Container Details

### What Happens During Startup

The container entrypoint script (`devenv/entrypoint.sh`):

1. **Creates log directory** and prepares log files
2. **Starts nREPL server** on port 7888 with CIDER middleware for development
3. **Keeps container running** in a ready state for MCP communication

### Container Configuration

The container (`devenv/container/Containerfile`):

- Uses official Clojure tools-deps image with Temurin JDK 21
- Sets working directory to `/usr/app`
- Provides complete Clojure development environment

### Logs

Development logs are stored in `.logs/`:

- Container startup and application logs
- nREPL server output for development activities

## Managing the Container

### Stop the Container

```bash
podman stop clojure-mcp-proxy-direct
```

### Restart the Container

```bash
# Stop existing container
podman stop clojure-mcp-proxy-direct

# Start fresh container
./devenv/container/run-container.sh
```

### Rebuild After Changes

```bash
# Rebuild image after modifying container configuration
./devenv/container/image-build.sh

# Restart with new image
./devenv/container/run-container.sh
```

## Troubleshooting

### Container Issues

**Container not starting:**

```bash
# Check if container exists
podman ps -a

# Check container logs
podman logs clojure-mcp-proxy-direct
```

**Build failures:**

- Ensure you're in the project root directory
- Verify Podman/Docker is running
- Check internet connectivity for dependency downloads

### Claude Desktop Integration Issues

**MCP server not appearing in Claude Desktop:**

- Verify container is running: `podman ps`
- Test container communication: `podman exec -it clojure-mcp-proxy-direct clojure -X:mcp`
- Restart Claude Desktop after configuration changes
- For Windows: Stop Claude Desktop from Task Manager if needed

**Connection errors:**

- Ensure container name matches: `clojure-mcp-proxy-direct`
- Verify Podman is accessible from command line
- Check that the `:mcp` alias is properly configured in `deps.edn`

### Development Issues

**nREPL connection failures:**

- Check if container is running: `podman ps`
- Verify port 7888 is accessible: `podman exec clojure-mcp-proxy-direct netstat -ln | grep 7888`
- Check container logs for nREPL startup messages

**Code changes not reflecting:**

- For interactive development, use nREPL to reload namespaces
- Restart the container to pick up major changes
- Ensure files are properly mounted in the container

**Permission issues:**

- Ensure project directory is readable/writable
- On SELinux systems, the container script should handle context labeling

### Architecture Details

This development environment uses:

- **Direct Container Communication**: Claude Desktop connects directly to the containerized MCP server
- **No HTTP Proxy**: Simpler architecture with direct stdio communication
- **Container Persistence**: The named container allows for consistent connection and state management
