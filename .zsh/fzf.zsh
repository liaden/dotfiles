if [[ -d /usr/local/opt/fzf ]]; then
  # Setup fzf
  # ---------
  if [[ ! "$PATH" == */usr/local/opt/fzf/bin* ]]; then
    export PATH="${PATH:+${PATH}:}/usr/local/opt/fzf/bin"
  fi

  # Auto-completion
  # ---------------
  [[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.zsh" 2> /dev/null

  # Key bindings
  # ------------
  source "/usr/local/opt/fzf/shell/key-bindings.zsh"
elif [[ -d /home/linuxbrew/.linuxbrew/opt/fzf ]]; then
  # Setup fzf
  # ---------
  if [[ ! "$PATH" == */home/linuxbrew/.linuxbrew/opt/fzf/bin* ]]; then
    export PATH="${PATH:+${PATH}:}/home/linuxbrew/.linuxbrew/opt/fzf/bin"
  fi

  # Auto-completion
  # ---------------
  [[ $- == *i* ]] && source "/home/linuxbrew/.linuxbrew/opt/fzf/shell/completion.zsh" 2> /dev/null

  # Key bindings
  # ------------
  source "/home/linuxbrew/.linuxbrew/opt/fzf/shell/key-bindings.zsh"
fi
