return {
  -- Tmux navigator: seamless Alt+hjkl between tmux panes and nvim splits
  {
    'christoomey/vim-tmux-navigator',
    event = 'VeryLazy',
    init = function()
      -- Use Alt+hjkl for navigation (your old config's preference)
      vim.g.tmux_navigator_no_mappings = 1
    end,
    keys = {
      { '<A-h>', '<cmd>TmuxNavigateLeft<cr>', desc = 'Tmux/Nvim left' },
      { '<A-j>', '<cmd>TmuxNavigateDown<cr>', desc = 'Tmux/Nvim down' },
      { '<A-k>', '<cmd>TmuxNavigateUp<cr>', desc = 'Tmux/Nvim up' },
      { '<A-l>', '<cmd>TmuxNavigateRight<cr>', desc = 'Tmux/Nvim right' },
    },
  },

  -- Toggleterm: integrated terminal
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    keys = {
      { '<leader>z', '<cmd>ToggleTerm direction=float<cr>', desc = 'Toggle float terminal' },
      { '<leader>Z', '<cmd>ToggleTerm direction=horizontal size=15<cr>', desc = 'Toggle horizontal terminal' },
    },
    opts = {
      open_mapping = false, -- we use custom keymaps above
      shade_terminals = true,
      float_opts = {
        border = 'rounded',
      },
    },
  },

  -- Tmux syntax highlighting (for editing .tmux.conf)
  {
    'tmux-plugins/vim-tmux',
    ft = 'tmux',
  },
}
