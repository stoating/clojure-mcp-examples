# devenv.nix
{ pkgs, inputs, lib, ... }:

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

  # Environment vars you want in the shell
  env = {
    PODMAN_IGNORE_CGROUPSV1_WARNING = "1"; # Suppress warning about cgroup v1
    # Optional: set git identity for the shell; override via your own env if you like
    # GIT_AUTHOR_NAME = "Your Name";
    # GIT_AUTHOR_EMAIL = "you@example.com";
    # GIT_COMMITTER_NAME = "Your Name";
    # GIT_COMMITTER_EMAIL = "you@example.com";
  };

  # Tools available in PATH
  packages = with pkgs; [
    clojure
    bash
    curl
    git
    podman
    mcp-proxy
  ];

  # Simple Clojure setup
  languages.clojure.enable = true;

  # Nice-to-have: quick script runner example
  scripts = {
    "bridge".exec = "bash ./bin/gen-bridge.sh";
    "claude".exec = "bash ./bin/claude.sh false false";
    "claude-vm".exec = "bash ./bin/claude.sh true false";
    "claude-win".exec = "bash ./bin/claude-win.sh false false";
    "claude-win-vm".exec = "bash ./bin/claude-win.sh true false";
    "start".exec = "bash ./bin/containers-run.sh false";
    "stop".exec = "bash ./bin/containers-stop-clean.sh false";
    "remove".exec = "bash ./bin/images-kill-clean.sh false";
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
    echo "  claude     → Generate Claude config for macOS/Linux and copy to destination"
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
