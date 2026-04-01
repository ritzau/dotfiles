# Emacs mode
bindkey -e

# ALT-B - switch git branch via fzf
fzf-git-checkout-widget() {
  git rev-parse --git-dir > /dev/null 2>&1 || return 5

  setopt localoptions pipefail no_aliases 2> /dev/null
  local branch="$(git branch -a --format='%(refname:short)' \
    | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" $(__fzfcmd) +m)"
  if [[ -z "$branch" ]]; then
    zle redisplay
    return 0
  fi
  # Strip origin/ prefix so remote branches get a local tracking branch
  branch="${branch#origin/}"
  git switch "$branch"
  local ret=$?
  zle reset-prompt
  return $ret
}
zle     -N    fzf-git-checkout-widget
bindkey '^[b' fzf-git-checkout-widget

# ALT-U - fzf pick an ancestor directory to cd into
cd-up-widget() {
  setopt localoptions pipefail no_aliases 2> /dev/null
  local dirs=() d="$PWD"
  while [[ "$d" != "/" ]]; do
    d="${d:h}"
    dirs+=("$d")
  done
  local target="$(printf '%s\n' "${dirs[@]}" \
    | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS" $(__fzfcmd) +m)"
  if [[ -n "$target" ]]; then
    cd "$target"
  fi
  zle reset-prompt
  return 0
}
zle     -N    cd-up-widget
bindkey '^[u' cd-up-widget

# Alt-Arrow word navigation
bindkey '\e[1;3D' backward-word
bindkey '\e[1;3C' forward-word

# Word deletion (Ctrl-Backspace, Ctrl-Delete)
bindkey '^H'      backward-delete-word
bindkey '\e[3;5~' delete-word

# Up/Down prefix search
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

KEYBIND_DEFS=~/.zkbd/$TERM-${${DISPLAY:t}:-$VENDOR-$OSTYPE}
if [[ -f "$KEYBIND_DEFS" ]]; then
  source "$KEYBIND_DEFS"
elif [[ -z "$__ZKBD_WARNING_SHOWN" ]]; then
  echo "zkbd: no key definitions for $TERM. Run: autoload zkbd && zkbd"
  export __ZKBD_WARNING_SHOWN=1
fi
[[ -n ${key[Up]} ]]     && bindkey "${key[Up]}"     up-line-or-beginning-search
[[ -n ${key[Down]} ]]   && bindkey "${key[Down]}"   down-line-or-beginning-search
[[ -n ${key[Home]} ]]   && bindkey "${key[Home]}"   beginning-of-line
[[ -n ${key[End]} ]]    && bindkey "${key[End]}"     end-of-line
[[ -n ${key[Delete]} ]] && bindkey "${key[Delete]}" delete-char
[[ -n ${key[Insert]} ]] && bindkey "${key[Insert]}" overwrite-mode

# Empty enter runs git status or ls
empty-line-status() {
  if [[ -z "$BUFFER" ]]; then
    BUFFER="git status 2>/dev/null || ls"
  fi
  zle .accept-line
}
zle -N accept-line empty-line-status
