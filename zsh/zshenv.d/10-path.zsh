# Keep basic user executables and mise's tools available in every shell,
# login or not: a non-interactive shell, such as Claude Code's, never runs
# `mise activate`'s prompt hook. The shims are a directory on PATH, so this
# stays fast. Interactive shells still activate mise in zshrc, which puts
# the tools themselves ahead of the shims.
typeset -U path
path=("$HOME/.local/bin" "$HOME/bin" "${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims" $path)
