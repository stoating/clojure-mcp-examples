#!/usr/bin/env bash

podman build -t clojure-mcp-proxy-in-host-image -f examples/cont_proxy_in_host/devenv/container/Containerfile .