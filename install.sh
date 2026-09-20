#!/usr/bin/env bash
# Set this machine up for me, as me — no sudo.  Tools come from mise
# (mise/config.toml, each project's own release binaries); configs are
# sourced or linked from this directory.  Re-runnable: a second run updates.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
export PATH="$BIN:$HOME/.local/share/mise/shims:$PATH"

info()    { printf '\033[1;34m[info]\033[0m %s\n' "$*"; }
warn()    { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }

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
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  info "Linked $dst -> $src"
}

# mise itself: one static binary from its GitHub release (mise.run does the
# same, from a host a network filter may not know).
install_mise() {
  if command -v mise >/dev/null 2>&1; then
    info "mise $(mise --version)"
    return
  fi
  local os arch tag
  case "$(uname -s)" in Darwin) os=macos ;; *) os=linux ;; esac
  case "$(uname -m)" in arm64|aarch64) arch=arm64 ;; *) arch=x64 ;; esac
  # Assets carry the version; /releases/latest redirects to its tag.
  tag=$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/jdx/mise/releases/latest)
  tag=${tag##*/}
  info "Installing mise $tag into $BIN..."
  mkdir -p "$BIN"
  curl -fsSL -o "$BIN/mise" "https://github.com/jdx/mise/releases/download/$tag/mise-$tag-$os-$arch"
  chmod +x "$BIN/mise"
}

install_tools() {
  link "$DOTFILES_DIR/mise/config.toml" "$HOME/.config/mise/config.toml"
  info "Installing tools (mise/config.toml)..."
  MISE_YES=1 mise install
  # gpustat is a Python package; only where there is a GPU to look at.
  if command -v nvidia-smi >/dev/null 2>&1; then
    uv tool install -q gpustat
  fi
}

# Pure zsh, so a clone is the install — the same on every machine.
install_p10k() {
  local dir="$HOME/.local/share/powerlevel10k"
  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" pull -q --ff-only || warn "powerlevel10k: could not update (offline?)"
  else
    info "Cloning powerlevel10k..."
    git clone -q --depth 1 https://github.com/romkatv/powerlevel10k.git "$dir"
  fi
}

# The machine's to install, not mine: the shell, tmux and curses tools
# without static builds.  Listed, never sudo'd.
check_system_tools() {
  local missing=() tool
  for tool in zsh tmux htop tig ncdu parallel; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
  done
  if (( ${#missing[@]} )); then
    warn "System tools missing: ${missing[*]}"
    warn "  Debian/Ubuntu: sudo apt install ${missing[*]}"
    warn "  macOS:         brew bundle --file=$DOTFILES_DIR/Brewfile"
  fi
}

info "Installing dotfiles from $DOTFILES_DIR"

# 1. Tools, as me
install_mise
install_tools
install_p10k
check_system_tools

# 2. ZSH config (sourced, not symlinked)
info "Setting up shell config..."
ensure_source_line "$DOTFILES_DIR/zsh/zshenv"   "$HOME/.zshenv"   "$HOME/.zshenv.local"
ensure_source_line "$DOTFILES_DIR/zsh/zprofile"  "$HOME/.zprofile" "$HOME/.zprofile.local"
ensure_source_line "$DOTFILES_DIR/zsh/zshrc"     "$HOME/.zshrc"    "$HOME/.zshrc.local"

# 3. Git config (symlinked — gitconfig doesn't support sourcing)
link "$DOTFILES_DIR/git/config" "$HOME/.gitconfig"

# 4. Neovim config
link "$DOTFILES_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"

# 5. tmux config
link "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

info "Done. Run: exec zsh -l"
