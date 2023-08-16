if [[ -d /usr/local/share/zsh/site-functions ]]; then
  fpath+="/usr/local/share/zsh/site-functions"
fi

if [[ -d /home/linuxbrew/.linuxbrew/share/zsh/site-functions ]]; then
  fpath+="/home/linuxbrew/.linuxbrew/share/zsh/site-functions"
fi

if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
  fpath+="/opt/homebrew/share/zsh/site-functions"
fi

if [[ -d $HOME/.zfunc ]]; then
  fpath+=$HOME/.zfunc
fi

fpath+=$HOME/.zsh/func
autoload -Uz pgexec

zgenom compdef _git config=git
