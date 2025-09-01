#!/usr/bin/env bash
set -euo pipefail

DEV="$1"

echo "Pulling base Clojure image..."
podman pull docker.io/library/clojure:temurin-21-tools-deps

echo ""
echo "Starting containers sequentially..."
echo "================================"

# Start container-proxy pattern
echo ""
echo "1. Building and starting container-proxy pattern..."
./patterns/container-proxy/devenv/container/image-build.sh
./patterns/container-proxy/devenv/container/run-container.sh &

sleep 2

# Start host-proxy pattern
echo ""
echo "2. Building and starting host-proxy pattern..."
./patterns/host-proxy/devenv/container/image-build.sh
./patterns/host-proxy/devenv/container/run-container.sh &

sleep 2

# Start direct pattern
echo ""
echo "3. Building and starting direct pattern..."
./patterns/direct/devenv/container/image-build.sh
./patterns/direct/devenv/container/run-container.sh &

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
