if [[ -d /usr/local/opt/asdf ]]; then
    export ASDF_DIR="/usr/local/opt/asdf/libexec"
    source $ASDF_DIR/asdf.sh
elif [[ -d /home/linuxbrew/.linuxbrew/opt/asdf ]]; then
    export ASDF_DIR="/home/linuxbrew/.linuxbrew/opt/asdf/libexec"
    source $ASDF_DIR/asdf.sh
fi
