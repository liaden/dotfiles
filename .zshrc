export TERM="xterm-256color" # for tmux

source "${HOME}/.zgen/zgen.zsh"

## customize powerlevel9k theme
if [[ "$(hostname)" == "CLM-JJOHNSON10.local" ]]; then
  export DEFAULT_USER="jjohnson10"
fi

# if the init scipt doesn't exist
if ! zgen saved; then
  source "${HOME}/.zsh_plugins"
fi

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

# chruby
if [[ -d /usr/local/chruby ]]; then
  source /usr/local/chruby/chruby.sh
  source /usr/local/chruby/auto.sh
else
  source /usr/local/share/chruby/chruby.sh
  source /usr/local/opt/chruby/share/chruby/auto.sh
fi

if [[ -d /Users/jjohnson10/.cargo/bin ]]; then
  export PATH="/Users/jjohnson10/.cargo/bin:$PATH"
fi

alias vim=nvim
alias config="alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'"

setopt HIST_IGNORE_SPACE

eval "$(direnv hook zsh)"
source ~/.zsh_work
source ~/.zsh/ag_helpers

export EDITOR=nvim

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
