#!/usr/bin/env bash
# Optional developer tools, including Neovim external dependencies.
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
if ! command -v mise >/dev/null 2>&1; then
  echo "Run ./install.sh first." >&2
  exit 1
fi
# Install from a separate manifest without adding these tools to the
# lightweight global mise configuration.
MISE_YES=1 mise install --config "$DOTFILES_DIR/mise/heavy.toml"
uv tool install basedpyright
for tool in clangd clang-format; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing $tool (install via system package manager, e.g. sudo apt install clangd clang-format)" >&2
  fi
done
echo "Optional developer tools installed. Restart your shell."
