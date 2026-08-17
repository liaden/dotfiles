# Point the shell at the socket-activated ssh-agent.
#
# POSIX sh -- sourced from .bash_profile and .zshrc, and has to be safe in a
# non-interactive shell.
#
# systemd (Arch: openssh's ssh-agent.socket, enabled with
# `systemctl --user enable --now ssh-agent.socket`) creates the socket lazily
# and starts the agent on first connect, so there is nothing to spawn here and
# no PID to track -- one agent per login session, surviving individual shells.
# That is the whole reason not to do the classic `eval $(ssh-agent)` dance in
# an rc file, which leaks a new agent process per terminal.
#
# An already-set SSH_AUTH_SOCK always wins: inside an ssh session with agent
# forwarding, or on the mac where launchd provides its own agent, the value is
# already correct and overwriting it would break forwarding.
#
# ~/.ssh/config carries `AddKeysToAgent yes`, so the key loads itself on first
# use and prompts for its passphrase exactly once per login.

if [ -z "${SSH_AUTH_SOCK:-}" ] && [ -n "${XDG_RUNTIME_DIR:-}" ]; then
    if [ -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]; then
        SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
        export SSH_AUTH_SOCK
    fi
fi
