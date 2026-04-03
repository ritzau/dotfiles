#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

info()    { printf '\033[1;34m[info]\033[0m %s\n' "$*"; }
warn()    { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
error()   { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }
fatal()   { printf '\033[1;31m[fatal]\033[0m %s\n' "$*" >&2; exit 1; }

ensure_source_line() {
  local src="$1" dst="$2" local_file="$3"
  local source_line="source \"$src\""
  local local_line="[[ -f \"$local_file\" ]] && source \"$local_file\""

  if [[ -f "$dst" ]] && grep -qF "$source_line" "$dst"; then
    info "Already sourced in $dst"
    return
  fi

  if [[ -f "$dst" ]]; then
    warn "Backing up $dst -> ${dst}.bak"
    cp "$dst" "${dst}.bak"
  fi

  cat > "$dst" <<EOF
$source_line

# Machine-local overrides (not tracked in dotfiles)
$local_line
EOF
  info "Wrote $dst"
}

link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    warn "Backing up $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -s "$src" "$dst"
  info "Linked $dst -> $src"
}

install_nix() {
  if command -v nix &>/dev/null; then
    info "Nix already installed"
    return
  fi
  info "Installing Nix (single-user)..."
  local nix_installer
  nix_installer=$(mktemp)
  curl -fsSL -o "$nix_installer" https://nixos.org/nix/install
  chmod +x "$nix_installer"
  # Always use single-user mode to avoid sudo and system-level changes
  sh "$nix_installer" --no-daemon 2>&1
  rm -f "$nix_installer"
  # Source nix in current shell so we can continue
  local nix_sh
  for nix_sh in \
    /etc/profile.d/nix.sh \
    /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
    "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
    if [[ -f "$nix_sh" ]]; then
      info "Sourcing $nix_sh"
      . "$nix_sh"
      break
    fi
  done
  # Hard fallback: add nix to PATH directly
  if ! command -v nix &>/dev/null; then
    export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
  fi
  if ! command -v nix &>/dev/null; then
    fatal "nix not found in PATH after install"
  fi

  # Enable flakes if not already configured
  local nix_conf_dir="$HOME/.config/nix"
  local nix_conf="$nix_conf_dir/nix.conf"
  if ! grep -qs 'experimental-features.*flakes' "$nix_conf" 2>/dev/null \
     && ! grep -qs 'experimental-features.*flakes' /etc/nix/nix.conf 2>/dev/null; then
    mkdir -p "$nix_conf_dir"
    echo "experimental-features = nix-command flakes" >> "$nix_conf"
    info "Enabled flakes in $nix_conf"
  fi
}

install_nix_packages() {
  info "Installing packages from flake..."
  if nix profile list 2>/dev/null | grep -q dotfiles-packages; then
    info "Upgrading existing dotfiles packages..."
    nix profile upgrade '.*dotfiles-packages.*'
  else
    nix profile add "$DOTFILES_DIR"
  fi
}


install_brew() {
  if ! command -v brew &>/dev/null; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [[ "$(uname -m)" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
  else
      eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_brew_packages() {
  info "Installing packages from flake..."
  brew bundle --file=Brewfile
}

info "Installing dotfiles from $DOTFILES_DIR"

if [[ "$(uname)" == "Darwin" ]]; then
  # 1. Brew package manager
  install_brew

  # 2. Packages
  install_brew_packages
else
  # 1. Nix package manager
  install_nix

  # 2. Packages
  install_nix_packages
fi

# 3. ZSH config (sourced, not symlinked)
info "Setting up shell config..."
ensure_source_line "$DOTFILES_DIR/zsh/zshenv"   "$HOME/.zshenv"   "$HOME/.zshenv.local"
ensure_source_line "$DOTFILES_DIR/zsh/zprofile"  "$HOME/.zprofile" "$HOME/.zprofile.local"
ensure_source_line "$DOTFILES_DIR/zsh/zshrc"     "$HOME/.zshrc"    "$HOME/.zshrc.local"

# 4. Git config (symlinked — gitconfig doesn't support sourcing)
link "$DOTFILES_DIR/git/config" "$HOME/.gitconfig"

# 5. Neovim config
info "Setting up Neovim config..."
mkdir -p "$HOME/.config/nvim"
link "$DOTFILES_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"

# 6. direnv config
info "Setting up direnv config..."
mkdir -p "$HOME/.config/direnv"
link "$DOTFILES_DIR/direnv/direnvrc" "$HOME/.config/direnv/direnvrc"

# 7. Optional: GitHub CLI auth + SSH key setup
setup_github() {
  if ! command -v gh &>/dev/null; then
    warn "gh not found, skipping GitHub setup"
    return
  fi

  if gh auth status &>/dev/null; then
    info "GitHub CLI already authenticated"
  else
    info "Authenticating with GitHub..."
    gh auth login
  fi

  local key="$HOME/.ssh/id_ed25519"
  if [[ -f "$key" ]]; then
    info "SSH key already exists: $key"
  else
    info "Generating SSH key..."
    ssh-keygen -t ed25519 -f "$key"
  fi

  if gh ssh-key list 2>/dev/null | grep -q "$(cat "${key}.pub" 2>/dev/null | awk '{print $2}')"; then
    info "SSH key already registered with GitHub"
  else
    info "Adding SSH key to GitHub..."
    gh ssh-key add "${key}.pub" --title "$(hostname) $(date +%Y-%m-%d)"
  fi
}

printf '\n'
read -rp "Set up GitHub CLI auth and SSH keys? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  setup_github
fi

info "Done. Run: exec zsh -l"
