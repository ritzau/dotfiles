#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

ensure_source_line() {
  local src="$1" dst="$2" local_file="$3"
  local source_line="source \"$src\""
  local local_line="[[ -f \"$local_file\" ]] && source \"$local_file\""

  if [[ -f "$dst" ]] && grep -qF "$source_line" "$dst"; then
    echo "Already sourced in $dst"
    return
  fi

  if [[ -f "$dst" ]]; then
    echo "Backing up $dst -> ${dst}.bak"
    cp "$dst" "${dst}.bak"
  fi

  cat > "$dst" <<EOF
$source_line

# Machine-local overrides (not tracked in dotfiles)
$local_line
EOF
  echo "Wrote $dst"
}

link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    echo "Backing up $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -sv "$src" "$dst"
}

install_nix() {
  if command -v nix &>/dev/null; then
    echo "Nix already installed"
    return
  fi
  echo "Installing Nix..."
  local nix_installer
  nix_installer=$(mktemp)
  curl -L -o "$nix_installer" https://nixos.org/nix/install
  sh "$nix_installer" --daemon --yes
  rm -f "$nix_installer"
  # Source nix in current shell so we can continue
  . /etc/profile.d/nix.sh 2>/dev/null || true
}

install_packages() {
  local packages_file="$DOTFILES_DIR/nix/packages.txt"
  if [[ ! -f "$packages_file" ]]; then
    echo "No packages.txt found, skipping"
    return
  fi

  echo "Installing packages via nix profile..."

  # Snapshot installed packages once (strip ANSI codes)
  local installed
  installed=$(nix profile list 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | awk '/^Name:/{print $2}')

  local pkg
  while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    if echo "$installed" | grep -qx "$pkg"; then
      echo "  $pkg (already installed)"
    else
      echo "  $pkg (installing)"
      nix profile add "nixpkgs#$pkg"
    fi
  done < "$packages_file"
}

echo "Installing dotfiles from $DOTFILES_DIR"
echo ""

# 1. Nix package manager
install_nix

# 2. Packages
install_packages

# 3. ZSH config (sourced, not symlinked)
echo ""
echo "Setting up shell config..."
ensure_source_line "$DOTFILES_DIR/zsh/zshenv"   "$HOME/.zshenv"   "$HOME/.zshenv.local"
ensure_source_line "$DOTFILES_DIR/zsh/zprofile"  "$HOME/.zprofile" "$HOME/.zprofile.local"
ensure_source_line "$DOTFILES_DIR/zsh/zshrc"     "$HOME/.zshrc"    "$HOME/.zshrc.local"

# 4. Git config (symlinked — gitconfig doesn't support sourcing)
link "$DOTFILES_DIR/git/config" "$HOME/.gitconfig"

echo ""
echo "Done. Run: exec zsh -l"
