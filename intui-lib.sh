#!/usr/bin/env bash
# intui-lib.sh — Shared helpers for intui-* scripts.
#
# Source this at the top of any intui script:
#   INTUI_LIB="$(cd "$(dirname "$0")" && pwd)/intui-lib.sh"
#   source "$INTUI_LIB"

set -euo pipefail

# --- Output ---

pass() { printf '\033[32m  ✓ %s\033[0m\n' "$*"; }
fail() { printf '\033[31m  ✗ %s\033[0m\n' "$*"; }
info() { printf '\033[34m  … %s\033[0m\n' "$*"; }
head() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# --- Checks ---

has_command() { command -v "$1" &>/dev/null; }

# --- Package install ---

install_pkg() {
  local cmd="$1"
  local pkg="${2:-$1}"

  if has_command "$cmd"; then
    return 0
  fi

  info "Installing $cmd..."
  if has_command apt-get; then
    sudo apt-get install -y "$pkg" >/dev/null 2>&1
  elif has_command brew; then
    brew install "$pkg" >/dev/null 2>&1
  else
    fail "Cannot install $cmd — no supported package manager"
    return 1
  fi

  has_command "$cmd"
}
