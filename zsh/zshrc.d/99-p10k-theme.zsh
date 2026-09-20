# GITSTATUS_LOG_LEVEL=DEBUG
source "${ZDOTDIR_DOTFILES:?}/../nix/p10k-theme.zsh"

# To customize prompt, run `p10k configure` or edit p10k config.
[[ ! -f "${ZDOTDIR_DOTFILES:?}/../p10k/p10k.zsh" ]] || source "${ZDOTDIR_DOTFILES:?}/../p10k/p10k.zsh"

# p10k only shows the context segment (user@host) for root or SSH sessions.
# In a container the shell is neither - no SSH_* vars, and the `who` fallback
# has no utmp to read - so it would be blank. Show the container name instead,
# in a different color than the yellow used for SSH hosts.
# Set here rather than in p10k/p10k.zsh: that file is `p10k configure` output
# and unsets POWERLEVEL9K_* on load, so it has to come after it.
if [[ -n $INTUI_CONTAINER || -f /.dockerenv || -f /run/.containerenv ]]; then
  typeset -g POWERLEVEL9K_CONTEXT_DEFAULT_CONTENT_EXPANSION='%m'
  typeset -g POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND=4
fi
