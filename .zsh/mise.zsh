# Interactive zsh gets the real activation hook rather than the shims from
# .config/shell/mise.sh: `mise activate` resolves versions per-directory and
# exports [env] vars from mise.toml, which shims cannot do.
#
# Cached like the other init subprocesses -- `mise activate zsh` is a fork+exec
# on every shell start otherwise. zsh_cache_source regenerates when the mise
# binary is newer than the cache, so a version bump picks itself up.
#
# The shim PATH still gets set up first, as the fallback for anything that runs
# before the hook fires (and for non-interactive shells that never source this).
[ -f "$HOME/.config/shell/mise.sh" ] && . "$HOME/.config/shell/mise.sh"

command -v mise >/dev/null && zsh_cache_source mise-activate mise mise activate zsh
