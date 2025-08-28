#!/usr/bin/env bash

podman build -t clojure-mcp-proxy-in-cont-image -f examples/cont_proxy_in_cont/devenv/container/Containerfile .