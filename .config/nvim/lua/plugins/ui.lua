return {
  -- Which-key: keymap hints popup
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      preset = 'modern',
      delay = 300,
      spec = {
        { '<leader>b', group = 'buffer' },
        { '<leader>c', group = 'code' },
        { '<leader>f', group = 'find' },
        { '<leader>g', group = 'git' },
        { '<leader>h', group = 'hunks' },
        { '<leader>l', group = 'lsp' },
        { '<leader>s', group = 'spell/search' },
        { '<leader>t', group = 'test/toggle' },
        { '<leader>x', group = 'diagnostics/swap' },
      },
    },
  },

  -- Lualine: minimal statusline
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = {
        theme = 'nightfox',
        component_separators = { left = '│', right = '│' },
        section_separators = { left = '', right = '' },
        globalstatus = true,
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch' },
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { 'diagnostics' },
        lualine_y = { 'filetype' },
        lualine_z = { 'location' },
      },
    },
  },

  -- Trouble: diagnostic list
  {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {},
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics (Trouble)' },
      { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics' },
      { '<leader>xL', '<cmd>Trouble loclist toggle<cr>', desc = 'Location List' },
      { '<leader>xQ', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix List' },
    },
  },

  -- Devicons (dependency for many plugins)
  { 'nvim-tree/nvim-web-devicons', lazy = true },

  -- Aerial: symbol outline (LSP + treesitter)
  {
    'stevearc/aerial.nvim',
    cmd = { 'AerialToggle', 'AerialNavToggle' },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = {
      backends = { 'lsp', 'treesitter', 'markdown', 'man' },
      layout = {
        min_width = 30,
        default_direction = 'right',
      },
    },
    keys = {
      { '<leader>co', '<cmd>AerialToggle<cr>', desc = 'Code outline (aerial)' },
      { '<leader>cn', '<cmd>AerialNavToggle<cr>', desc = 'Code nav (aerial)' },
    },
  },

  -- Noice: modern cmdline, messages, notifications
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = { 'MunifTanjim/nui.nvim' },
    opts = {
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
        },
      },
      presets = {
        bottom_search = true,        -- keep search at bottom (familiar)
        command_palette = true,       -- position cmdline at top
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    },
  },
}
