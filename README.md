# dotfiles

Personal dotfiles managed with a simple install script. Uses [Nix](https://nixos.org/) for package management and [zsh](https://www.zsh.org/) as the shell.

## Structure

```
git/          Git configuration (delta, zdiff3, rebase workflow)
nix/          Nix package list and p10k theme for Nix environments
nvim/         Neovim configuration (lazy.nvim, treesitter, fzf-lua)
p10k/         Powerlevel10k prompt configuration
tmux/         tmux configuration (mouse, truecolor)
zsh/
  zshenv.d/   Environment variables and PATH (sourced for all shells)
  zprofile.d/ Login shell setup (ssh-agent, home-manager)
  zshrc.d/    Interactive shell setup (aliases, completion, fzf, direnv, key bindings)
  completion/ Completions for bazel, delta, fd, just, rg, uv
  disabled/   Opt-in plugin configs (ghcup, volta)
install.sh    Installer script
```

## Installation

```sh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh -l
```

The install script will:

1. Install Nix (if not already present)
2. Install packages from `flake.nix`
3. Set up zsh config files (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`)
4. Symlink `git/config` to `~/.gitconfig`
5. Symlink Neovim config to `~/.config/nvim/init.lua`
6. Symlink `tmux/tmux.conf` to `~/.tmux.conf`

Existing files are backed up with a `.bak` suffix before being replaced.

## Local overrides

Machine-specific settings go in local files that are sourced automatically but not tracked:

- `~/.zshenv.local`
- `~/.zprofile.local`
- `~/.zshrc.local`
- `~/.gitconfig.local` (for user identity, signing keys, etc.)

Work-specific defaults for the git helpers in `zsh/zshrc.d/41-git.zsh` also
belong in `~/.zshrc.local`, e.g.

```sh
export GIT_STACK_TEST_CMD='bazel test //...'   # default for git-stack-test
export GIT_BASE_BRANCH=develop                 # only if origin/HEAD is wrong
```

## License

[BSD Zero Clause License](LICENSE)
