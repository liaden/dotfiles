# zmodload zsh/zprof

source "${HOME}/.zgenom/zgenom.zsh"

# add linuxbrew and completions
if [[ -d /home/linuxbrew ]]; then
  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
fi

zgenom autoupdate

# `zgenom saved` sources $ZGEN_INIT and then inherits the exit status of the
# LAST plugin it loaded, so one plugin returning non-zero (fzf-docker does) makes
# `saved` false and rebuilds the whole cache on every shell — ~1.4s instead of
# ~0.1s. powerlevel10k used to be loaded last and returned 0, which hid this for
# years. Test for the init file itself; the exit status of a plugin is not a
# statement about whether the cache exists.
if [[ -f ${ZGEN_INIT} ]]; then
  source ${ZGEN_INIT}
else
  source ~/.zsh/completions.zsh
  source "${HOME}/.zsh/plugins"
  zgenom save
fi

# Must precede any zsh_cache_source caller below.
source ~/.zsh/cache.zsh

source ~/.zsh/asdf.zsh

# vim cli settings
source ~/.zsh/vim.zsh

# rust
if [[ -d "$HOME/.cargo/bin" ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

if [[ -d "$HOME/go/bin" ]]; then
  export PATH="$HOME/go/bin:$PATH"
fi

alias vim=nvim

setopt AUTO_CD                  # cd without explicit cd
setopt HIST_IGNORE_SPACE        # prefixed ' ' filters command from history
setopt EXTENDED_HISTORY         # save timestamp and duration
setopt SHARE_HISTORY            # shares between concurrent sessions
setopt HIST_FIND_NO_DUPS        # duplicates are still recorded but only one match on history
setopt HIST_NO_STORE            # remove 'history ...' commands from history
setopt HIST_REDUCE_BLANKS       # cleanup whitespace
setopt INC_APPEND_HISTORY_TIME  # add commands to history after command finishes rather than session end

export EDITOR=nvim
export MANPAGER='nvim +Man!'
export MANWIDTH=999

source ~/.zsh/direnv.zsh
[ -f ~/.zsh_work ] && source ~/.zsh_work

source ~/.zsh/chruby.zsh
source ~/.zsh/ag_helpers
source ~/.zsh/git_helpers
source ~/.zsh/fzf.zsh
source ~/.zsh/atuin.zsh
source ~/.zsh/bun.zsh
source ~/.zsh/gcloud.zsh
# source ~/.zsh/chruby.zsh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

zsh_cache_source starship-init starship starship init zsh

export PATH="$HOME/bin:$PATH"
# zprof

export NODE_OPTIONS="--max-old-space-size=8192"
export CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1

# podman as docker drop-in replacement
# alias docker=podman  # disabled — lima docker context
# alias docker-compose="podman compose"  # disabled
