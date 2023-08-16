if [[ -d /usr/local/opt/fzf ]]; then
  # Auto-completion
  # ---------------
  [[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.zsh" 2> /dev/null

  # Key bindings
  # ------------
  source "/usr/local/opt/fzf/shell/key-bindings.zsh"
elif [[ -d /opt/homebrew/opt/fzf ]]; then
  # Auto-completion
  # ---------------
  [[ $- == *i* ]] && source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2> /dev/null

  # Key bindings
  # ------------
  source "/usr/local/opt/fzf/shell/key-bindings.zsh"
elif [[ -d /home/linuxbrew/.linuxbrew/opt/fzf ]]; then
  # Auto-completion
  # ---------------
  [[ $- == *i* ]] && source "/home/linuxbrew/.linuxbrew/opt/fzf/shell/completion.zsh" 2> /dev/null

  # Key bindings
  # ------------
  source "/home/linuxbrew/.linuxbrew/opt/fzf/shell/key-bindings.zsh"
fi
