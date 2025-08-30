# Clojure MCP Connection Examples

A comprehensive demonstration of different ways to connect your LLM (especially Claude Desktop) with Clojure codebases using the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/). This project showcases multiple architectural patterns for integrating Claude Desktop with Clojure development environments.

## 🎯 Project Overview

This repository demonstrates **four different connection patterns** for integrating Claude Desktop with Clojure development environments:

1. **Container + Proxy None** (`cont_proxy_none`) - Direct container connection
2. **Container + Proxy In Container** (`cont_proxy_in_cont`) - SSE proxy inside container
3. **Container + Proxy In Host** (`cont_proxy_in_host`) - SSE proxy on host system
4. **Virtual Machine + Proxy In VM** (`vm_proxy_in_vm`) - VM-based setup similar to SSE proxy inside container

Each example provides a complete, reproducible development environment using containers and the powerful [clojure-mcp](https://github.com/bhauman/clojure-mcp) library for seamless REPL integration.

### 🔍 Focused Development with Selective Mounting

One particularly interesting aspect of this containerized approach is that you can not only mount a full project, but also break larger projects into smaller parts and mount only specific subsections. This allows you to provide reduced context to your LLM, keeping it focused on the current area of interest in your codebase rather than being overwhelmed by the entire project structure.

### 💡 Recommended Approach: SSE Proxy in Container

Based on practical experience, running the SSE proxy inside the container (Pattern 2: `cont_proxy_in_cont`) tends to provide the smoothest workflow. This approach keeps Claude's responsibility minimal - simply pointing Claude to a ready endpoint that's prepared for immediate interaction. The container handles all the complexity internally, presenting Claude with a clean, standardized HTTP/SSE interface.

## 🚀 Quick Start

### Prerequisites

- **Claude Desktop** (for MCP integration)

**Note**: The bootstrap scripts handle installation of **Nix** and **devenv**. After installing Nix, **close your terminal and open a new terminal** before installing devenv. Once you enter the devenv shell with `devenv shell`, all other dependencies (Podman, Clojure, mcp-proxy, etc.) are guaranteed to be present due to the Nix packaging system.

- For VM setup, you'll need a VM to be set up (You can use VirtualBox, VMware, or any other virtualization tool of your choice). I have an example setup here: [nixos - setup virtual machine dev env](https://youtu.be/8CXBBitdjBU)

### One-Time Setup

1. **Clone the repository:**

   ```bash
   git clone <repository-url>
   cd clojure-mcp-examples
   ```

2. **Install Nix:**

   ```bash
   ./bootstrap/01-install-nix.sh
   ```

3. **Close your terminal and open a new terminal**

4. **Install devenv:**

   ```bash
   ./bootstrap/02-install-devenv.sh
   ```

5. **Enter the development environment:**

   ```bash
   devenv shell
   ```

6. **Generate MCP bridge scripts:**

   ```bash
   bridge
   ```

7. **Generate Claude Desktop configuration (choose one):**

   ```bash
   claude        # For Linux/macOS (recommended for Linux/macOS)
   claude-vm     # For Linux/macOS with VM support
   claude-win    # For Windows (recommended for Windows)
   claude-win-vm # For Windows with VM support
   ```

8. **Copy the generated `claude_desktop_config.json` to Claude Desktop's config directory:**
   - **Windows**: `%APPDATA%\Roaming\Claude\claude_desktop_config.json`
   - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Linux**: `~/.config/Claude/claude_desktop_config.json`

9. **Start the development environment:**

   ```bash
   start
   ```

10. **Restart Claude Desktop** to load the new MCP servers

## 🏗️ Architecture Overview

This project demonstrates different architectural patterns for connecting Claude Desktop to Clojure development environments:

### Pattern 1: Direct Container Connection (`cont_proxy_none`)

```  bash
Claude Desktop → podman exec → Container (Clojure MCP)
```

- **Pros**: Simple, direct connection
- **Cons**: Platform-specific commands in Claude config
- **Best for**: Simple setups and quick testing

### Pattern 2: Container with Internal Proxy (`cont_proxy_in_cont`)

```  bash
Claude Desktop → mcp-proxy client → HTTP/SSE → Container (mcp-proxy server + Clojure MCP)
```

- **Pros**: Platform-agnostic HTTP communication
- **Cons**: More complex container setup
- **Best for**: Cross-platform compatibility, HTTP-based workflows

### Pattern 3: Container with Host Proxy (`cont_proxy_in_host`)

```  bash
Claude Desktop → Bridge Script → mcp-proxy (host) → HTTP/SSE → Container (Clojure MCP)
```

- **Pros**: If you have to it is good to know you can
- **Cons**: Requires host-side proxy installation. Passes responsibility to the host
- **Best for**: Development environments where you want proxy control on the host

### Pattern 4: Virtual Machine Setup (`vm_proxy_in_vm`)

```  bash
Claude Desktop → mcp-proxy client → HTTP/SSE → VM (mcp-proxy server + Clojure MCP)
```

- **Pros**: Better isolation, reproducible VM environments
- **Cons**: Higher resource usage. Need to start VM and necessary processes on VM separately
- **Best for**: Team using VMs in >=2025

## 📁 Project Structure

``` bash
├── bootstrap/              # Installation scripts for Nix and devenv
│   ├── 01-install-nix.sh
│   └── 02-install-devenv.sh
├── bin/                    # Utility scripts
│   ├── claude.sh           # Generate Claude Desktop configs
│   ├── claude-win.sh       # Windows-specific Claude configs
│   ├── gen-bridge.sh       # Generate MCP bridge scripts
│   └── containers-*.sh     # Container management scripts
│   └── images-*.sh         # Image management scripts
├── examples/               # Four different connection patterns
│   ├── cont_proxy_none/    # Direct container connection
│   ├── cont_proxy_in_cont/ # Container-based proxy
│   ├── cont_proxy_in_host/ # Host-based proxy
│   └── vm_proxy_in_vm/     # VM-based setup
├── src/mcp/                # Example Clojure application
│   └── mcp.clj             # Playground where your project would go
├── devenv.nix              # Development environment configuration
└── deps.edn                # Clojure dependencies and aliases
```

## 🛠️ Development Environment Features

### Reproducible Setup with devenv

- **Nix-based**: Ensures identical environments across machines without version conflict (installed via bootstrap script)
- **Container Support**: Podman/Docker integration (available per default in this devenv shell)
- **Python Tools**: Pre-configured `mcp-proxy` and dependencies (available per default in this devenv shell)
- **Clojure Tools**: Complete Clojure development stack (available per default in this devenv shell)

### MCP Integration

- **clojure-mcp**: Direct REPL integration with Claude
- **Multi-pattern**: Four different connection architectures
- **Cross-platform**: (Theoretical! Help me confirm and improve!) Windows, macOS, and Linux support
- **Logging**: Comprehensive logging for debugging

### Container Features

- **Clojure 1.12.1**: Latest stable Clojure version
- **nREPL**: Interactive development server
- **Volume Mounts**: Live code editing without risk of Claude going rogue
- **Port Forwarding**: HTTP/SSE communication

## 🎨 Example Usage

Once connected, you can interact with your Clojure codebase through Claude Desktop:

```clojure
;; Claude can execute Clojure code in your development environment
(+ 1 2 3)
; => 6

;; Access your project functions
(mcp.mcp/greet {:name "Claude"})
; "Hello, Claude!"

;; Explore your codebase
(clj-mcp.repl-tools/list-ns)
; Shows all available namespaces

;; Get function documentation
(clj-mcp.repl-tools/doc-symbol 'map)
; Shows documentation for the map function
```

## 🔧 Available Commands

The devenv shell provides you convenient scripts to seamlessly get up and running:

### Setup Commands

- `bridge` - Generate MCP bridge configuration
- `claude` - Generate Claude Desktop config (Linux/macOS)
- `claude-vm` - Generate Claude Desktop config with VM support
- `claude-win` - Generate Claude Desktop config (Windows)
- `claude-win-vm` - Generate Claude Desktop config (Windows + VM)

### Environment Management

- `start` - Start all development containers
- `stop` - Stop all running containers
- `remove` - Remove containers and images
- `dev-*` - Development versions of the above commands (including high-level mcp development of the entire project)

## 🐛 Troubleshooting

### MCP Server Not Appearing in Claude Desktop

1. **Verify container status:**

   ```bash
   podman ps  # Check if containers are running
   ```

2. **Check Claude Desktop config:**
   - Ensure config file is in the correct location
   - Restart Claude Desktop after config changes
   - On Windows, stop Claude from Task Manager if needed (view -> reload is usually enough)

3. **Test MCP connection manually:**

   ```bash
   # Test container-based MCP
   podman exec -it <container-name> clojure -X:mcp

   # Test HTTP endpoint
   curl http://localhost:7080/status
   ```

## 🧪 Development Workflow

## 📚 Learning Resources

- **[Model Context Protocol](https://modelcontextprotocol.io/)** - Official MCP documentation
- **[clojure-mcp](https://github.com/bhauman/clojure-mcp)** - Clojure MCP implementation
- **[devenv](https://devenv.sh/)** - Development environment management
- **[Claude Desktop](https://claude.ai/desktop)** - AI assistant with MCP support

## 🤝 Contributing

This project is designed to be educational and easily reproducible. Contributions that improve:

- **Check functionality on MacOS especially (please!)**
- **Documentation clarity**
- **Cross-platform compatibility**
- **New connection patterns**
- **Troubleshooting guides**

are especially welcome! You can write me in the repo or provide a PR. I am also on Clojure Slack (Stoating) and on the Clojure Camp (Stoating)

## 🙏 Acknowledgments

Special thanks to **Bruce Hauman** for creating the excellent [clojure-mcp](https://github.com/bhauman/clojure-mcp) library that makes seamless REPL integration and communication with Claude Desktop possible.

The configurations in this repository, especially the logging setup, general structure, and scripts, are inspired by the comprehensive guide in the [clojure-mcp wiki: Running MCP and nREPL server in a container](https://github.com/bhauman/clojure-mcp/wiki/Running-MCP-and-nREPL-server-in-a-container).

## Happy coding with Claude and Clojure! 🎉
