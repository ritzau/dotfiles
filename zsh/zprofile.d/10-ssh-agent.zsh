SSH_AGENT_CFG="$HOME/.ssh/agent-cfg-$HOST.sh"

if command -v ssh-agent &>/dev/null; then
  start_ssh_agent() {
    mkdir -p "${SSH_AGENT_CFG:h}"
    ssh-agent | sed '/^echo/d' > "$SSH_AGENT_CFG"
    chmod 600 "$SSH_AGENT_CFG"
    . "$SSH_AGENT_CFG"
  }

  if [[ -f $SSH_AGENT_CFG ]]; then
    . "$SSH_AGENT_CFG"
    # Use kill -0 instead of grepping ps output
    if ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
      start_ssh_agent
    fi
  else
    start_ssh_agent
  fi

  unfunction start_ssh_agent
fi
