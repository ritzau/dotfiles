# dotfiles

Personal dotfiles managed with a simple install script. Tools come from
[mise](https://mise.jdx.dev) (each project's own release binaries, installed
as the user — no sudo), the shell is [zsh](https://www.zsh.org/).

## Structure

```
git/          Git configuration (delta, zdiff3, rebase workflow)
mise/         Basic tool configuration (config.toml)
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
Brewfile      macOS system tools (zsh, tmux, htop, …)
```

## Installation

```sh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh -l

# Optional: select profiles for this machine
mkdir -p ~/.config/dotfiles
cp packages.example.toml ~/.config/dotfiles/packages.toml
${EDITOR:-vi} ~/.config/dotfiles/packages.toml
just status
just install
just purge           # show removals and ask for confirmation
```

The install script will:

1. Install mise (one binary in `~/.local/bin`) and lightweight tools and Neovim in `mise/config.toml`
2. Clone powerlevel10k, `uv tool install gpustat` where there is a GPU
3. List missing system tools (zsh, tmux) — those
   are the machine's to install: `sudo apt install …`, or `brew bundle` on macOS
4. Set up zsh config files (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`)
5. Symlink `git/config` to `~/.gitconfig`
6. Symlink Neovim config to `~/.config/nvim/init.lua`
7. Symlink `tmux/tmux.conf` to `~/.tmux.conf`

Existing files are backed up with a `.bak` suffix before being replaced.
Optional tools are selected in `~/.config/dotfiles/packages.toml`, which is
machine-local and never committed. `just install` installs/repairs selected profiles;
`just status` previews changes. `just purge` shows removals and asks for confirmation; `just purge --yes`
skips confirmation for automation. Ownership is recorded in
`~/.local/state/dotfiles/packages.json`. Existing independently installed tools
are not adopted. Purge removes managed global selections, not shared mise
version files. Core tools remain in `mise/config.toml` and are not purged.

The reconciler requires Python 3.11+ (`tomllib`). Rust remains managed by
rustup and C/C++ tooling by the OS; these profiles currently install no tools.
Go, web, Lua, shell, Bazel, Python editor support, Tree-sitter, and CLI extras
are selectable. Language-specific tools installed outside mise (such as a
pre-existing `gopls`) are not removed. Run `just doctor` to check editor tools.

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
