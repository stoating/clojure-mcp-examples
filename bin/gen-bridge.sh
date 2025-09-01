#!/usr/bin/env bash
set -euo pipefail

# Create necessary directories
mkdir -p "$(pwd)/patterns/host-proxy/gen/claude_desktop"

OUT="$(pwd)/patterns/host-proxy/gen/claude_desktop/clojure-mcp-bridge.sh"

HOST="127.0.0.1"
PORT="7081"
LOG_FILE="$(pwd)/patterns/host-proxy/.logs/mcp-sse.out"

# Resolve binaries (inside devenv or PATH)
CURL_BIN="$(command -v curl)"
MCP_PROXY_BIN="$(command -v mcp-proxy)"
PODMAN_BIN="$(command -v podman)"

# Write the bridge script
cat > "$OUT" <<SH
#!/usr/bin/env bash

HOST="${HOST}"
PORT="${PORT}"

CURL="${CURL_BIN}"
MCP_PROXY="${MCP_PROXY_BIN}"
PODMAN="${PODMAN_BIN}"

LOG_FILE="${LOG_FILE}"

# start SSE server (in background) that spawns MCP in the container
"\$MCP_PROXY" --host="\$HOST" --port="\$PORT" -- \\
  "\$PODMAN" exec -i -w "/usr/app" "clojure-mcp-host-proxy" clojure -X:mcp \\
  >> "\$LOG_FILE" 2>&1 &

# wait for server
for i in {1..50}; do
  "\$CURL" -fsS "http://\${HOST}:\${PORT}/status" >/dev/null && break || sleep 1
done

# run client-mode proxy (Claude talks to this via stdio)
exec "\$MCP_PROXY" "http://\${HOST}:\${PORT}/sse"
SH

chmod +x "$OUT"

echo "Wrote bridge script to: $OUT"
echo "  Host/Port : $HOST:$PORT"
echo "  Logs      : $LOG_FILE"
echo "  curl      : $CURL_BIN"
echo "  mcp-proxy : $MCP_PROXY_BIN"
echo "  podman    : $PODMAN_BIN"