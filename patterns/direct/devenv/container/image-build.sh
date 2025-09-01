#!/usr/bin/env bash

podman build -t clojure-mcp-proxy-none-image -f examples/cont_proxy_none/devenv/container/Containerfile .