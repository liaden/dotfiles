export TERM="xterm-256color" # for tmux

# add linuxbrew and completions
if [[ -d /home/linuxbrew ]]; then
  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
fi

source ~/.zsh/completions.zsh

source "${HOME}/.zgen/zgen.zsh"

## customize powerlevel9k theme
if [[ "$(hostname)" == "CLM-JJOHNSON10.local" ]]; then
  export DEFAULT_USER="jjohnson10"
fi

# if the init scipt doesn't exist
if ! zgen saved; then
  source "${HOME}/.zsh_plugins"
fi

source ~/.zsh/asdf.zsh
source ~/.zsh/chruby.zsh

# vim cli settings
bindkey -v

# cause it is really only vi mode
bindkey -a -s "diw" "bde"
bindkey -a -s "daw" "bdw"
bindkey -a -s "diW" "bdE"
bindkey -a -s "daW" "bdW"

# shorten latency when escaping to normal mode
export KEYTIMEOUT=1

# add other features back into vim cli mode
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward

# rust
if [[ -d "$HOME/.cargo/bin" ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

if [[ -d "$HOME/go/bin" ]]; then
  export PATH="$HOME/go/bin:$PATH"
fi

alias git=hub
alias vim=nvim
alias config="alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'"

setopt AUTO_CD                  # cd without explicit cd
setopt HIST_IGNORE_SPACE        # prefixed ' ' filters command from history
setopt EXTENDED_HISTORY         # save timestamp and duration
setopt HIST_FIND_NO_DUPS        # duplicates are still recorded but only one match on history
setopt HIST_NO_STORE            # remove 'history ...' commands from history
setopt HIST_REDUCE_BLANKS       # cleanup whitespace
setopt INC_APPEND_HISTORY_TIME  # add commands to history after command finishes rather than session end

export EDITOR=nvim
export FZF_DEFAULT_OPTS='--height=50% --min-height=15 --reverse'
export FZF_DEFAULT_CMD='fd --type f'

command -v direnv  && eval "$(direnv hook zsh)"
[ -f ~/.zsh_work ] && source ~/.zsh_work

source ~/.zsh/ag_helpers
source ~/.zsh/git_helpers
source ~/.zsh/fzf.zsh
