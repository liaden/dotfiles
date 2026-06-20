if [[ -d /usr/local/opt/asdf ]]; then
    export ASDF_DIR="/usr/local/opt/asdf/libexec"
    source $ASDF_DIR/asdf.sh
elif [[ -d /opt/homebrew/opt/asdf ]]; then
    export ASDF_DIR="/opt/homebrew/opt/asdf"
    source $ASDF_DIR/asdf.sh
elif [[ -d /home/linuxbrew/.linuxbrew/opt/asdf ]]; then
    # asdf 0.16+ (Go rewrite) — binary is in PATH via brew; add shims manually
    export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
    export PATH="$ASDF_DATA_DIR/shims:$PATH"
fi
