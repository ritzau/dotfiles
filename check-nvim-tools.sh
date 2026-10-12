#!/usr/bin/env bash
# Check executables required by the Neovim configuration.
set -uo pipefail
missing=0
for tool in nvim git rg fd fzf tree-sitter clangd clang-format basedpyright-langserver ruff gopls rust-analyzer lua-language-server yaml-language-server vscode-json-language-server shfmt yamlfmt biome buildifier cc; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf 'OK      %s\n' "$tool"
  else
    printf 'MISSING %s\n' "$tool"
    missing=1
  fi
done
exit "$missing"
