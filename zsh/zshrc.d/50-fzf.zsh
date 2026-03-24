# fzf - general-purpose command-line fuzzy finder
# https://github.com/junegunn/fzf

FZF_HOME=$(nix-store -r $(which fzf) 2>/dev/null)

if [[ -n "$FZF_HOME" ]]; then
  # Auto-completion (interactive shells only)
  [[ $- == *i* ]] && source "$FZF_HOME/share/fzf/completion.zsh" 2>/dev/null

  # Key bindings
  source "$FZF_HOME/share/fzf/key-bindings.zsh" 2>/dev/null
fi
