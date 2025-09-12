# Clojure MCP Host Proxy

A containerized Clojure development environment that provides MCP (Model Context Protocol) server functionality with host-based HTTP SSE (Server-Sent Events) proxy support for integration with Claude Desktop.

For a walkthrough video, see: [YouTube - model context protocol - clojure mcp examples with multiple clients](https://youtu.be/Cc1A8eKUs7k)

## Overview

This project demonstrates how to create a Clojure-based MCP server that runs in a container while exposing its functionality through a host-based HTTP SSE endpoint. The setup includes:

- **Clojure MCP Server**: A containerized Clojure application with example functions exposed as MCP tools
- **nREPL Development Environment**: Interactive Clojure development with REPL access
- **Host-based HTTP SSE Proxy**: Bridges the MCP stdio interface to HTTP for Claude Desktop integration
- **Containerized Clojure Environment**: Development environment packaged in a container with host system proxy

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

### Dependencies

The project uses:

- **Clojure 1.12.1**: Core language
- **clojure-mcp**: Library for MCP server functionality (from [bhauman/clojure-mcp](https://github.com/bhauman/clojure-mcp))
- **nREPL**: Interactive development environment
- **mcp-proxy**: Host-based HTTP SSE bridge for MCP stdio interface

## Prerequisites

- **Podman** (or Docker) installed on your system
- **Git** for cloning the repository
- **uv package manager** installed locally for MCP proxy
- **mcp-proxy** tool installed locally: `uv tool install mcp-proxy`

## Quick Start

### 1. Build the Container Image

From the project root directory:

```bash
podman build -t clojure-mcp-host-proxy-image devenv/container/
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
- Start the container with name `clojure-mcp-host-proxy`
- Start nREPL server (port 7888) inside the container
- Display real-time logs from the nREPL service

### 3. Verify the Setup

The container provides:

- **nREPL server** on port 7888 for interactive development
- **Containerized Clojure MCP server** accessible via `podman exec`
- **Real-time logs** displayed in the container output

### 4. Set Up Host-based SSE Proxy

The MCP SSE proxy runs on your host system (not in the container) and communicates with the containerized Clojure application. This architecture allows Claude Desktop to connect reliably while keeping the Clojure development environment containerized.

## Claude Desktop Integration

### Configuration

Add this configuration to your `claude_desktop_config.json`:

#### Option 1: Direct Command (Linux/macOS)

```json
{
    "mcpServers": {
        "clojure-mcp-host-proxy": {
            "command": "bash",
            "args": [
                "-lc",
                "/home/<user>/.local/bin/mcp-proxy --host=127.0.0.1 --port=7081 -- podman exec -i -w /usr/app clojure-mcp-host-proxy clojure -X:mcp >/tmp/mcp-sse.log 2>&1 & for i in {1..50}; do curl -fsS http://127.0.0.1:7081/status >/dev/null && break || sleep 1; done; exec /home/<user>/.local/bin/mcp-proxy http://127.0.0.1:7081/sse"
            ]
        }
    }
}
```

#### Option 2: Bridge Script (Recommended)

```json
{
    "mcpServers": {
        "clojure-mcp-host-proxy": {
            "command": "bash",
            "args": [
                "-lc",
                "/path/to/project/gen/claude_desktop/clojure-mcp-bridge.sh"
            ]
        }
    }
}
```

**Windows via WSL:**

```json
{
    "mcpServers": {
        "clojure-mcp-host-proxy": {
            "command": "wsl.exe",
            "args": [
                "bash",
                "-lc",
                "/path/to/project/gen/claude_desktop/clojure-mcp-bridge.sh"
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

1. **Container running**: `clojure-mcp-host-proxy` container must be active
2. **mcp-proxy** installed (recommended via uv): `uv tool install mcp-proxy`
3. **WSL2** (Windows only) properly configured
4. **Bridge script** configured with correct paths (if using Option 2)

### Testing the Integration

Once configured:

1. Ensure the container `clojure-mcp-host-proxy` is running
2. Restart Claude Desktop
3. The MCP server should appear in Claude's available tools
4. Test by asking Claude to use the greeting or math functions

## Container Details

### What Happens During Startup

The container entrypoint script (`devenv/entrypoint.sh`):

1. **Creates log directory** and prepares log files
2. **Starts nREPL server** on port 7888 with CIDER middleware
3. **Keeps container running** and ready for MCP communication via `podman exec`
4. **Tails logs** to display real-time output from the nREPL service

### Container Configuration

The container (`devenv/container/Containerfile`):

- Uses official Clojure tools-deps image with Temurin JDK 21
- Sets up working directory at `/usr/app`
- Provides a minimal, focused Clojure development environment

### Host-based SSE Proxy Architecture

The SSE proxy runs on your host system and:

- Starts an HTTP SSE server on port 7081
- Communicates with the containerized Clojure MCP server via `podman exec`
- Provides a reliable bridge for Claude Desktop integration
- Maintains separation between development environment and integration layer

### Logs

Development logs are stored in `.logs/`:

- `nrepl.out` - nREPL server output and errors
- `mcp-sse.out` - MCP SSE proxy output and errors (when using bridge script)

## Managing the Container

### Stop the Container

```bash
podman stop clojure-mcp-host-proxy
```

Or press `Ctrl+C` in the terminal where it's running.

### Rebuild After Changes

```bash
# Rebuild image after modifying container configuration
./devenv/container/image-build.sh

# Restart with new image
./devenv/container/run-container.sh
```

### Interactive Development

```bash
# Connect to nREPL for interactive development
# Container port 7888 is exposed to host
```

## Troubleshooting

### Port Conflicts

**Port 7081 already in use:**

```bash
# Find and kill the process using port 7081
lsof -i :7081
kill <PID>
```

### Connection Issues

**MCP server not appearing in Claude Desktop:**

- Verify container is running: `podman ps`
- Test container communication: `podman exec -it clojure-mcp-host-proxy clojure -X:mcp`
- Ensure `mcp-proxy` is installed and accessible
- Restart Claude Desktop (try View -> Reload or restart from Task Manager) after configuration changes

**Bridge script issues:**

- Ensure the bridge script is executable: `chmod +x gen/claude_desktop/clojure-mcp-bridge.sh`
- Update paths in the bridge script to match your system configuration
- Test the script manually before using it in Claude Desktop

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

**MCP functions not available:**

- Verify the container started successfully: `podman logs clojure-mcp-host-proxy`
- Test MCP server directly: `podman exec -it clojure-mcp-host-proxy clojure -X:mcp`
- Check SSE proxy logs in `.logs/mcp-sse.out` or `/tmp/mcp-sse.log`
- Ensure the clojure-mcp dependency is properly resolved

**Host-based proxy issues:**

- Verify `mcp-proxy` is installed and accessible
- Test SSE endpoint manually: `curl http://127.0.0.1:7081/status`
- Check that the container can be accessed via `podman exec`
- Ensure no firewall rules are blocking port 7081
