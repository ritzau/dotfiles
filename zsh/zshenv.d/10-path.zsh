# Keep basic user executables available in every shell.
# mise shims are configured for login shells in zprofile.
typeset -U path
path=("$HOME/.local/bin" "$HOME/bin" $path)
