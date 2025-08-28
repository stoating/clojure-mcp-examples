#!/usr/bin/env bash

HOST="127.0.0.1"
PORT="7081"

CURL="/nix/store/z1l1b9bdzk6yspdf53z90n2dv311g1r6-curl-8.14.1-bin/bin/curl"
MCP_PROXY="/nix/store/lhnlbby7c5y6zjbzzi9mdpnin14xgmdh-mcp-proxy-0.8.2/bin/mcp-proxy"
PODMAN="/nix/store/imrfnidd75fd9pd2p1s1fyb1kn07x6mj-podman-5.5.2/bin/podman"

LOG_FILE="/home/zslade/projects/clojure-mcp-examples/examples/cont_proxy_in_host/.logs/mcp-sse.out"

# start SSE server (in background) that spawns MCP in the container
"$MCP_PROXY" --host="$HOST" --port="$PORT" -- \
  "$PODMAN" exec -i -w "/usr/app" "clojure-mcp-proxy-in-host" clojure -X:mcp \
  >> "$LOG_FILE" 2>&1 &

# wait for server
for i in {1..20}; do
  "$CURL" -fsS "http://${HOST}:${PORT}/status" >/dev/null && break || sleep 1
done

# run client-mode proxy (Claude talks to this via stdio)
exec "$MCP_PROXY" "http://${HOST}:${PORT}/sse"
