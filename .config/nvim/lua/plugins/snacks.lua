return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      -- Picker (configured in finder.lua, Phase 10)
      picker = {},

      bigfile = { enabled = true },
      dashboard = { enabled = true },
      explorer = { enabled = true },
      scope = { enabled = true },
      statuscolumn = { enabled = true },

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

      -- Inline images + mermaid/latex diagrams (kitty graphics protocol;
      -- no-ops gracefully on terminals without it, e.g. alacritty)
      image = {
        enabled = true,
        convert = {
          -- default args plus -p: chromium needs --no-sandbox on Ubuntu 24+
          -- (AppArmor userns restriction), passed via puppeteer config
          mermaid = function()
            local theme = vim.o.background == 'light' and 'neutral' or 'dark'
            return {
              '-i', '{src}', '-o', '{file}', '-b', 'transparent', '-t', theme,
              '-s', '{scale}', '-p', vim.fn.expand('~/.config/mermaid/puppeteer.json'),
            }
          end,
        },
      },
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
