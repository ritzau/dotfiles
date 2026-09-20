# mise's shims too, so non-interactive shells and programs spawned from the
# editor find the tools; interactive shells get the real bin dirs from
# zshrc.d/05-mise.zsh.
export PATH=~/.local/bin:~/bin:~/.local/share/mise/shims:$PATH
