# Use eza if available, fall back to ls
if (( $+commands[eza] )); then
  alias ls='eza'
  alias ll='eza -lF'
  alias la='eza -a'
  alias l='eza -F'
  alias tree='eza --tree'
else
  alias ll='ls -lF'
  alias la='ls -A'
  alias l='ls -CF'
fi

# Use bat if available
(( $+commands[bat] )) && alias cat='bat --plain'

# Clipboard (Linux; macOS has pbcopy/pbpaste built in)
if [[ "$OSTYPE" == linux* ]]; then
  alias pbcopy='xsel -ib'
  alias pbpaste='xsel -ob'
fi
