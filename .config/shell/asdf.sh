# Locate asdf by binary rather than by package prefix, so this holds on a
# distro package, linuxbrew, and both Homebrew arches without a branch each.
#
# 0.16+ is a Go rewrite with no shell entrypoint: the binary comes from the
# package manager and only the shims dir is missing from PATH. Older releases
# ship asdf.sh, which brew keeps under the formula prefix.
#
# POSIX sh on purpose -- sourced from .profile, .bash_profile and .zsh/asdf.zsh.

export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"

if command -v asdf >/dev/null 2>&1; then
    if [ -f /usr/local/opt/asdf/libexec/asdf.sh ]; then
        . /usr/local/opt/asdf/libexec/asdf.sh
    elif [ -f /opt/homebrew/opt/asdf/libexec/asdf.sh ]; then
        . /opt/homebrew/opt/asdf/libexec/asdf.sh
    fi

    # Idempotent: .zprofile and .zshrc both pull this in.
    case ":$PATH:" in
        *":$ASDF_DATA_DIR/shims:"*) ;;
        *) PATH="$ASDF_DATA_DIR/shims:$PATH"; export PATH ;;
    esac
fi
