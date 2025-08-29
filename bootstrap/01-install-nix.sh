#!/usr/bin/env bash
set -euo pipefail

OS_TYPE="Unknown"

detect_os() {
    local uname_str
    uname_str="$(uname -s)"

    if [[ "$uname_str" == "Linux" ]]; then
        if grep -qi "microsoft" /proc/version 2>/dev/null || \
           grep -qi "WSL" /proc/sys/kernel/osrelease 2>/dev/null; then
            OS_TYPE="WSL"
        else
            OS_TYPE="Linux"
        fi
    elif [[ "$uname_str" == "Darwin" ]]; then
        OS_TYPE="macOS"
    fi
}

main() {
    detect_os
    echo "Detected OS: $OS_TYPE"

    if [[ "$OS_TYPE" == "Linux" ]]; then
        echo "Installing Nix for Linux..."
        sh <(curl -L https://nixos.org/nix/install) --daemon

    elif [[ "$OS_TYPE" == "macOS" ]]; then
        echo "Installing Nix for macOS..."
        curl -L https://github.com/NixOS/experimental-nix-installer/releases/download/0.27.0/nix-installer.sh | sh -s -- install

    elif [[ "$OS_TYPE" == "WSL" ]]; then
        echo "Installing Nix for WSL..."
        sh <(curl -L https://nixos.org/nix/install) --no-daemon

    else
        echo "Unsupported or unknown OS"
        exit 1
    fi
}

main "$@"
