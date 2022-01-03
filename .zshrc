# zmodload zsh/zprof

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export TERM="xterm-256color" # for tmux

source "${HOME}/.zgenom/zgenom.zsh"

# add linuxbrew and completions
if [[ -d /home/linuxbrew ]]; then
  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
fi

source ~/.zsh/completions.zsh

## customize powerlevel9k theme
if [[ "$(hostname)" == "CLM-JJOHNSON10.local" ]]; then
  export DEFAULT_USER="jjohnson10"
fi

# if the init scipt doesn't exist
if ! zgenom saved; then
  source "${HOME}/.zsh/plugins"
fi

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

alias git=hub
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

command -v direnv > /dev/null  && eval "$(direnv hook zsh)"
[ -f ~/.zsh_work ] && source ~/.zsh_work

source ~/.zsh/minikube.zsh
source ~/.zsh/ag_helpers
source ~/.zsh/git_helpers
source ~/.zsh/fzf.zsh
source ~/.zsh/chruby.zsh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

source ~/.zsh/p10k.zsh

export PATH="$HOME/bin:$PATH"
# zprof
