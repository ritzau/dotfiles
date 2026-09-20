# Puts the installed tools' bin dirs on PATH (and follows per-directory
# tool versions).  Before completion, so the tools' completions load.
(( $+commands[mise] )) && eval "$(mise activate zsh)"
