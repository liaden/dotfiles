# Cache slow shell-init subprocesses.
#
# `eval "$(tool init zsh)"` costs a fork+exec on every single shell start. Here
# that was ~70ms of a ~180ms startup (atuin ~60ms, direnv ~10ms). The output is
# deterministic, so it is generated once and regenerated only when the producing
# binary is newer than the cache.

typeset -g ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

# zsh_cache_source <name> <binary> <command...>
#   Cache stdout of <command...> to $ZSH_CACHE_DIR/<name>.zsh and source it.
#   Regenerates when the cache is missing/empty, or when <binary> is newer than
#   the cache (i.e. after a brew upgrade).
zsh_cache_source() {
  local name=$1 bin=$2
  shift 2
  local cache="$ZSH_CACHE_DIR/${name}.zsh"

  if [[ ! -s $cache || ${commands[$bin]} -nt $cache ]]; then
    [[ -d $ZSH_CACHE_DIR ]] || mkdir -p $ZSH_CACHE_DIR
    # Generate via a temp file: a failed or partial run must not poison the
    # cache, or every future shell sources a broken half-file.
    local tmp="${cache}.$$"
    if "$@" > $tmp 2>/dev/null && [[ -s $tmp ]]; then
      mv -f $tmp $cache
      # Compiled form; zsh prefers <file>.zwc automatically when it is newer.
      zcompile -- $cache 2>/dev/null
    else
      rm -f $tmp
      return 1
    fi
  fi

  source $cache
}
