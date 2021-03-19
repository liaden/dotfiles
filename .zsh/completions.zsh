if [ -x "$(command -v brew)" ]; then
  if [[ -f /usr/local/share/zsh/site-functions ]]; then
    fpath+="/usr/local/share/zsh/site-functions"
  elif [[ -f /home/linuxbrew/.linuxbrew/share/zsh/site-functions ]]; then
    fpath+="/home/linuxbrew/.linuxbrew/share/zsh/site-functions"
  fi
fi

if [[ -d $HOME/.zfunc ]]; then
  fpath+=$HOME/.zfunc
fi

compdef _git config=git
