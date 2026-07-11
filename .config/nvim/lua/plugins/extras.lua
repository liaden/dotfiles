return {
  -- CSS color preview (replaces vim-css-color)
  -- catgoose fork: norcalli original is unmaintained and calls deprecated APIs
  {
    'catgoose/nvim-colorizer.lua',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      filetypes = { 'css', 'scss', 'html', 'javascript', 'typescript', 'lua' },
    },
  },

  -- vim-fetch: open file:line references (e.g., vim file.rb:42)
  {
    'wsdjeg/vim-fetch',
    lazy = false,
  },

  -- vim-dadbod: modern SQL REPL (replaces vipsql)
  {
    'tpope/vim-dadbod',
    cmd = 'DB',
  },
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = { 'tpope/vim-dadbod' },
    cmd = { 'DBUI', 'DBUIToggle', 'DBUIAddConnection' },
    keys = {
      { '<leader>qd', '<cmd>DBUIToggle<cr>', desc = 'Toggle DBUI' },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
  {
    'kristijanhusak/vim-dadbod-completion',
    dependencies = { 'tpope/vim-dadbod' },
    ft = { 'sql', 'mysql', 'plsql' },
  },

  -- Firenvim: neovim in browser textareas (Linux only)
  {
    'glacambre/firenvim',
    cond = not vim.g.vscode and vim.fn.has('linux') == 1,
    build = function() vim.fn['firenvim#install'](0) end,
    lazy = false,
  },
}
