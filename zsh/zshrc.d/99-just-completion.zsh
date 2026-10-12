# Project-owned completion hints for just recipe arguments.
# Place immediately above a recipe:
#   # @complete target=file
#   # @complete target=dir
#   # @complete target=bazel-target
#   # @complete target=recipe
#   # @complete target=none
#   # @complete args=delegate:git
#   # @complete args=delegate:bazel build
#
# Delegation invokes the registered zsh completion for the named command.
# Hints are read from the nearest Justfile/justfile (not imported modules).
# Unannotated arguments complete files. Recipe names and just flags use
# just's existing completion function where available.

_dotfiles_just_hint() {
  emulate -L zsh
  local recipe="$1" param="$2" dir="$PWD" file="" line hint="" name
  while :; do
    if [[ -f "$dir/justfile" ]]; then file="$dir/justfile"; break; fi
    if [[ -f "$dir/Justfile" ]]; then file="$dir/Justfile"; break; fi
    [[ "$dir" == / ]] && break
    dir="${dir:h}"
  done
  [[ -n "$file" ]] || return 1
  # Only accept annotations directly attached to a matching recipe.
  awk -v recipe="$recipe" -v param="$param" '
    /^[[:space:]]*#[[:space:]]*@complete[[:space:]]/ {
      sub(/^[[:space:]]*#[[:space:]]*@complete[[:space:]]+/, "")
      split($0, a, "=")
      if (a[1] == param && length(a[2])) pending=substr($0,length(a[1])+2)
      next
    }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { pending=""; next }
    {
      if ($0 ~ "^[[:space:]]*" recipe "([[:space:]]|:)" && $0 ~ /:/) {
        if (pending != "") print pending
        exit
      }
      pending=""
    }
  ' "$file"
}

_dotfiles_just_complete() {
  local -a original_words delegate_words
  local original_current recipe param hint index
  # Delegate recipe names/options to the existing just completion.
  if (( CURRENT <= 2 )) || [[ "${words[CURRENT]}" == -* ]]; then
    if (( $+functions[_just] )); then _just; else _files; fi
    return
  fi
  recipe="${words[2]}"
  # Determine positional parameter name from the recipe header.
  local dir="$PWD" file="" header
  while :; do
    if [[ -f "$dir/justfile" ]]; then file="$dir/justfile"; break; fi
    if [[ -f "$dir/Justfile" ]]; then file="$dir/Justfile"; break; fi
    [[ "$dir" == / ]] && break
    dir="${dir:h}"
  done
  [[ -n "$file" ]] || { _files; return; }
  header=$(awk -v recipe="$recipe" '$0 ~ "^[[:space:]]*" recipe "([[:space:]]|:)" && $0 ~ /:/ {print; exit}' "$file")
  [[ -n "$header" ]] || { _files; return; }
  local params="${header#"$recipe"}"
  params="${params%%:*}"
  local -a fields
  fields=(${=params})
  index=$(( CURRENT - 2 ))
  param="${fields[index]}"
  # Variadic recipe parameters use *name or +name.
  if [[ -z "$param" && ${#fields} -gt 0 ]]; then
    local last="${fields[-1]}"
    [[ "$last" == [\*+]* ]] && param="$last"
  fi
  param="${param#[\*+]}"
  param="${param%%=*}"
  [[ -n "$param" ]] || { _files; return; }
  hint=$(_dotfiles_just_hint "$recipe" "$param")
  case "$hint" in
    dir) _files -/ ;;
    file|"") _files ;;
    bazel-target)
      local root cache
      root=$(_dotfiles_workspace_root) || return
      cache=$(_dotfiles_bazel_cache_file "$root")
      [[ -r "$cache" ]] && compadd -- "${(@f)$(<"$cache")}"
      ;;
    recipe)
      local -a recipes
      recipes=(${(@f)$(command just --summary 2>/dev/null)})
      compadd -- ${=recipes}
      ;;
    none) return ;;
    delegate:*)
      local spec="${hint#delegate:}"
      delegate_words=(${=spec})
      (( ${#delegate_words} )) || return
      # Preserve all recipe arguments up to the cursor as delegated arguments.
      original_words=("${words[@]}")
      original_current=$CURRENT
      words=("${delegate_words[@]}" "${original_words[@]:2}")
      CURRENT=$(( original_current - 2 + ${#delegate_words} ))
      _normal
      words=("${original_words[@]}")
      CURRENT=$original_current
      ;;
    *) _files ;;
  esac
}

# Load after the stock completion registration. Preserve _just as fallback.
if (( $+functions[compdef] )); then
  compdef _dotfiles_just_complete just
fi
