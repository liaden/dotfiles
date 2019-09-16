export TERM="xterm-256color" # for tmux

# add linuxbrew and completions
if [[ -d /home/linuxbrew ]]; then
  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

source "${HOME}/.zgen/zgen.zsh"

## customize powerlevel9k theme
if [[ "$(hostname)" == "CLM-JJOHNSON10.local" ]]; then
  export DEFAULT_USER="jjohnson10"
fi

# if the init scipt doesn't exist
if ! zgen saved; then
  source "${HOME}/.zsh_plugins"
fi

# linuxbrew/homebrew
if [ -x "$(command -v brew)" ]; then
  source "$(brew --prefix chruby)/share/chruby/chruby.sh"
  source "$(brew --prefix chruby)/share/chruby/auto.sh"

  ASDF_DIR=$(brew --prefix asdf)
  source $ASDF_DIR/asdf.sh
  if [[ -f /usr/local/etc/bash_completion.d/asdf.bash ]]; then
    source /usr/local/etc/bash_completion.d/asdf.bash
  fi
  if [[ -f /home/linuxbrew/.linuxbrew/etc/bash_completion.d/asdf.bash ]]; then
    source /home/linuxbrew/.linuxbrew/etc/bash_completion.d/asdf.bash
  fi
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

# chruby (work linux)
if [[ -d /usr/local/chruby ]]; then
  source /usr/local/chruby/chruby.sh
  source /usr/local/chruby/auto.sh
fi

# rust
if [[ -d "$HOME/.cargo/bin" ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

alias git=hub
alias vim=nvim
alias config="alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'"

setopt HIST_IGNORE_SPACE

export EDITOR=nvim
export FZF_DEFAULT_OPTS='--height=50% --min-height=15 --reverse'
export FZF_DEFAULT_CMD='fd --type f'

command -v direnv] && eval "$(direnv hook zsh)"
[ -f ~/.zsh_work ] && source ~/.zsh_work

source ~/.zsh/ag_helpers
source ~/.zsh/git_helpers

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
