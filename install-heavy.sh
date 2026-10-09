#!/usr/bin/env bash
# Install optional tools and activate them in the user's global mise config.
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
command -v mise >/dev/null || { echo "Run ./install.sh first." >&2; exit 1; }
command -v uv >/dev/null || { echo "Run ./install.sh first (uv missing)." >&2; exit 1; }

# Do not modify the tracked basic manifest. Generate a combined user config
# so optional tools are available to Neovim through normal mise shims.
mkdir -p "$HOME/.config/mise"
config="$HOME/.config/mise/config.toml"
if [[ -e "$config" && ! -L "$config" ]]; then
  cp "$config" "$config.bak"
fi
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
cat "$DOTFILES_DIR/mise/config.toml" > "$tmp"
printf '\n# Optional developer tools\n' >> "$tmp"
sed '/^\[tools\]/d' "$DOTFILES_DIR/mise/heavy.toml" >> "$tmp"
mv "$tmp" "$HOME/.config/mise/config-heavy.toml"
ln -sfn "$HOME/.config/mise/config-heavy.toml" "$config"
MISE_YES=1 mise install
uv tool install basedpyright
for tool in clangd clang-format cc; do
  command -v "$tool" >/dev/null || echo "Missing system tool: $tool (install with your package manager)" >&2
done
"$DOTFILES_DIR/check-nvim-tools.sh"
echo "Optional tools installed. Restart your shell."
