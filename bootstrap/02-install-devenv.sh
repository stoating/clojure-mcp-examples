#!/usr/bin/env bash
set -euo pipefail

# Ensure Nix profile is sourced for non-interactive shells so `nix-env` is on PATH.
# Interactive shells often source this from ~/.bashrc; scripts do not, so we source
# the common locations used by single-user and multi-user Nix installations.
if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
	# shellcheck source=/dev/null
	. "$HOME/.nix-profile/etc/profile.d/nix.sh"
elif [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
	# shellcheck source=/dev/null
	. "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
fi

if ! command -v nix-env >/dev/null 2>&1; then
	echo "Error: nix-env not found in PATH. Try opening a new terminal or run: . ~/.nix-profile/etc/profile.d/nix.sh" >&2
	exit 1
fi

nix-env --install --attr devenv -f https://github.com/NixOS/nixpkgs/tarball/nixpkgs-unstable

devenv --version || true