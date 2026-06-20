if [[ -d /usr/local/share/google-cloud-sdk ]]; then
  source "/usr/local/share/google-cloud-sdk/path.zsh.inc"
  source "/usr/local/share/google-cloud-sdk/completion.zsh.inc"
elif [[ -d /opt/homebrew/share/google-cloud-sdk ]]; then
  source "/opt/homebrew/share/google-cloud-sdk/path.zsh.inc"
  source "/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc"
elif [[ -d /home/linuxbrew/.linuxbrew/share/google-cloud-sdk ]]; then
  source "/home/linuxbrew/.linuxbrew/share/google-cloud-sdk/path.zsh.inc"
  source "/home/linuxbrew/.linuxbrew/share/google-cloud-sdk/completion.zsh.inc"
fi
