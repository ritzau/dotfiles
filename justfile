# Optional, independent developer setup. Run ./install.sh once first.
# Toolchains are opt-in; support recipes install editor/LSP tooling only.
set shell := ["bash", "-euo", "pipefail", "-c"]

# Prepare a writable global mise config without modifying tracked dotfiles.
_prepare-mise:
    @command -v mise >/dev/null || { echo "Run ./install.sh first" >&2; exit 1; }
    @mkdir -p "$HOME/.config/mise"
    @config="$HOME/.config/mise/config.toml"; if [ -L "$config" ]; then cp -L "$config" "$config.tmp"; mv "$config.tmp" "$config"; elif [ ! -f "$config" ]; then cp mise/config.toml "$config"; fi

# Install a set of mise-managed tools into the writable global config.
_mise *tools: _prepare-mise
    @mise use --global {{tools}}

# General CLI extras, independent of language tooling.
setup-cli:
    @just _mise 'bottom@latest' 'btop@latest' 'cloc@latest' 'dust@latest' 'eza@latest' 'fastfetch@latest' 'tealdeer@latest' 'yq@latest'

# Neovim and parser tooling (requires a system C compiler for parsers).
setup-editor:
    @just _mise 'neovim@latest' 'tree-sitter@latest'

# Go compiler/runtime, optional if Go already exists.
setup-go-toolchain:
    @just _mise 'go@latest'

# Go language server; requires a working Go toolchain.
setup-go:
    @command -v go >/dev/null || { echo "Go missing: run just setup-go-toolchain" >&2; exit 1; }
    @GOBIN="$HOME/.local/bin" go install golang.org/x/tools/gopls@latest

# Rust toolchain (rustup should own rustc/cargo).
setup-rust-toolchain:
    @command -v rustup >/dev/null || { echo "Install rustup using your OS package manager or rustup.rs" >&2; exit 1; }
    @rustup toolchain install stable
    @rustup default stable

# Rust editor support (via rustup when available, otherwise standalone).
setup-rust:
    @if command -v rustup >/dev/null; then rustup component add rust-analyzer; else just _mise 'ubi:rust-lang/rust-analyzer@latest'; fi

# Python runtime is intentionally not installed.
setup-python:
    @command -v uv >/dev/null || { echo "Run ./install.sh first (uv missing)" >&2; exit 1; }
    @uv tool install --upgrade ruff
    @uv tool install --upgrade basedpyright

# Optional managed Python runtime.
setup-python-toolchain:
    @uv python install

# C/C++ compiler and clang tooling are normally system-provided.
setup-cpp:
    @for tool in clangd clang-format; do command -v "$tool" >/dev/null || echo "Missing $tool: install with system package manager" >&2; done

setup-cpp-toolchain:
    @for tool in cc c++; do command -v "$tool" >/dev/null || echo "Missing $tool: install GCC or Clang with system package manager" >&2; done

# Lua editor support, no Lua runtime needed.
setup-lua:
    @just _mise 'ubi:LuaLS/lua-language-server@latest'

setup-lua-toolchain:
    @echo "Install Lua with your system package manager if required."

# Node is required for the npm-provided language servers.
setup-web-toolchain:
    @just _mise 'node@latest'

setup-web:
    @command -v npm >/dev/null || { echo "Node/npm missing: run just setup-web-toolchain" >&2; exit 1; }
    @just _mise 'npm:@biomejs/biome@latest' 'npm:yaml-language-server@latest' 'npm:vscode-langservers-extracted@latest'

setup-shell:
    @just _mise 'ubi:mvdan/sh@latest'
    @command -v shellcheck >/dev/null || echo "Optional: install shellcheck via system package manager"

setup-bazel:
    @just _mise 'buildifier@latest' 'ubi:google/yamlfmt@latest'

# Report optional dependencies; missing tools are not installation failures.
check:
    @./check-nvim-tools.sh
