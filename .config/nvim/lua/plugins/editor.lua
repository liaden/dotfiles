return {
  -- Surround: cs, ds, ys + surroundings
  {
    'kylechui/nvim-surround',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {},
  },

  -- Commenting: gcc (line), gc (visual), gcO/gco/gcA
  -- NOTE: Nvim 0.11 has built-in gc/gcc commenting. Comment.nvim adds value for
  -- treesitter-aware multi-language blocks (e.g., Lua inside VimScript, HTML inside ERB).
  -- If you find the built-in sufficient, this plugin can be dropped entirely.
  {
    'numToStr/Comment.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {}, -- treesitter-aware commenting
  },

  -- Yank ring: cycle through yank history
  {
    'gbprod/yanky.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      ring = { history_length = 50 },
      highlight = { timer = 200 },
    },
    keys = {
      -- Use direct call instead of <Plug>(YankyYank) to preserve register context.
      -- The <Plug> expr mapping loses vim.v.register when re-evaluating the returned 'y'.
      { 'y', function() return require('yanky').yank({ register = vim.v.register }) end, mode = { 'n', 'x' }, expr = true, desc = 'Yank (yanky)' },
      { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' }, desc = 'Put after (yanky)' },
      { 'P', '<Plug>(YankyPutBefore)', mode = { 'n', 'x' }, desc = 'Put before (yanky)' },
      { '<C-p>', '<Plug>(YankyPreviousEntry)', desc = 'Cycle yank ring back' },
      { '<C-n>', '<Plug>(YankyNextEntry)', desc = 'Cycle yank ring forward' },
    },
  },

  -- Smart substitution: abolish, coercion (crs = snake_case, crm = MixedCase, etc.)
  {
    'tpope/vim-abolish',
    event = { 'BufReadPost', 'BufNewFile' },
  },

  -- Enhanced text objects: better a/i objects with custom patterns
  {
    'echasnovski/mini.ai',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      n_lines = 500,
    },
  },

  -- Flash: jump anywhere, treesitter-select, enhanced f/t
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {},
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash jump' },
      { 'S', mode = { 'n', 'x', 'o' }, function() require('flash').treesitter() end, desc = 'Flash treesitter select' },
      { 'r', mode = 'o', function() require('flash').remote() end, desc = 'Flash remote (operator)' },
      { 'R', mode = { 'o', 'x' }, function() require('flash').treesitter_search() end, desc = 'Flash treesitter search' },
    },
  },

  -- Sideways: swap function arguments left/right
  {
    'AndrewRadev/sideways.vim',
    cmd = { 'SidewaysLeft', 'SidewaysRight' },
    keys = {
      { '<C-h>', '<cmd>SidewaysLeft<cr>', desc = 'Move argument left' },
      { '<C-l>', '<cmd>SidewaysRight<cr>', desc = 'Move argument right' },
      { '<leader>si', '<cmd>SidewaysJumpLeft<cr>', desc = 'Insert before argument' },
      { '<leader>sa', '<cmd>SidewaysJumpRight<cr>', desc = 'Append after argument' },
    },
    init = function()
      -- sideways.vim text objects for arguments
      vim.cmd([[
        omap aa <Plug>SidewaysArgumentTextobjA
        xmap aa <Plug>SidewaysArgumentTextobjA
        omap ia <Plug>SidewaysArgumentTextobjI
        xmap ia <Plug>SidewaysArgumentTextobjI
      ]])
    end,
  },
}
