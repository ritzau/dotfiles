# Load the current directory's .envrc *before* the p10k instant prompt starts
# watching for output: the hook (80-direnv.zsh) would otherwise print
# "direnv: loading …" during startup and trip the instant-prompt check.
# p10k's documented recipe: export first, hook after the prompt.
(( $+commands[direnv] )) && emulate zsh -c "$(direnv export zsh)"
