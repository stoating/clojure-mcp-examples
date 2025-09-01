#!/usr/bin/env bash

podman build -t clojure-mcp-container-proxy-image -f patterns/container-proxy/devenv/container/Containerfile .