ASDF_DIR=$(brew --prefix asdf)
source $ASDF_DIR/asdf.sh
if [[ -f /home/linuxbrew/.linuxbrew/etc/bash_completion.d/asdf.bash ]]; then
  source /home/linuxbrew/.linuxbrew/etc/bash_completion.d/asdf.bash
elif [[ -f /usr/local/etc/bash_completion.d/asdf.bash ]]; then
  source /usr/local/etc/bash_completion.d/asdf.bash
fi
