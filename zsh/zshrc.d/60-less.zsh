# Use bat as pager for less if available (replaces source-highlight)
if (( $+commands[bat] )); then
  export LESSOPEN="| bat --color=always --plain %s"
  export LESS=' -R '
else
  local hilite
  for hilite in \
    /usr/local/opt/source-highlight/bin/src-hilite-lesspipe.sh \
    /usr/share/source-highlight/src-hilite-lesspipe.sh \
    /usr/bin/src-hilite-lesspipe.sh
  do
    if [[ -f "$hilite" ]]; then
      export LESSOPEN="| $hilite %s"
      export LESS=' -R '
      break
    fi
  done
fi

# Make less more friendly for non-text input files
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"
