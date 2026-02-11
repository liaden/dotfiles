return {
  -- Gitsigns: inline signs + hunk staging
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      signs = {
        add          = { text = '│' },
        change       = { text = '│' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = function(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        -- Navigation between hunks
        map('n', ']h', gs.next_hunk, 'Next git hunk')
        map('n', '[h', gs.prev_hunk, 'Prev git hunk')

        -- Hunk staging
        map('n', '<leader>hs', gs.stage_hunk, 'Stage hunk')
        map('n', '<leader>hu', gs.undo_stage_hunk, 'Unstage hunk')
        map('v', '<leader>hs', function()
          gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
        end, 'Stage selected lines')
        map('n', '<leader>hS', gs.stage_buffer, 'Stage entire buffer')
        map('n', '<leader>hR', gs.reset_buffer, 'Reset buffer')
        map('n', '<leader>hr', gs.reset_hunk, 'Reset hunk')

        -- Preview & blame
        map('n', '<leader>hp', gs.preview_hunk, 'Preview hunk')
        map('n', '<leader>hb', function() gs.blame_line({ full = true }) end, 'Blame line')
        map('n', '<leader>hd', gs.diffthis, 'Diff this')
        map('n', '<leader>hD', function() gs.diffthis('~') end, 'Diff this (cached)')

        -- Toggle blame
        map('n', '<leader>tb', gs.toggle_current_line_blame, 'Toggle line blame')
      end,
    },
  },

  -- Fugitive: git commands
  {
    'tpope/vim-fugitive',
    cmd = { 'Git', 'Gread', 'Gwrite', 'GBrowse', 'Gdiffsplit' },
    keys = {
      { '<leader>gs', '<cmd>Git<cr>', desc = 'Git status (fugitive)' },
      { '<leader>gb', '<cmd>Git blame<cr>', desc = 'Git blame' },
      { '<leader>gd', '<cmd>Gdiffsplit<cr>', desc = 'Git diff split' },
      { '<leader>gl', '<cmd>Git log --oneline<cr>', desc = 'Git log' },
    },
  },

  -- Neogit: magit-like interactive staging
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
    },
    cmd = 'Neogit',
    opts = {
      integrations = {
        diffview = true,
      },
    },
    keys = {
      { '<leader>gg', '<cmd>Neogit<cr>', desc = 'Neogit status' },
      { '<leader>gc', '<cmd>Neogit commit<cr>', desc = 'Neogit commit' },
      { '<leader>gp', '<cmd>Neogit push<cr>', desc = 'Neogit push' },
      { '<leader>gP', '<cmd>Neogit pull<cr>', desc = 'Neogit pull' },
    },
  },

  -- Diffview: tabpage diff viewer + file history
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    keys = {
      { '<leader>gD', '<cmd>DiffviewOpen<cr>', desc = 'Diffview open' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = 'File history' },
      { '<leader>gH', '<cmd>DiffviewFileHistory<cr>', desc = 'Branch history' },
    },
    opts = {},
  },
}
