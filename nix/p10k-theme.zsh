# Find powerlevel10k installed via nix
local p10k_theme
for p10k_theme in \
  "${HOME}/.nix-profile/share/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme" \
  "${HOME}/opt/powerlevel10k/powerlevel10k.zsh-theme"
do
  if [[ -f "$p10k_theme" ]]; then
    source "$p10k_theme"
    return
  fi
done
echo "powerlevel10k not found. Run: nix profile add nixpkgs#zsh-powerlevel10k"
