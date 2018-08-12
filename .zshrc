source ~/antigen/antigen.zsh

antigen bundle robbyrussell/oh-my-zsh lib/
antigen bundle git
antigen bundle heroku
antigen bundle zsh-users/zsh-syntax-highlighting

antigen bundle ruby
antigen bundle rails
antigen bundle bundler
antigen bundle chruby


antigen theme robbyrussell/oh-my-zsh themes/robbyrussell

antigen apply

# vim cli settings
bindkey -v

# cause it is really only vi mode
bindkey -a -s "diw" "bde"
bindkey -a -s "daw" "bdw"
bindkey -a -s "diW" "bdE"
bindkey -a -s "daW" "bdW"

# shorten latency when escaping to normal mode
export KEYTIMEOUT=1

# aadd other features back into vim cli mode
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward

# chruby
source /usr/local/share/chruby/chruby.sh
source /usr/local/opt/chruby/share/chruby/auto.sh

setopt HIST_IGNORE_SPACE

source ~/.zsh_work
source ~/.zsh/ag_helpers

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
