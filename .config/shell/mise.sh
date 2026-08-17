# mise (replaces asdf) -- shims only.
#
# Sourced from .profile / .bash_profile / .zsh/mise.zsh, so it has to stay
# POSIX sh and has to be safe in a non-interactive shell.
#
# Shims rather than `mise activate` on purpose. `activate` installs a
# per-prompt hook that rewrites PATH on every cd, which is the right thing for
# an interactive zsh (see .zsh/mise.zsh) but wrong here: login shells, systemd
# units and scripts have no prompt to hook, so they need a PATH entry that
# simply resolves `ruby` and friends.
#
# Both dirs are checked because mise moved its data dir: distro packages use
# the XDG path, the curl installer and older versions used ~/.local/share/mise
# directly.

if command -v mise >/dev/null 2>&1; then
    for _mise_shims in \
        "${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims" \
        "$HOME/.local/share/mise/shims"
    do
        [ -d "$_mise_shims" ] || continue
        # Idempotent: .zprofile and .zshrc both pull this in.
        case ":$PATH:" in
            *":$_mise_shims:"*) ;;
            *) PATH="$_mise_shims:$PATH"; export PATH ;;
        esac
        break
    done
    unset _mise_shims
fi
