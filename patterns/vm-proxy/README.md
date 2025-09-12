# VM Proxy Pattern

This directory contains the VM-based deployment pattern for the Clojure MCP project. This pattern runs the complete development stack inside a virtual machine, with Claude Desktop connecting from the host system via an HTTP SSE proxy.

For a walkthrough video, see: [YouTube - model context protocol - clojure mcp examples with multiple clients](https://youtu.be/Cc1A8eKUs7k)

## Architecture Overview

This setup provides a virtualized Clojure development environment with these components:

- **Virtual Machine**: Contains the complete development environment (Clojure, nREPL, MCP server)
- **Host System**: Runs Claude Desktop which connects to the VM's exposed port
- **MCP SSE Proxy**: Bridges Claude Desktop's SSE client to the Clojure MCP stdio interface
- **Claude Desktop**: Connects to the VM's HTTP SSE endpoint for MCP communication

## When to Use This Pattern

### ✅ Ideal For

- **Team Development**: Ensures identical environments across all team members
- **Sandboxed Development**: Complete isolation from host system
- **Production-like Testing**: VM mimics server deployment environments
- **Resource Isolation**: Dedicated VM resources prevent conflicts with host applications
- **Security-sensitive Projects**: Additional isolation layer for experimental or sensitive development
- **Backup/Distribution**: Entire development environment can be snapshotted and shared

### ⚠️ Consider Alternatives If

- **Limited Resources**: VM requires significant RAM and storage
- **Performance Critical**: Virtualization adds overhead compared to other patterns
- **Simple Projects**: Container patterns are simpler for development
- **Network Restrictions**: Additional network complexity (host ↔ VM ↔ services)

## Prerequisites

### Virtual Machine Requirements

- **Hypervisor**: VirtualBox, VMware, Hyper-V, or similar
- **Guest OS**: Linux distribution (Ubuntu 20.04+, Fedora 35+, etc.)
- **Resources**:
  - 4GB RAM minimum (8GB recommended)
  - 20GB+ disk space
  - Network access (NAT or Bridged networking)
- **Port Forwarding**: VM port 7080 → Host port 7080

### Host System Requirements

- **Claude Desktop**: Installed and configured
- **mcp-proxy tool**: Install via `uv tool install mcp-proxy` (requires Python and uv)
- **Network Access**: Ability to connect to VM's forwarded port

### Detailed VM Setup

For comprehensive VM setup instructions, see: [NixOS - Setup Virtual Machine](https://youtu.be/8CXBBitdjBU)

## VM Environment Setup

### 1. Initial VM Configuration

After creating your Linux VM, clone and set up the project:

```bash
# Clone the repository
git clone <repository-url>
cd clojure-mcp-examples

# Install Nix (if not already installed)
../../bootstrap/01-install-nix.sh

# Close terminal and open new terminal session

# Install devenv
../../bootstrap/02-install-devenv.sh

# Enter development environment
devenv shell
```

### 2. Start the Development Environment

From within the VM, in the `patterns/vm-proxy` directory:

```bash
# Start the development services
bash devenv/entrypoint.sh
```

This script will:

1. Create and prepare log directories
2. Start nREPL server on port 7888 (VM internal)
3. Start MCP SSE proxy on port 7080 (exposed to host)
4. Display real-time logs from both services

### 3. Manual Startup (Alternative)

You can also start services manually for debugging:

```bash
# Terminal 1: Start nREPL
clojure -M:mcp-nrepl

# Terminal 2: Start MCP proxy (after nREPL is running)
mcp-proxy --host=0.0.0.0 --port=7080 -- clojure -X:mcp
```

## VM Port Configuration

Ensure your VM is configured to forward port 7080:

### VirtualBox Example

1. VM Settings → Network → Advanced → Port Forwarding
2. Add rule: Host Port `7080` → Guest Port `7080`
3. Protocol: TCP

### VMware Example

1. VM Settings → Network Adapter → NAT → Advanced
2. Add Port Forwarding: Host Port `7080` → Guest Port `7080`

### Testing Port Access

From your host system:

```bash
curl http://localhost:7080/status
```

## Project Structure

```bash
patterns/vm-proxy/
├── README.md              # This documentation
├── deps.edn              # Clojure dependencies and aliases
├── devenv/
│   └── entrypoint.sh     # VM service startup script
└── src/
    └── mcp/
        └── mcp.clj       # Example MCP service functions
```

## Configuration Details

### deps.edn

- **:mcp-nrepl**: Starts nREPL with CIDER middleware on port 7888
- **:mcp**: Runs the MCP server connecting to nREPL

### Clojure MCP Functions

The `src/mcp/mcp.clj` file contains example functions:

- `greet`: Simple greeting function with optional name parameter
- `plus-two`: Mathematical function demonstrating parameter handling
- `-main`: Command-line entry point demonstrating function usage

## Claude Desktop Integration

### Host System Configuration

Add this configuration to your Claude Desktop config file:

#### Linux/macOS Host

```json
{
  "mcpServers": {
    "clojure-mcp-vm-proxy": {
      "command": "bash",
      "args": [
        "-c",
        "mcp-proxy http://localhost:7080/sse"
      ]
    }
  }
}
```

#### Windows Host

```json
{
  "mcpServers": {
    "clojure-mcp-vm-proxy": {
      "command": "cmd",
      "args": [
        "/c",
        "mcp-proxy http://localhost:7080/sse"
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

1. **mcp-proxy installed on host**: `uv tool install mcp-proxy`
2. **VM running with services started**
3. **Port 7080 forwarded** from VM to host
4. **Network connectivity** between host and VM

## Development Workflow

### Starting Development

1. **Start VM** and log in
2. **Navigate** to project directory
3. **Run services**: `bash devenv/entrypoint.sh`
4. **Verify connection** from host: `curl http://localhost:7080/status`
5. **Restart Claude Desktop** to pick up MCP server

### Development Cycle

1. **Modify Clojure code** in `src/mcp/mcp.clj`
2. **Connect to nREPL** for interactive development (port 7888)
3. **Test functions** via Claude Desktop MCP interface
4. **Monitor logs** in `.logs/` directory

### Logs and Monitoring

Development logs are stored in the VM at `.logs/`:

- `nrepl.out` - nREPL server output and errors
- `mcp-sse.out` - MCP SSE proxy output and errors

View logs in real-time:

```bash
tail -f .logs/nrepl.out .logs/mcp-sse.out
```

## Troubleshooting

### VM Connectivity Issues

**Port forwarding not working:**

```bash
# From host system
telnet localhost 7080

# From inside VM
netstat -ln | grep 7080
```

**Services not starting:**

```bash
# Check nREPL
lsof -i :7888

# Check proxy
lsof -i :7080

# View service logs
cat .logs/nrepl.out
cat .logs/mcp-sse.out
```

### Claude Desktop Connection

**MCP server not appearing:**

1. Verify mcp-proxy is installed: `which mcp-proxy`
2. Test SSE endpoint: `curl http://localhost:7080/sse`
3. Check Claude Desktop logs
4. Restart Claude Desktop completely

**Connection timeouts:**

1. Verify VM services are running
2. Check firewall settings on host and VM
3. Test basic connectivity: `ping <vm-ip>`
4. Verify port forwarding configuration
