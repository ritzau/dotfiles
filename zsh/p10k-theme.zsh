# powerlevel10k, wherever this machine has it: install.sh's clone first.
local p10k_theme
for p10k_theme in \
  "${HOME}/.local/share/powerlevel10k/powerlevel10k.zsh-theme" \
  "${HOMEBREW_PREFIX:-/opt/homebrew}/share/powerlevel10k/powerlevel10k.zsh-theme" \
  "/usr/local/share/powerlevel10k/powerlevel10k.zsh-theme" \
  "${HOME}/opt/powerlevel10k/powerlevel10k.zsh-theme"
do
  if [[ -f "$p10k_theme" ]]; then
    source "$p10k_theme"
    return
  fi
done
echo "powerlevel10k not found; run ~/dotfiles/install.sh"
