if [ -x "$(command -v brew)" ]; then
  fpath+="$(brew --prefix)/share/zsh/site-functions"
fi

if [[ -d $HOME/.zfunc ]]; then
  fpath+=$HOME/.zfunc
fi
