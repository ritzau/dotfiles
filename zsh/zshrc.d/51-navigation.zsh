# Interactive ancestor navigation and cached Bazel target selection.
# Alt+U: choose a parent directory. Alt+B: insert a Bazel target.
# Run bazel-targets-refresh to update the target cache explicitly.

_dotfiles_workspace_root() {
  local dir="${PWD:A}"
  while [[ "$dir" != / ]]; do
    if [[ -f "$dir/MODULE.bazel" || -f "$dir/WORKSPACE" || -f "$dir/WORKSPACE.bazel" ]]; then
      print -r -- "$dir"
      return 0
    fi
    dir="${dir:h}"
  done
  [[ -f /MODULE.bazel || -f /WORKSPACE || -f /WORKSPACE.bazel ]] && print -r -- /
}

_dotfiles_ancestor_widget() {
  emulate -L zsh
  setopt localoptions pipefail
  local dir="${PWD:A}" name labels selection
  local -a entries
  # Use a tab-separated path field, hidden from fzf's search/display.
  while [[ "$dir" != / ]]; do
    dir="${dir:h}"
    name="${dir:t}"
    [[ "$dir" == / ]] && name=/
    labels=""
    [[ -e "$dir/.git" ]] && labels+=" [git]"
    [[ -f "$dir/MODULE.bazel" || -f "$dir/WORKSPACE" || -f "$dir/WORKSPACE.bazel" ]] && labels+=" [bazel]"
    [[ "$dir" == "${HOME:A}" ]] && labels+=" [home]"
    entries+=("$dir"$'\t'"$name$labels")
  done
  (( ${#entries} )) || return 0
  selection=$(printf '%s\n' "${entries[@]}" | fzf --no-sort --delimiter=$'\t' --with-nth=2 --prompt='Up > ' --height=~40% --reverse) || return 0
  local target="${selection%%$'\t'*}"
  [[ -d "$target" ]] && builtin cd -- "$target"
  zle reset-prompt
}
zle -N _dotfiles_ancestor_widget
bindkey '^[u' _dotfiles_ancestor_widget

_dotfiles_bazel_cache_file() {
  local root="$1"
  local key
  key=$(printf '%s' "$root" | sha256sum 2>/dev/null | cut -d' ' -f1)
  if [[ -z "$key" ]]; then
    key=$(printf '%s' "$root" | shasum -a 256 | cut -d' ' -f1)
  fi
  print -r -- "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/bazel-targets-$key"
}

bazel-targets-refresh() {
  emulate -L zsh
  local root cache tmp
  root=$(_dotfiles_workspace_root) || { print -u2 'Not in a Bazel workspace'; return 1; }
  command -v bazel >/dev/null || { print -u2 'bazel not found'; return 1; }
  cache=$(_dotfiles_bazel_cache_file "$root")
  mkdir -p -- "${cache:h}"
  tmp=$(mktemp "${cache}.XXXXXX") || return 1
  if (cd "$root" && command bazel query '//...' --output=label > "$tmp"); then
    LC_ALL=C sort -u "$tmp" > "$cache"
    rm -f "$tmp"
    print -r -- "Cached $(wc -l < "$cache" | tr -d ' ') targets in $cache"
  else
    rm -f "$tmp"
    print -u2 'Bazel query failed; existing cache preserved'
    return 1
  fi
}

_dotfiles_bazel_widget() {
  emulate -L zsh
  local root cache selection
  root=$(_dotfiles_workspace_root) || { zle -M 'Not in a Bazel workspace'; return 0; }
  cache=$(_dotfiles_bazel_cache_file "$root")
  if [[ ! -s "$cache" ]]; then
    zle -M 'No target cache; run bazel-targets-refresh first'
    return 0
  fi
  selection=$(fzf --no-sort --height=~50% --reverse --prompt='Bazel > ' < "$cache") || return 0
  [[ -n "$selection" ]] || return 0
  # Quote the inserted label using zsh's shell-quoting modifier.
  LBUFFER+="${(q)selection}"
  zle redisplay
}
zle -N _dotfiles_bazel_widget
bindkey '^[b' _dotfiles_bazel_widget
