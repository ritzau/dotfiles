# dotfiles

Personal dotfiles managed with a simple install script. Tools come from
[mise](https://mise.jdx.dev) (each project's own release binaries, installed
as the user — no sudo), the shell is [zsh](https://www.zsh.org/).

## Structure

```
git/          Git configuration (delta, zdiff3, rebase workflow)
mise/         Basic tools (config.toml); legacy heavy manifest (heavy.toml)
nvim/         Neovim configuration (lazy.nvim, treesitter, fzf-lua)
p10k/         Powerlevel10k prompt configuration
tmux/         tmux configuration (mouse, truecolor)
zsh/
  zshenv.d/   Environment variables and PATH (sourced for all shells)
  zprofile.d/ Login shell setup (ssh-agent)
  zshrc.d/    Interactive shell setup (mise, aliases, completion, fzf, direnv, key bindings)
  completion/ Completions for bazel, delta, fd, just, rg, uv
  disabled/   Opt-in plugin configs (ghcup, volta)
install.sh    Basic installer
justfile      Independent language/toolchain and editor setup recipes
install-heavy.sh  Deprecated; prints migration instructions
Brewfile      macOS system tools (zsh, tmux, htop, …)
```

## Installation

```sh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh -l

# Optional: choose only what you need
just --list
just setup-editor
just setup-go-toolchain  # optional, if Go is not already installed
just setup-go            # gopls
just setup-python        # Ruff and basedpyright; no Python installation
```

The install script will:

1. Install mise (one binary in `~/.local/bin`) and lightweight tools in `mise/config.toml`
2. Clone powerlevel10k, `uv tool install gpustat` where there is a GPU
3. List missing system tools (zsh, tmux, htop, tig, ncdu, parallel) — those
   are the machine's to install: `sudo apt install …`, or `brew bundle` on macOS
4. Set up zsh config files (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`)
5. Symlink `git/config` to `~/.gitconfig`
6. Symlink Neovim config to `~/.config/nvim/init.lua`
7. Symlink `tmux/tmux.conf` to `~/.tmux.conf`

Existing files are backed up with a `.bak` suffix before being replaced.
Optional developer setup is controlled by the root Justfile. Run `just --list` to see recipes. Toolchain recipes (`setup-go-toolchain`, `setup-rust-toolchain`, `setup-python-toolchain`, `setup-cpp-toolchain`, `setup-web-toolchain`, `setup-lua-toolchain`) are separate from support-tool recipes (`setup-go`, `setup-rust`, `setup-python`, `setup-cpp`, `setup-web`, `setup-lua`, `setup-shell`, `setup-bazel`). `setup-editor` installs Neovim and tree-sitter; `setup-cli` installs optional general CLI tools. `setup-cpp` checks system-provided clang tooling rather than installing a compiler. `setup-go` uses `go install` for gopls instead of the unsupported `ubi:golang/tools` release. Some recipes require system-provided prerequisites. Run `just check` to inspect missing Neovim dependencies. `install-heavy.sh` is deprecated and no longer installs anything.

## Local overrides

Machine-specific settings go in local files that are sourced automatically but not tracked:

- `~/.zshenv.local`
- `~/.zprofile.local`
- `~/.zshrc.local`
- `~/.gitconfig.local` (for user identity, signing keys, etc.)

The git helpers in `zsh/zshrc.d/41-git.zsh` infer their defaults from the
repo: the base branch from `origin/HEAD`, and the test command for
`git-stack-test` from the build system at the root (bazel, just, cargo, go,
npm, pytest). Override in `~/.zshrc.local` only when the inference is wrong:

```sh
export GIT_STACK_TEST_CMD='bazel test //foo/...'
export GIT_BASE_BRANCH=develop
```

## License

[BSD Zero Clause License](LICENSE)
