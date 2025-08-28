#!/usr/bin/env bash
set -euo pipefail

DEV="$1"

CONTAINER_NAMES=(
  clojure-mcp-proxy-in-cont
  clojure-mcp-proxy-in-host
  clojure-mcp-proxy-none
)

if [[ "$DEV" == "true" ]]; then
  CONTAINER_NAMES+=(clojure-mcp-examples)
fi

echo "Stopping known containers in parallel..."
pids=()
for name in "${CONTAINER_NAMES[@]}"; do
  if podman ps --format '{{.Names}}' | grep -qx "$name"; then
    echo " - stopping $name"
    podman stop --time=10 "$name" >/dev/null 2>&1 &   # run in background
    pids+=($!)
  else
    echo " - $name not running"
  fi
done

# wait for all stop operations to finish
for pid in "${pids[@]}"; do
  wait "$pid" || true
done

echo "Done."

for port in 7080 7081 7082 7083; do
  echo "Checking for process on port $port..."
  pid=""
  if command -v lsof >/dev/null 2>&1; then
    pid=$(lsof -ti tcp:$port || true)
  elif command -v fuser >/dev/null 2>&1; then
    pid=$(fuser ${port}/tcp 2>/dev/null || true)
  else
    echo "Neither lsof nor fuser found, cannot check port $port."
  fi

  if [ -n "${pid:-}" ]; then
    echo "Killing process(es) $pid on port $port..."
    kill -9 $pid || true
  else
    echo "No process found listening on port $port."
  fi
done

echo "Cleanup complete."