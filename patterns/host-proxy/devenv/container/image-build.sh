#!/usr/bin/env bash

podman build -t clojure-mcp-host-proxy-image -f patterns/host-proxy/devenv/container/Containerfile .