if command -v atuin &>/dev/null; then
  # Both were `eval "$(...)"`, costing ~60ms of every shell start between them.
  # gen-completions is the worse of the two: ~123KB regenerated every time.
  zsh_cache_source atuin-init atuin atuin init zsh
  zsh_cache_source atuin-completions atuin atuin gen-completions --shell zsh

  # fzf's key-bindings.zsh binds ^R in emacs+viins+vicmd; atuin's init only
  # overrides emacs and viins (it takes '/' in vicmd instead). So in normal mode
  # ^R still reached fzf, which searches $HISTFILE (SAVEHIST=10000) rather than
  # atuin's db — reverse search that silently sees a fraction of the history.
  # viins, not vicmd: ^R should open the TUI ready to type either way.
  bindkey -M vicmd '^r' atuin-search-viins
  # vim.zsh binds ^z with a bare bindkey, which after `bindkey -v` is viins only.
  bindkey -M vicmd '^z' fg-bg

  # 18.18 claimed two keys on upgrade. Reclaim both: `k` is movement in normal
  # mode, and `?` on an empty buffer should type a character, not start an AI
  # session. ^R remains the way in.
  bindkey -M vicmd 'k' up-line-or-history
  bindkey -M viins '?' self-insert
fi
