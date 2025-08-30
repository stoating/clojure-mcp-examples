#!/usr/bin/env bash
set -euo pipefail

DEV="$1"

echo "Pulling base Clojure image..."
podman pull docker.io/library/clojure:temurin-21-tools-deps

echo ""
echo "Starting containers sequentially..."
echo "================================"

# Start cont_proxy_in_cont
echo ""
echo "1. Building and starting clojure-mcp-proxy-in-cont..."
./examples/cont_proxy_in_cont/devenv/container/image-build.sh
./examples/cont_proxy_in_cont/devenv/container/run-container.sh &

sleep 2

# Start cont_proxy_in_host
echo ""
echo "2. Building and starting clojure-mcp-proxy-in-host..."
./examples/cont_proxy_in_host/devenv/container/image-build.sh
./examples/cont_proxy_in_host/devenv/container/run-container.sh &

sleep 2

# Start cont_proxy_none
echo ""
echo "3. Building and starting clojure-mcp-proxy-none..."
./examples/cont_proxy_none/devenv/container/image-build.sh
./examples/cont_proxy_none/devenv/container/run-container.sh &

sleep 2

# Start dev container if requested
if [[ "$DEV" == "true" ]]; then
  echo ""
  echo "4. Building and starting clojure-mcp-examples (dev mode)..."
  ./devenv/container/image-build.sh
  ./devenv/container/run-container.sh &
  sleep 2
fi

echo ""
echo "================================"
echo "All containers started!"
echo ""
echo "Container status:"
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "To check logs for a specific container:"
echo "  podman logs <container-name>"
echo ""
echo "To stop all containers:"
echo "  stop"
echo ""
