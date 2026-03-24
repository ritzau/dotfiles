fpath=(${ZDOTDIR:-$HOME/.dotfiles/zsh}/completion $fpath)
autoload -Uz compinit
compinit -u
