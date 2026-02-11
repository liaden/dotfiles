return {
  -- vim-rails: :A, :R, gf in Rails, projections
  {
    'tpope/vim-rails',
    ft = { 'ruby', 'eruby' },
  },

  -- vim-bundler: gf on gem names, Bopen
  {
    'tpope/vim-bundler',
    ft = { 'ruby', 'eruby' },
    cmd = { 'Bundle', 'Bopen', 'Bsplit', 'Btabedit' },
  },

  -- vim-rake: useful for non-Rails Ruby projects
  {
    'tpope/vim-rake',
    ft = 'ruby',
  },
}
