# ALT-B - switch git branch via fzf
fzf-git-checkout-widget() {
  git rev-parse --git-dir > /dev/null 2>&1 || return 5

  local cmd="git branch -a --format='%(refname:short)'"
  setopt localoptions pipefail no_aliases 2> /dev/null
  local branch="$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse $FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" $(__fzfcmd) +m)"
  if [[ -z "$branch" ]]; then
    zle redisplay
    return 0
  fi
  git checkout "$branch"
  unset branch
  local ret=$?
  zle fzf-redraw-prompt
  return $ret
}
zle     -N    fzf-git-checkout-widget
bindkey '^[b' fzf-git-checkout-widget

# ALT-U - cd to git root or home
cd-up-widget() {
  local GIT_DIR
  GIT_DIR=$(git rev-parse --show-toplevel) && [[ $PWD != $GIT_DIR ]] && cd "$GIT_DIR" || cd "$HOME"
  zle fzf-redraw-prompt
  return 0
}
zle     -N    cd-up-widget
bindkey '^[u' cd-up-widget

# ALT-Arrow word movement
bindkey '\e[1;3D' backward-word
bindkey '\e[1;3C' forward-word

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
[[ -n ${key[Up]} ]] && bindkey "${key[Up]}" up-line-or-beginning-search
[[ -n ${key[Down]} ]] && bindkey "${key[Down]}" down-line-or-beginning-search
bindkey "^[OA" up-line-or-beginning-search
bindkey "^[OB" down-line-or-beginning-search

# Empty enter runs git status or ls
empty-line-status() {
  if [[ -z "$BUFFER" ]]; then
    BUFFER="git status 2>/dev/null || ls"
  fi
  zle .accept-line
}
zle -N accept-line empty-line-status
