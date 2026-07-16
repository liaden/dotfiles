if command -v atuin &>/dev/null; then
  # Both were `eval "$(...)"`, costing ~60ms of every shell start between them.
  # gen-completions is the worse of the two: ~123KB regenerated every time.
  zsh_cache_source atuin-init atuin atuin init zsh
  zsh_cache_source atuin-completions atuin atuin gen-completions --shell zsh
fi
