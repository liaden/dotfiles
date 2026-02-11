return {
  {
    'folke/snacks.nvim',
    priority = 900,
    lazy = false,
    opts = {
      -- Picker (configured in finder.lua, Phase 10)
      picker = {},

      -- Toast notifications (replaces nvim-notify)
      notifier = { enabled = true },

      -- Indent guides + scope highlighting
      indent = { enabled = true },

      -- Smooth scrolling
      scroll = { enabled = true },

      -- Highlight + navigate word references (like vim-illuminate)
      words = { enabled = true },

      -- Better buffer deletion (preserves window layout)
      bufdelete = { enabled = true },

      -- Dim inactive code (replaces twilight.nvim for code)
      dim = { enabled = true },

      -- Zen mode (distraction-free editing)
      zen = { enabled = true },

      -- Git utilities (blame, browse)
      git = { enabled = true },

      -- Quick file opener (fast startup for specific files)
      quickfile = { enabled = true },

      -- Better vim.ui.input
      input = { enabled = true },
    },
    keys = {
      { '<leader>bd', function() Snacks.bufdelete() end, desc = 'Delete buffer (keep layout)' },
      { '<leader>un', function() Snacks.notifier.show_history() end, desc = 'Notification history' },
      { '<leader>uZ', function() Snacks.zen() end, desc = 'Zen mode' },
      { '<leader>uz', function() Snacks.zen.zoom() end, desc = 'Zoom (zen)' },
      { '<leader>ud', function() Snacks.dim() end, desc = 'Dim inactive scopes' },
      { '<leader>gB', function() Snacks.git.blame_line() end, desc = 'Git blame line (snacks)' },
      { '<leader>go', function() Snacks.gitbrowse() end, desc = 'Open in browser (git)' },
      { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Next word reference' },
      { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Prev word reference' },
    },
  },
}
