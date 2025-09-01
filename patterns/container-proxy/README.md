# Development Environment

This directory contains the containerized development environment for the Clojure MCP project.

## Prerequisites

- **Podman** (or Docker) installed on your system
- **Git** for cloning the repository

## Container Setup

### Building the Image

To build the container image, run the following command from the project root directory:

```bash
podman build -t clojure-mcp-proxy-in-cont-image devenv/container/
```

This will:

- Use the official Clojure tools-deps image with Temurin JDK 21
- Install required dependencies (curl, ca-certificates)
- Install `uv` package manager
- Install `mcp-proxy` tool via uv
- Set up the working directory at `/usr/app`
- Expose port 7080 for the HTTPS SSE server

### Running the Container

After building the image, you can run the container using the provided script:

```bash
./devenv/container/run-container.sh
```

This script will:

- Mount the project directory to `/usr/app/` inside the container
- Mount your local Maven repository (`~/.m2`) to `/root/.m2` for dependency caching
- Expose port 7080 for the MCP SSE proxy
- Start the container interactively
- Execute the entrypoint script that sets up the development environment

## What Happens When You Run

When the container starts, the entrypoint script will:

1. **Set up logging**: Create `.logs` directory and prepare log files
2. **Start nREPL server**: Launch a Clojure REPL server for development
3. **Start MCP SSE proxy**: Launch the MCP proxy on port 7080 that bridges to the Clojure MCP stdio interface
4. **Tail logs**: Display real-time logs from both services

The container will run indefinitely, providing:

- A Clojure development environment via nREPL
- An HTTP SSE endpoint at `http://localhost:7080` for MCP communication
- Real-time log monitoring

## Logs

Development logs are stored in the `.logs` directory:

- `nrepl.out` - nREPL server logs
- `mcp-sse.out` - MCP SSE proxy logs

## Stopping the Container

To stop the running container:

```bash
podman stop clojure-mcp-proxy-in-cont
```

Or simply press `Ctrl+C` if running interactively.

## Troubleshooting

### Port Already in Use

If port 7080 is already in use, you have several options:

#### Option 1: Kill the process using the port**

```bash
# Find the process using port 7080
lsof -i :7080

# Example output:
# COMMAND  PID     USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
# exe     5789 stoating   12u  IPv6  81839      0t0  TCP *:7080 (LISTEN)

# Kill the process using the PID from the output
kill 5789
```

#### Option 2: Use a different port

Modify the port mapping in the run command:

```bash
-p 8080:7080  # Maps local port 8080 to container port 7080
```

### Volume Mount Issues

If you encounter permission issues with volume mounts, ensure:

- The project directory is readable/writable
- SELinux contexts are properly set (the `:Z` flag should handle this)

### Container Build Fails

- Ensure you're running the build command from the project root directory
- Check that Podman/Docker is properly installed and running
- Verify internet connectivity for downloading dependencies

## Claude Desktop Integration

To connect Claude Desktop to your running development environment, you'll need to configure the MCP server in Claude Desktop's configuration file.

### Claude Desktop Configuration

Create or update your `claude_desktop_config.json` file with the following configuration:

Non-Windows

```json
{
    "mcpServers": {
        "clojure-mcp-proxy-in-cont": {
            "command": "bash",
            "args": [
                "-c",
                "/home/<user>/.local/bin/mcp-proxy http://localhost:7080/sse"
            ]
        }
    }
}
```

Windows via WSL

```json
{
    "mcpServers": {
        "clojure-mcp-proxy-in-cont": {
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

### Configuration Details

- **Server Name**: `clojure-mcp-proxy-in-cont` - This is the identifier for your MCP server
- **Command**: `wsl.exe` - Uses Windows Subsystem for Linux to execute the proxy command
- **Args**: Runs the `mcp-proxy` tool that connects to the SSE endpoint at `http://localhost:7080/sse`
- **Path**: `/home/stoating/.local/bin/mcp-proxy` - The location where `uv` installs the mcp-proxy tool

### Prerequisites for Claude Desktop Integration

1. **WSL2** must be installed and configured on your Windows system
2. **uv package manager** must be installed in your WSL environment
3. **mcp-proxy** must be installed (recommended via uv): `uv tool install mcp-proxy`
4. The **development container must be running** on port 7080

### Configuration File Location

The `claude_desktop_config.json` file should be placed in Claude Desktop's configuration directory:

- **Windows**: `%APPDATA%\Roaming\Claude\claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

### Verifying the Connection

Once configured and with the development environment running:

1. Restart Claude Desktop
2. The MCP server should appear in Claude's available tools
3. You can interact with the Clojure REPL through Claude's interface

### Troubleshooting Claude Desktop Integration

#### MCP Server Not Appearing

- Verify the development container is running on port 7080
- Check that WSL can access `localhost:7080` from within the WSL environment
- Ensure `mcp-proxy` is installed and accessible at the specified path
- Restart Claude Desktop after configuration changes. In Windows, you may need to stop Claude Desktop from the Task Manager.

#### Connection Errors

- Verify the SSE endpoint is accessible: `curl http://localhost:7080/sse` from WSL
- Check firewall settings aren't blocking port 7080
- Ensure the container is exposing port 7080 correctly
