#!/usr/bin/env bash
# Deprecated: install only the language tooling you need.
set -euo pipefail
cat >&2 <<'EOF'
install-heavy.sh has been replaced by independent Just recipes.
Run 'just --list' to see available setup commands, for example:
  just setup-editor
  just setup-go-toolchain   # optional
  just setup-go             # gopls only
  just setup-python         # ruff + basedpyright, no Python install
  just setup-cpp            # check system clang tooling
EOF
exit 1
