#!/usr/bin/env bash
set -e

nix-env --install --attr devenv -f https://github.com/NixOS/nixpkgs/tarball/nixpkgs-unstable

devenv --version || true