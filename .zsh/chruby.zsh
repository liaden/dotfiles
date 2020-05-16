if [ -x "$(command -v brew)" ]; then
  if [[ -d /usr/local/opt/chruby/share/chruby/ ]]; then
    source /usr/local/opt/chruby/share/chruby/chruby.sh
    source /usr/local/opt/chruby/share/chruby/auto.sh
  elif [[ -d /home/linuxbrew/.linuxbrew/opt/chruby ]]; then
    source /home/linuxbrew/.linuxbrew/opt/chruby/share/chruby/chruby.sh
    source /home/linuxbrew/.linuxbrew/opt/chruby/share/chruby/auto.sh
  fi
elif [[ -d /usr/local/chruby ]]; then
  source /usr/local/chruby/chruby.sh
  source /usr/local/chruby/auto.sh
fi

