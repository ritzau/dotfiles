# The hook itself, installed after the instant prompt (see 00-direnv-export.zsh).
(( $+commands[direnv] )) && emulate zsh -c "$(direnv hook zsh)"
