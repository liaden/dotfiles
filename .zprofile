export PATH="$HOME/.local/bin:$PATH"

if [ -x "$(command -v xmonad)" ]; then
    export PATH="$HOME/.xmonad/bin:$PATH"
fi

eval "$(/opt/homebrew/bin/brew shellenv zsh)"
source ~/.zsh/asdf.zsh
