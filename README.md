# dotfiles

Personal dotfiles managed with a simple install script. Uses [Nix](https://nixos.org/) for package management and [zsh](https://www.zsh.org/) as the shell.

## Structure

```
git/          Git configuration (delta, zdiff3, rebase workflow)
nix/          Nix package list and p10k theme for Nix environments
p10k/         Powerlevel10k prompt configuration
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
2. Install packages from `nix/packages.txt`
3. Set up zsh config files (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`)
4. Symlink `git/config` to `~/.gitconfig`

Existing files are backed up with a `.bak` suffix before being replaced.

## Local overrides

Machine-specific settings go in local files that are sourced automatically but not tracked:

- `~/.zshenv.local`
- `~/.zprofile.local`
- `~/.zshrc.local`
- `~/.gitconfig.local` (for user identity, signing keys, etc.)

## License

[BSD Zero Clause License](LICENSE)
