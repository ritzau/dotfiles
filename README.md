# dotfiles

Personal dotfiles managed with a simple install script. Tools come from
[mise](https://mise.jdx.dev) (each project's own release binaries, installed
as the user — no sudo), the shell is [zsh](https://www.zsh.org/).

## Structure

```
git/          Git configuration (delta, zdiff3, rebase workflow)
mise/         Basic tools (config.toml) and optional development tools (heavy.toml)
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
install-heavy.sh  Optional developer/Neovim tools installer
Brewfile      macOS system tools (zsh, tmux, htop, …)
```

## Installation

```sh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh -l

# Optional: Neovim, language servers, formatters, and developer tools
./install-heavy.sh
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
The optional `install-heavy.sh` combines the basic and heavy manifests into a generated user-local mise config so all tools are active in normal shells, and installs basedpyright via uv. Run `./check-nvim-tools.sh` to verify Neovim's external dependencies. Neovim uses blink.cmp, Ruff and basedpyright for Python, and language servers for Rust, Go and Lua. Treesitter parsers install on demand. On Ubuntu, install `clangd` and `clang-format` through apt if missing. The Neovim configuration also needs a C compiler to build Treesitter parsers. A second run updates the tools; neither script invokes sudo.

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
