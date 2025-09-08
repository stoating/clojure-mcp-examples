# Clojure MCP Connection Patterns

A comprehensive demonstration of different architectural patterns for connecting your LLM (especially Claude Desktop) with Clojure codebases using the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/). This project showcases multiple patterns for integrating Claude Desktop with Clojure development environments.

## 🎯 Project Overview

This repository demonstrates **four different connection patterns** for integrating Claude Desktop with Clojure development environments:

1. **Direct Connection** (`patterns/direct`) - Direct container connection without proxy
2. **Container Proxy** (`patterns/container-proxy`) - SSE proxy inside container
3. **Host Proxy** (`patterns/host-proxy`) - SSE proxy on host system
4. **VM Proxy** (`patterns/vm-proxy`) - VM-based setup with proxy inside VM

Each pattern provides a complete, reproducible development environment using containers and the powerful [clojure-mcp](https://github.com/bhauman/clojure-mcp) library for seamless REPL integration.

### 🔍 Focused Development with Selective Mounting

One particularly interesting aspect of this containerized approach is that you can not only mount a full project, but also break larger projects into smaller parts and mount only specific subsections. This allows you to provide reduced context to your LLM, keeping it focused on the current area of interest in your codebase rather than being overwhelmed by the entire project structure.

### 💡 Recommended Pattern: Container Proxy

Based on practical experience, running the SSE proxy inside the container (`patterns/container-proxy`) tends to provide the smoothest workflow. This approach keeps Claude's responsibility minimal - simply pointing Claude to a ready endpoint that's prepared for immediate interaction. The container handles all the complexity internally, presenting Claude with a clean, standardized HTTP/SSE interface.

### 🔗 Multiple Client Connections

The container proxy pattern supports **multiple simultaneous client connections** to the same REPL environment. All of these clients can run at the same time, communicating on the same port (7080) and using the same shared REPL inside the container:

- **Claude Desktop**: Generated with `claude-std` (Linux/macOS) or `claude-win` (Windows)
- **Claude Code**: Pre-configured in `.mcp.json`
- **GitHub Copilot Chat**: Generated with `copilot`
- **Codex in VSCode**: Generated with `codex-conf`
- **Codex CLI**: Generated with `codex-conf` (config placed in `.codex/config.toml`)

This multi-client architecture allows you to seamlessly switch between different AI assistants and development tools while maintaining a consistent development environment.

## 🚀 Three Command Startup

Get up and running with Claude + Clojure in just **three commands**:

### 1. Clone and Install Nix

```bash
git clone <repository-url> && cd clojure-mcp-examples && ./bootstrap/01-install-nix.sh
```

**⚠️ Important:** Close your terminal and open a new one after this step.

### 2. Install devenv and Enter Development Shell

```bash
./bootstrap/02-install-devenv.sh && devenv shell
```

This installs **devenv** and enters the development shell with all dependencies (Podman, Clojure, mcp-proxy, etc.).

### 3. Setup Everything and Start

```bash
# For Linux/macOS:
bridge && claude-std && start

# For Windows:
bridge && claude-win && start
```

This command chain:

- **`bridge`** - Generates the **MCP bridge script** for host-proxy pattern
- **`claude-std`/`claude-win`** - Creates your **Claude Desktop configuration** (platform-specific) and automatically copies it to your OS-specific Claude Desktop directory (with backup of existing config)
- **`start`** - **Starts all development containers** (container-proxy, host-proxy, direct patterns)

### 4. Final Step

**Restart Claude Desktop** (or use View → Reload) - you'll now have multiple Clojure MCP servers available!

### 5. Optional: Setup Additional AI Tools

```bash
# Setup GitHub Copilot Chat (creates .vscode/mcp.json)
copilot

# Setup Codex in VSCode and CLI (creates ~/.codex/config.toml)
codex-conf
```

These commands generate configurations for additional AI tools that can connect to the same running REPL environment.

---

## 📖 Detailed Setup (Step-by-step Approach)

### Prerequisites

- **Claude Desktop** (for MCP integration)

**Note**: The bootstrap scripts handle installation of **Nix** and **devenv**. After installing Nix, **close your terminal and open a new terminal** before installing devenv. Once you enter the devenv shell with `devenv shell`, all other dependencies (Podman, Clojure, mcp-proxy, etc.) are guaranteed to be present due to the Nix packaging system.

- For VM setup, you'll need a VM to be set up (You can use VirtualBox, VMware, or any other virtualization tool of your choice). I have an example setup here: [nixos - setup virtual machine dev env](https://youtu.be/8CXBBitdjBU)

### Step-by-Step Setup

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

6. **Generate MCP bridge script (for host-proxy pattern):**

   ```bash
   bridge
   ```

7. **Generate Claude Desktop configuration (choose one):**

   ```bash
   claude-std     # For Linux/macOS
   claude-win     # For Windows
   ```

8. **These commands will copy the generated `claude_desktop_config.json` to Claude Desktop's config directory:**
   - **Windows**: `%APPDATA%\Roaming\Claude\claude_desktop_config.json`
   - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Linux**: `~/.config/Claude/claude_desktop_config.json`

9. **Start the development environment:**

   ```bash
   start
   ```

10. **Restart Claude Desktop** to load the new MCP servers

## 🏗️ Architecture Patterns

This project demonstrates different architectural patterns for connecting Claude Desktop to Clojure development environments:

### Pattern 1: Direct Connection (`patterns/direct`)

``` bash
Claude Desktop → podman exec → Container (Clojure MCP)
```

- **Pros**: Simple, direct connection with minimal overhead
- **Cons**: Platform-specific commands in Claude config
- **Best for**: Simple setups, quick testing, local development

### Pattern 2: Container Proxy (`patterns/container-proxy`)

``` bash
Claude Desktop → mcp-proxy client → HTTP/SSE → Container (mcp-proxy server + Clojure MCP)
```

- **Pros**: Platform-agnostic HTTP communication, self-contained, supports multiple clients
- **Cons**: Slightly more complex container setup
- **Best for**: Cross-platform compatibility, production-like environments, multi-client development

### Pattern 3: Host Proxy (`patterns/host-proxy`)

``` bash
Claude Desktop → Bridge Script → mcp-proxy (host) → HTTP/SSE → Container (Clojure MCP)
```

- **Pros**: Proxy control on host if that's what you need
- **Cons**: Requires host-side proxy installation. Slow.
- **Best for**: Development environments where you want proxy control on the host

### Pattern 4: VM Proxy (`patterns/vm-proxy`)

``` bash
Claude Desktop → mcp-proxy client → HTTP/SSE → VM (mcp-proxy server + Clojure MCP)
```

- **Pros**: Better isolation, reproducible VM environments
- **Cons**: Higher resource usage, requires VM management, not as automatable
- **Best for**: Team environments, security-conscious setups

## 📁 Project Structure

``` bash
├── bootstrap/                # Installation scripts for Nix and devenv
│   ├── 01-install-nix.sh
│   └── 02-install-devenv.sh
├── bin/                      # Utility scripts
│   ├── claude.sh             # Generate Claude Desktop configs (Linux/macOS)
│   ├── claude-win.sh         # Generate Claude Desktop configs (Windows)
│   ├── copilot.sh            # Generate GitHub Copilot Chat config
│   ├── codex.sh              # Generate Codex configs
│   ├── copy-claude-config.sh # Copy Claude config to OS location with backup
│   ├── copy-copilot-config.sh # Copy Copilot config to .vscode/
│   ├── copy-codex-config.sh  # Copy Codex config to ~/.codex/
│   ├── gen-bridge.sh         # Generate MCP bridge scripts
│   ├── containers-*.sh       # Container management scripts
│   └── images-*.sh           # Image management scripts
├── devenv/                   # Top-level container for development
│   └── container/            # Container configuration
├── gen/                      # Generated configuration files
│   ├── claude_desktop_config.json # Generated Claude Desktop config
│   ├── config.toml           # Generated Codex config
│   └── mcp.json              # Generated Copilot config
├── patterns/                 # Four different connection patterns
│   ├── direct/               # Direct container connection (no proxy)
│   ├── container-proxy/      # Proxy inside container (recommended)
│   ├── host-proxy/           # Proxy on host system
│   └── vm-proxy/             # VM-based setup with proxy
├── .mcp.json                 # Claude Code configuration (pre-configured)
├── .codex/                   # Codex CLI configuration directory
│   └── config.toml           # Codex CLI configuration
├── devenv.nix                # Development environment configuration
└── deps.edn                  # Clojure dependencies and aliases
```

## 🛠️ Development Environment Features

### Reproducible Setup with devenv

- **Nix-based**: Ensures identical environments across machines without version conflicts (installed via bootstrap script)
- **Container Support**: Podman/Docker integration (available by default in devenv shell)
- **Python Tools**: Pre-configured `mcp-proxy` and dependencies (available by default in devenv shell)
- **Clojure Tools**: Complete Clojure development stack (available by default in devenv shell)
- **AI Tool Integration**: Claude Code (v1.0.94) and Codex (v0.29.0) pre-installed

### MCP Integration

- **clojure-mcp**: Direct REPL integration with Claude (v0.1.8-alpha)
- **Multi-pattern**: Four different connection architectures
- **Multi-client**: Supports Claude Desktop, Claude Code, GitHub Copilot, and Codex simultaneously
- **Cross-platform**: Windows (with WSL), macOS, and Linux support
- **Logging**: Comprehensive logging for debugging

### Container Features

- **Clojure 1.12.1**: Latest stable Clojure version
- **nREPL**: Interactive development server on port 7888
- **Volume Mounts**: Live code editing with isolation
- **Port Forwarding**: HTTP/SSE communication on port 7080
- **Multiple Patterns**: All patterns can run simultaneously

## 🎨 Example Usage

Once connected, you can interact with your Clojure codebase through any of the connected AI tools:

```clojure
;; Execute Clojure code in your development environment
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

The devenv shell provides convenient scripts for seamless setup:

### Setup Commands

- `bridge` - Generate MCP bridge configuration for host-proxy pattern
- `claude-std` - Generate Claude Desktop config (Linux/macOS) and copy to system location
- `claude-win` - Generate Claude Desktop config (Windows) and copy to system location
- `copilot` - Generate GitHub Copilot Chat config and copy to `.vscode/mcp.json`
- `codex-conf` - Generate Codex configs and copy to `~/.codex/config.toml`

### Environment Management

- `start` - Start all development containers (container-proxy, host-proxy, direct patterns)
- `stop` - Stop all running containers
- `remove` - Remove containers and images

### Advanced Commands

- `dev-*` - Development versions of the above commands (including high-level mcp development)
- `claude-*-vm` - Generate Claude Desktop config with VM support and copy to system location

### Pre-configured Files

- `.mcp.json` - Claude Code configuration (ready to use)
- `.codex/config.toml` - Codex CLI configuration (updated by `codex-conf`)

## 🧑‍💻 Multiple AI Tool Integration

This setup supports **simultaneous connections** from multiple AI development tools:

### Claude Desktop

Primary integration with comprehensive MCP server configuration including all patterns.

### Claude Code

Pre-configured via `.mcp.json` at the project root. Connects to the container-proxy on port 7080.

### GitHub Copilot Chat

Generate configuration with `copilot` command. Creates `.vscode/mcp.json` for VS Code integration.

### Codex (OpenAI)

- **VSCode Extension**: Configured via `codex-conf` command
- **CLI Tool**: Also configured via `codex-conf`, placed in `~/.codex/config.toml`

All tools connect to the same running Clojure REPL environment, allowing you to seamlessly switch between different AI assistants while maintaining consistent state.

## 🐛 Troubleshooting

### MCP Server Not Appearing in Claude Desktop

1. **Verify container status:**

   ```bash
   podman ps  # Check if containers are running
   ```

2. **Check Claude Desktop config:**
   - Ensure config file is in the correct location
   - Restart Claude Desktop after config changes
   - On Windows, stop Claude from Task Manager if needed (View → Reload is usually enough)

3. **Test MCP connection manually:**

   ```bash
   # Test container-based MCP
   podman exec -it clojure-mcp-container-proxy clojure -X:mcp

   # Test HTTP endpoint (for proxy patterns)
   curl http://localhost:7080/status
   ```

### Port Conflicts

If port 7080 is already in use:

```bash
# Find the process using port 7080
lsof -i :7080

# Kill the process
kill <PID>
```

### Container Issues

```bash
# Check container logs
podman logs clojure-mcp-container-proxy

# Restart containers
stop && start
```

### Multiple AI Tools Not Working

1. Ensure containers are running: `podman ps`
2. Test the SSE endpoint: `curl http://localhost:7080/sse`
3. Check tool-specific configuration files in `gen/` directory
4. Restart the respective AI tools after configuration changes

## 📚 Learning Resources

- **[Model Context Protocol](https://modelcontextprotocol.io/)** - Official MCP documentation
- **[clojure-mcp](https://github.com/bhauman/clojure-mcp)** - Clojure MCP implementation
- **[devenv](https://devenv.sh/)** - Development environment management
- **[Claude Desktop](https://claude.ai/desktop)** - AI assistant with MCP support
- **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** - Command line tool for agentic coding

## 🤝 Contributing

This project is designed to be educational and easily reproducible. Contributions that improve:

- **Cross-platform testing** (especially macOS)
- **Documentation clarity**
- **New connection patterns**
- **Additional AI tool integrations**
- **Troubleshooting guides**
- **Performance optimizations**

are especially welcome! Feel free to open issues or submit PRs. You can also reach me on Clojure Slack or Clojure Camp as @Stoating.

## 🙏 Acknowledgments

Special thanks to **Bruce Hauman** for creating the excellent [clojure-mcp](https://github.com/bhauman/clojure-mcp) library that makes seamless REPL integration and communication with Claude Desktop possible.

The configurations in this repository, especially the logging setup, general structure, and scripts, are inspired by the comprehensive guide in the [clojure-mcp wiki: Running MCP and nREPL server in a container](https://github.com/bhauman/clojure-mcp/wiki/Running-MCP-and-nREPL-server-in-a-container).

## Happy coding with Claude (or CoPilot or Codex) and Clojure! 🎉
