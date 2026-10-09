#!/usr/bin/env bash
# Optional developer tools, including all Neovim external dependencies.
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

if ! command -v mise >/dev/null 2>&1; then
  printf 'Run ./install.sh first to install mise and basic tools.\n' >&2
  exit 1
fi

# Keep the basic global config in place; install optional tools explicitly
# from the separate manifest without making them global requirements.
tools=()
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*([^#[:space:]]+)[[:space:]]*=[[:space:]]*"([^"]+)" ]]; then
    name="${BASH_REMATCH[1]}"
    name="${name#\"}"
    name="${name%\"}"
    tools+=("${name}@${BASH_REMATCH[2]}")
  fi
done < "$DOTFILES_DIR/mise/heavy.toml"
MISE_YES=1 mise install "${tools[@]}"

# pylsp is distributed as a Python application.
uv tool install python-lsp-server

# External commands used by Neovim that need to be visible to Neovim:
# clangd, clang-format, tree-sitter, ruff, shfmt, yamlfmt, biome,
# buildifier, yaml-language-server, vscode-json-language-server.
printf 'Optional developer tools installed. Restart your shell.\n'
