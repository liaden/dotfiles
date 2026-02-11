return {
  {
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      default_file_explorer = true,
      columns = { 'icon' },
      -- NOTE: Most keymaps below are oil.nvim defaults. We only override two:
      -- <C-h> → <C-s> (split) to avoid tmux conflict with <C-h>
      -- <C-l> → gr (refresh) to avoid tmux conflict with <C-l>
      keymaps = {
        ['<C-s>'] = 'actions.select_split',  -- default is <C-h>, conflicts with tmux nav
        ['gr'] = 'actions.refresh',           -- default is <C-l>, conflicts with tmux nav
        ['<C-h>'] = false,                    -- explicitly disable conflicting defaults
        ['<C-l>'] = false,
      },
      view_options = {
        show_hidden = false, -- toggle with g.
      },
    },
    keys = {
      { '-', '<cmd>Oil<cr>', desc = 'Open parent directory (oil)' },
    },
  },
}
