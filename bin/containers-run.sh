#!/usr/bin/env bash
set -euo pipefail

DEV="$1"

podman pull docker.io/library/clojure:temurin-21-tools-deps

systemd-run --user --unit=build-cont-proxy-in-cont \
  --collect --same-dir --working-directory="$(pwd)" \
  bash -lc './examples/cont_proxy_in_cont/devenv/container/image-build.sh && \
            ./examples/cont_proxy_in_cont/devenv/container/run-container.sh'

sleep 1

systemd-run --user --unit=build-cont-proxy-in-host \
  --collect --same-dir --working-directory="$(pwd)" \
  bash -lc './examples/cont_proxy_in_host/devenv/container/image-build.sh && \
            ./examples/cont_proxy_in_host/devenv/container/run-container.sh'

sleep 1

systemd-run --user --unit=build-cont-proxy-none \
  --collect --same-dir --working-directory="$(pwd)" \
  bash -lc './examples/cont_proxy_none/devenv/container/image-build.sh && \
            ./examples/cont_proxy_none/devenv/container/run-container.sh'

sleep 1

if [[ "$DEV" == "true" ]]; then
  systemd-run --user --unit=build-cont-mcp-examples \
    --collect --same-dir --working-directory="$(pwd)" \
    bash -lc './devenv/container/image-build.sh && \
              ./devenv/container/run-container.sh'
fi