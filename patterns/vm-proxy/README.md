# VM Development Environment

This directory contains the VM-based development environment for the Clojure MCP project.

## Architecture Overview

This setup provides a virtualized Clojure development environment where:

- **Virtual Machine**: Runs the complete development stack (containers, Clojure application, MCP server)
- **Host System**: Runs Claude Desktop which connects to the VM
- **Container Inside VM**: Runs the Clojure application and MCP SSE proxy server
- **Claude Desktop**: Connects to the VM's exposed SSE endpoint

## Prerequisites

- **Virtual Machine Software** (VirtualBox, VMware, Hyper-V, etc.)
- **Linux VM** set up with:
  - **Nix** and **devenv** installed (via bootstrap scripts)
  - **Podman** or **Docker** for containerization
- **Claude Desktop** on your host system (for MCP integration)

## VM Setup Process

### 1. Create and Configure Your Virtual Machine

Set up a Linux virtual machine (Ubuntu, Fedora, etc.) with:

- At least 4GB RAM (8GB recommended)
- 20GB+ disk space
- Network access (NAT or Bridged)
- Port forwarding for port 7082 (VM → Host)

**Note**: For detailed VM setup instructions, refer to the video guide at: [nixos - setup virtual machine](https://youtu.be/8CXBBitdjBU)

### 2. Install Development Environment in VM

Inside your VM, clone and set up the project:

```bash
# Clone the repository
git clone <repository-url>
cd clojure-mcp-examples

# Install Nix
./bootstrap/01-install-nix.sh

# Close terminal and open new terminal

# Install devenv
./bootstrap/02-install-devenv.sh

# Enter development environment
devenv shell
```

### 3. Container Setup Inside VM

The development environment runs containers inside the VM:

#### Building the Image

```bash
# From within the devenv shell in the VM
podman build -t clojure-mcp-vm-proxy-image devenv/container/
```

This creates a container with:

- Official Clojure tools-deps image with Temurin JDK 21
- Required dependencies (curl, ca-certificates)
- `uv` package manager and `mcp-proxy` tool
- Working directory at `/usr/app`
- Exposed port 7082 for the MCP SSE server

#### Running the Container

```bash
# Start the development environment
start  # This uses the devenv script to start containers
```

The container startup process:

1. **Set up logging**: Create `.logs` directory and prepare log files
2. **Start nREPL server**: Launch Clojure REPL server for development
3. **Start MCP SSE proxy**: Launch MCP proxy on port 7082 (VM-specific port)
4. **Tail logs**: Display real-time logs from both services

## What's Running

Once started, your VM provides:

- **Clojure development environment** via nREPL (port 7888)
- **HTTP SSE endpoint** at `http://localhost:7082` for MCP communication
- **Real-time log monitoring** for debugging
- **Complete isolation** from host system

## Logs

Development logs are stored in the `.logs` directory within the VM:

- `nrepl.out` - nREPL server logs
- `mcp-sse.out` - MCP SSE proxy logs

## VM Port Configuration

Ensure your VM is configured to forward port 7082:

- **VM Port**: 7082 (internal container port)
- **Host Port**: 7082 (accessible from host system)
- **Protocol**: TCP

## Claude Desktop Integration (Host System)

Configure Claude Desktop on your host system to connect to the VM:

### Claude Desktop Configuration

#### Linux/macOS Host

```json
{
  "mcpServers": {
    "clojure-mcp-vm-proxy-in-vm": {
      "command": "bash",
      "args": [
        "-c",
        "mcp-proxy http://localhost:7082/sse"
      ]
    }
  }
}
```

#### Windows Host

```json
{
  "mcpServers": {
    "clojure-mcp-vm-proxy-in-vm": {
      "command": "cmd",
      "args": [
        "/c",
        "mcp-proxy http://localhost:7082/sse"
      ]
    }
  }
}
```

### Configuration Requirements

1. **mcp-proxy** must be installed on your host system:
   - Install via `uv tool install mcp-proxy` (requires Python and uv)
   - Or use your system's package manager
2. **VM must be running** with containers started
3. **Port 7082 must be forwarded** from VM to host
4. **Network connectivity** between host and VM

### Configuration File Location

Place `claude_desktop_config.json` in Claude Desktop's configuration directory:

- **Windows**: `%APPDATA%\Roaming\Claude\claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

## Advantages of VM-Based Setup

### ✅ Pros

- **Complete Isolation**: Full separation between development environment and host
- **Reproducible**: Entire VM can be cloned, backed up, or distributed
- **Team Consistency**: Same VM image ensures identical environments across team members
- **Resource Control**: Dedicated VM resources prevent conflicts with host system
- **Security**: Sandboxed environment for experimental or sensitive development

### ⚠️ Cons

- **Resource Overhead**: VM requires dedicated RAM and CPU resources
- **Network Complexity**: Additional network layer (host ↔ VM ↔ container)
- **Performance**: Slight performance penalty due to virtualization layer
- **Storage**: VM disk images can be large (10GB+)

## Troubleshooting

### Claude Desktop Connection

1. **MCP server not appearing**:
   - Verify mcp-proxy is installed on host
   - Check port 7082 is accessible from host: `curl http://localhost:7082/status`
   - Restart Claude Desktop after configuration changes

2. **Connection timeouts**:
   - Check VM is running and containers are started
   - Verify firewall settings aren't blocking port 7082
   - Test SSE endpoint: `curl http://localhost:7082/sse`