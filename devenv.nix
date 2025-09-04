# devenv.nix
{ pkgs, inputs, lib, config, ... }:

let
  py = pkgs.python312Packages;

  # Pin mcp to 1.13.1
  mcp = py.mcp.overridePythonAttrs (old: rec {
    version = "1.13.1";
    src = pkgs.fetchPypi {
      inherit (old) pname;
      inherit version;
      # nix-prefetch-url --unpack https://pypi.io/packages/source/m/mcp/mcp-1.13.1.tar.gz
      # nix hash convert --hash-algo sha256 --to sri xxx
      sha256 = "sha256-FlMGqP15kdyAM07dLeB3mBdaVkYQQ7eukHsnl5SoNMU=";
    };
  });

  # Build mcp-proxy from GitHub (rev 1e5091d) with uvicorn + mcp
  mcp-proxy = py.buildPythonApplication rec {
    pname = "mcp-proxy";
    version = "0.8.2";

    src = pkgs.fetchFromGitHub {
      owner = "sparfenyuk";
      repo = "mcp-proxy";
      rev = "1e5091d";
      # nix-prefetch-url --unpack https://github.com/sparfenyuk/mcp-proxy/archive/1e5091d.tar.gz
      # nix hash convert --hash-algo sha256 --to sri xxx
      sha256 = "sha256-3hNpUOWbyOUjLcvfcMzj4+xHyUl7k1ZSy8muWHvSEvM=";
    };

    format = "pyproject";
    nativeBuildInputs = with py; [ setuptools wheel ];
    propagatedBuildInputs = with py; [ mcp uvicorn ];
  };
in {

  name = "clojure-mcp-examples";

  # Override specific packages
  overlays = [
    (final: prev: {
      # Bump claude-code from 1.0.65 -> 1.0.94 using npm tarball
      # NPM tarball: https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-1.0.94.tgz
      claude-code = prev.claude-code.overrideAttrs (old: let
        version = "1.0.94";
      in rec {
        inherit version;
        src = prev.fetchurl {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          # nix-prefetch-url --unpack https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-1.0.94.tgz
          # devenv shell
          # error: hash mismatch in fixed-output derivation '/nix/store/bv2ljxnhrdb6yk9wwwpnmcf5plbd9yfh-claude-code-1.0.94.tgz.drv':
          # specified: sha256-TAGs9elamISvxeEH02w+TU+B7HTYtnWBqukTiSpikeU=
          #    got:    sha256-Hvp+fKWUP20ZeZDlNXwV+Re6qIQtnY0LwbhfJRRL99o=
          sha256 = "sha256-Hvp+fKWUP20ZeZDlNXwV+Re6qIQtnY0LwbhfJRRL99o=";
        };
      });

      # Define codex (Node CLI) 0.29.0 from the NPM tarball
      codex = prev.stdenv.mkDerivation (finalAttrs: rec {
        pname = "codex";
        version = "0.29.0";

        src = prev.fetchurl {
          url = "https://registry.npmjs.org/@openai/codex/-/codex-${version}.tgz";
          # Build once to get the correct SRI (will print "got: sha256-...")
          sha256 = "sha256-ZK9x+D1j3KGexQPQMXoXtOmmGYIOL2s8jzmyDJIccUY=";
        };

        nativeBuildInputs = [
          prev.nodejs_22
          prev.makeBinaryWrapper
          prev.installShellFiles
        ];

        # NPM tarballs unpack into a "package" directory and set that as CWD
        # From https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/by-name/co/codex/package.nix#L75
        installPhase = ''
          runHook preInstall

          dest=$out/lib/node_modules/@openai/codex
          mkdir -p "$dest"
          # Copy the whole packaged module contents (we are already in ./package)
          shopt -s dotglob nullglob
          cp -r ./* "$dest"

          mkdir -p $out/bin
          makeBinaryWrapper ${prev.nodejs_22}/bin/node $out/bin/codex --add-flags "$dest/bin/codex.js"

          ${prev.lib.optionalString (prev.stdenv.buildPlatform.canExecute prev.stdenv.hostPlatform) ''
            $out/bin/codex completion bash > codex.bash
            $out/bin/codex completion zsh > codex.zsh
            $out/bin/codex completion fish > codex.fish
            installShellCompletion codex.{bash,zsh,fish}
          ''}

          runHook postInstall
        '';

      });
    })
  ];

  # Environment vars you want in the shell
  env = {
    PODMAN_IGNORE_CGROUPSV1_WARNING = "1"; # Suppress warning about cgroup v1
    # Optional: set git identity for the shell; override via your own env if you like
    # GIT_AUTHOR_NAME = "Your Name";
    # GIT_AUTHOR_EMAIL = "you@example.com";
    # GIT_COMMITTER_NAME = "Your Name";
    # GIT_COMMITTER_EMAIL = "you@example.com";
    # Point Codex to the live repo path (writable), not the Nix store copy
    CODEX_HOME = "${config.devenv.root}/.codex";
  };

  # Tools available in PATH
  packages = with pkgs; [
    clojure
    bash
    curl
    git
    podman
    ripgrep
    claude-code
    codex
    mcp-proxy
  ];

  # Simple Clojure setup
  languages.clojure.enable = true;

  # Nice-to-have: quick script runner example
  scripts = {
    # one-time generation scripts for claude-desktop
    "claude-std".exec = "bash ./bin/claude.sh false false";
    "claude-std-vm".exec = "bash ./bin/claude.sh true false";
    "claude-win".exec = "bash ./bin/claude-win.sh false false";
    "claude-win-vm".exec = "bash ./bin/claude-win.sh true false";

    # one-time generation scripts for non-claude tools
    "copilot".exec = "bash ./bin/copilot.sh";
    "codex-conf".exec = "bash ./bin/codex.sh";

    # host-proxy
    "bridge".exec = "bash ./bin/gen-bridge.sh";

    "start".exec = "bash ./bin/containers-run.sh false";
    "stop".exec = "bash ./bin/containers-stop-clean.sh false";
    "remove".exec = "bash ./bin/images-kill-clean.sh false";

    # additional dev scripts for top-level repo management
    "dev-claude-vm".exec = "bash ./bin/claude.sh true true";
    "dev-claude-win-vm".exec = "bash ./bin/claude-win.sh true true";
    "dev-start".exec = "bash ./bin/containers-run.sh true";
    "dev-stop".exec = "bash ./bin/containers-stop-clean.sh true";
    "dev-remove".exec = "bash ./bin/images-kill-clean.sh true";
  };

  processes = {
    startup.exec = "echo Starting up...";
  };

  # Run on shell entry
  enterShell = ''
    echo ""
    echo "✨ Welcome to clojure-mcp-examples ✨"
    echo ""
    echo "You can run the following commands from the project root:"
    echo "---------------------------------------------------------"
    echo "🔧 One-time setup for Claude Desktop (bridge and a claude):"
    echo "  bridge     → Generate MCP Bridge config for Claude"
    echo "  claude-std → Generate Claude config for macOS/Linux and copy to destination"
    echo "  claude-win → Generate Claude config for Windows and copy to destination"
    echo ""
    echo "🛠  Development environment management:"
    echo "  start      → Start the development environment"
    echo "  stop       → Stop the development environment"
    echo "  remove     → Remove all containers and images"
    echo "---------------------------------------------------------"
  '';

  # Example task you can trigger with: devenv tasks run mcp-proxy:help
  tasks = {
    "mcp-proxy:help".exec = "mcp-proxy --help";
  };

  # Turn off Cachix unless you use it
  cachix.enable = false;
}
