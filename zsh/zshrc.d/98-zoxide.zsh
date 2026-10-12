# Initialize zoxide after completion and fzf.
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi
