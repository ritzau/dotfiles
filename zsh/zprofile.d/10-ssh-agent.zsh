# SSH agent setup.
#
# Pick the best agent that is already available instead of blindly starting
# our own (which would shadow the real one with an empty agent). Candidates,
# in order of preference:
#   1. whatever SSH_AUTH_SOCK already points at (forwarded via `ssh -A`,
#      macOS launchd agent, 1Password, ...)
#   2. the desktop session's agent (GNOME keyring / gcr-ssh-agent, or a
#      systemd user ssh-agent) - useful for ssh/tty logins into a workstation
#   3. the agent we started earlier on this host (persisted in the cfg file)
# An agent that has identities loaded beats one that is merely running, so a
# stale, empty socket inherited from e.g. an old tmux server does not win over
# the keyring agent that actually holds the keys. Only if nothing usable is
# found do we start (and persist) a fresh agent.

if command -v ssh-agent &>/dev/null && command -v ssh-add &>/dev/null; then
  _ssh_agent_cfg="$HOME/.ssh/agent-cfg-$HOST.sh"

  # Exit status: 0 = agent with identities, 1 = agent without, 2 = unusable.
  _ssh_agent_status() {
    [[ -n $1 && -S $1 ]] || return 2
    SSH_AUTH_SOCK=$1 ssh-add -l &>/dev/null
  }

  _ssh_agent_persisted_sock=
  if [[ -f $_ssh_agent_cfg ]]; then
    _ssh_agent_persisted_sock=$(. "$_ssh_agent_cfg" 2>/dev/null; print -r -- "$SSH_AUTH_SOCK")
  fi

  _ssh_agent_cands=(
    "$SSH_AUTH_SOCK"
    "${XDG_RUNTIME_DIR:+$XDG_RUNTIME_DIR/keyring/ssh}"
    "${XDG_RUNTIME_DIR:+$XDG_RUNTIME_DIR/gcr/ssh}"
    "${XDG_RUNTIME_DIR:+$XDG_RUNTIME_DIR/ssh-agent.socket}"
    "$_ssh_agent_persisted_sock"
  )

  typeset -A _ssh_agent_st
  for _s in "${_ssh_agent_cands[@]}"; do
    [[ -n $_s && -z ${_ssh_agent_st[$_s]} ]] || continue
    _ssh_agent_status "$_s"
    _ssh_agent_st[$_s]=$?
  done

  _ssh_agent_pick=
  for _want in 0 1; do
    for _s in "${_ssh_agent_cands[@]}"; do
      if [[ -n $_s ]] && (( _ssh_agent_st[$_s] == _want )); then
        _ssh_agent_pick=$_s
        break 2
      fi
    done
  done

  if [[ -z $_ssh_agent_pick ]]; then
    mkdir -p "${_ssh_agent_cfg:h}"
    ssh-agent | sed '/^echo/d' > "$_ssh_agent_cfg"
    chmod 600 "$_ssh_agent_cfg"
    . "$_ssh_agent_cfg"
  elif [[ $_ssh_agent_pick == $_ssh_agent_persisted_sock ]]; then
    . "$_ssh_agent_cfg"   # also restores SSH_AGENT_PID
  else
    export SSH_AUTH_SOCK=$_ssh_agent_pick
    unset SSH_AGENT_PID
  fi

  unfunction _ssh_agent_status
  unset _ssh_agent_cfg _ssh_agent_persisted_sock _ssh_agent_cands _ssh_agent_st _ssh_agent_pick _s _want
fi
