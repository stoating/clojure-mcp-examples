#!/usr/bin/env bash
set -euo pipefail

VM="$1"
DEV="$2"

OUT="claude_desktop_config.json"

# Resolve nix-store binaries (inside devenv)
MCP_PROXY="$(command -v mcp-proxy)"
PODMAN="$(command -v podman)"
BASH_BIN="$(command -v bash)"

# Bridge path relative to project root (we assume script runs from project root)
BRIDGE_PATH="$(pwd)/examples/cont_proxy_in_host/gen/claude_desktop/clojure-mcp-bridge.sh"

# Define JSON snippets for each server
server_in_cont=$(cat <<JSON
    "clojure-mcp-proxy-in-cont": {
      "command": "${BASH_BIN}",
      "args": [
        "-c",
        "${MCP_PROXY} http://localhost:7080/sse"
      ]
    }
JSON
)

server_examples=$(cat <<JSON
    "clojure-mcp-examples": {
      "command": "${BASH_BIN}",
      "args": [
        "-c",
        "${MCP_PROXY} http://localhost:7083/sse"
      ]
    }
JSON
)

server_none=$(cat <<JSON
    "clojure-mcp-proxy-none": {
      "command": "${BASH_BIN}",
      "args": [
        "-c",
        "exec ${PODMAN} exec -i -w /usr/app clojure-mcp-proxy-none clojure -X:mcp"
      ]
    }
JSON
)

server_vm=$(cat <<JSON
    "clojure-mcp-vm-proxy-in-vm": {
      "command": "${BASH_BIN}",
      "args": [
        "-c",
        "${MCP_PROXY} http://localhost:7082/sse"
      ]
    }
JSON
)

server_in_host=$(cat <<JSON
    "clojure-mcp-proxy-in-host": {
      "command": "${BASH_BIN}",
      "args": [
        "-c",
        "${BRIDGE_PATH}"
      ]
    }
JSON
)

# Collect servers in desired order:
# 1) in-cont, 2) examples (if DEV), 3) none, 4) vm (if VM), 5) in-host (last)
servers="$server_in_cont"

if [[ "$DEV" == "true" ]]; then
  servers="$servers,
$server_examples"
fi

servers="$servers,
$server_none"

if [[ "$VM" == "true" ]]; then
  servers="$servers,
$server_vm"
fi

servers="$servers,
$server_in_host"

# Write final JSON
cat > "$OUT" <<JSON
{
  "mcpServers": {
$servers
  }
}
JSON

echo "Wrote Claude Desktop config to $OUT"
echo "  mcp-proxy : $MCP_PROXY"
echo "  podman    : $PODMAN"
echo "  bridge    : $BRIDGE_PATH"
echo "  vm section: $VM"
echo "  dev mode  : $DEV"

# Copy config to OS-specific location
echo "Copy config to destination..."
bash ./bin/copy-claude-config.sh
