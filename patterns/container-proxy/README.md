# Clojure MCP Container Proxy

A containerized Clojure development environment that provides MCP (Model Context Protocol) server functionality with HTTP SSE (Server-Sent Events) proxy support for integration with Claude Desktop.

For a walkthrough video, see: [YouTube - model context protocol - clojure mcp examples with multiple clients](https://youtu.be/Cc1A8eKUs7k)

## Overview

This project demonstrates how to create a Clojure-based MCP server that runs in a container and exposes its functionality through an HTTP SSE endpoint. The setup includes:

- **Clojure MCP Server**: A simple Clojure application with example functions exposed as MCP tools
- **nREPL Development Environment**: Interactive Clojure development with REPL access
- **HTTP SSE Proxy**: Bridges the MCP stdio interface to HTTP for Claude Desktop integration
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
- **nREPL**: Interactive development environment
- **mcp-proxy**: HTTP SSE bridge for MCP stdio interface

## Prerequisites

- **Podman** (or Docker) installed on your system
- **Git** for cloning the repository

## Quick Start

### 1. Build the Container Image

From the project root directory:

```bash
podman build -t clojure-mcp-container-proxy-image devenv/container/
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
- Expose port 7080 for the MCP SSE proxy
- Start both nREPL (port 7888) and MCP SSE proxy (port 7080)
- Display real-time logs from both services

### 3. Verify the Setup

The container provides:

- **nREPL server** on port 7888 for interactive development
- **MCP SSE endpoint** at `http://localhost:7080/sse` for Claude Desktop
- **Real-time logs** displayed in the container output

## Claude Desktop Integration

### Configuration

Add this configuration to your `claude_desktop_config.json`:

**Non-Windows:**

```json
{
    "mcpServers": {
        "clojure-mcp-container-proxy": {
            "command": "bash",
            "args": [
                "-c",
                "/home/<user>/.local/bin/mcp-proxy http://localhost:7080/sse"
            ]
        }
    }
}
```

**Windows via WSL:**

```json
{
    "mcpServers": {
        "clojure-mcp-container-proxy": {
            "command": "wsl.exe",
            "args": [
                "bash",
                "-c",
                "/home/<user>/.local/bin/mcp-proxy http://localhost:7080/sse"
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

1. **mcp-proxy** installed (recommended via uv): `uv tool install mcp-proxy`
2. **WSL2** (Windows only) properly configured
3. **Container running** on port 7080

### Testing the Integration

Once configured:

1. Restart Claude Desktop
2. The MCP server should appear in Claude's available tools
3. Test by asking Claude to use the greeting or math functions

## Container Details

### What Happens During Startup

The container entrypoint script (`devenv/entrypoint.sh`):

1. **Creates log directory** and prepares log files
2. **Starts nREPL server** on port 7888 with CIDER middleware
3. **Starts MCP SSE proxy** on port 7080 bridging to the Clojure MCP stdio interface
4. **Tails logs** to display real-time output from both services

### Container Configuration

The container (`devenv/container/Containerfile`):

- Uses official Clojure tools-deps image with Temurin JDK 21
- Installs `uv` package manager
- Installs `mcp-proxy` tool via uv
- Exposes port 7080 for HTTP SSE communication

### Logs

Development logs are stored in `.logs/`:

- `nrepl.out` - nREPL server output and errors
- `mcp-sse.out` - MCP SSE proxy output and errors

## Managing the Container

### Stop the Container

```bash
podman stop clojure-mcp-container-proxy
```

Or press `Ctrl+C` in the terminal where it's running.

### Rebuild After Changes

```bash
# Rebuild image after modifying container configuration
./devenv/container/image-build.sh

# Restart with new image
./devenv/container/run-container.sh
```

## Troubleshooting

### Port Conflicts

**Port 7080 already in use:**

```bash
# Find and kill the process using port 7080
lsof -i :7080
kill <PID>
```

### Connection Issues

**MCP server not appearing in Claude Desktop:**

- Verify container is running: `podman ps`
- Check SSE endpoint: `curl http://localhost:7080/sse`
- Ensure `mcp-proxy` is installed and accessible
- Restart Claude Desktop (try View -> Reload or even restart the app (end Task from Task Manager)) after configuration changes

**nREPL connection failures:**

- Check if port 7888 is accessible: `nc -z localhost 7888`
- Verify container port mapping in `run-container.sh`
- Check nREPL logs in `.logs/nrepl.out`

### Container Issues

**Build failures:**

- Ensure you're in the project root directory
- Verify Podman/Docker is running
- Check internet connectivity for dependency downloads

**Permission issues:**

- Ensure project directory is readable/writable
- On SELinux systems, the `:Z` flag should handle context labeling

### Development Issues

**Code changes not reflecting:**

- Restart the container after modifying Clojure code
- For interactive development, use nREPL to reload namespaces
- Check that files are properly mounted in the container

**MCP functions not available:**

- Verify the MCP server started successfully in logs
- Check `mcp-sse.out` for any startup errors
- Ensure the clojure-mcp dependency is properly resolved
