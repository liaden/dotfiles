if [ -x "$(command -v brew)" ]; then
  source "$(brew --prefix chruby)/share/chruby/chruby.sh"
  source "$(brew --prefix chruby)/share/chruby/auto.sh"
elif [[ -d /usr/local/chruby ]]; then
  source /usr/local/chruby/chruby.sh
  source /usr/local/chruby/auto.sh
fi

