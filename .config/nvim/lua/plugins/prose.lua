return {
  -- Vim-pencil: soft/hard wrap modes for prose
  {
    'preservim/vim-pencil',
    ft = { 'markdown', 'text', 'org' },
    init = function()
      vim.g['pencil#wrapModeDefault'] = 'soft'
    end,
  },

  -- Zen mode: distraction-free writing
  -- NOTE: Also available via snacks.zen (Phase 16). If snacks.zen is
  -- sufficient, you can skip this plugin. zen-mode.nvim has more
  -- configuration options (integration with twilight, tmux, kitty).
  {
    'folke/zen-mode.nvim',
    cmd = 'ZenMode',
    opts = {
      window = {
        width = 80,
        options = {
          number = false,
          relativenumber = false,
          signcolumn = 'no',
        },
      },
      plugins = {
        twilight = { enabled = true },
        tmux = { enabled = true },    -- hide tmux statusbar in zen
        kitty = { enabled = true, font = '+2' }, -- increase font in kitty
      },
    },
    keys = {
      { '<leader>wz', '<cmd>ZenMode<cr>', desc = 'Zen mode (prose)' },
    },
  },

  -- Twilight: dim inactive paragraphs
  {
    'folke/twilight.nvim',
    cmd = 'Twilight',
    opts = {},
    keys = {
      { '<leader>wt', '<cmd>Twilight<cr>', desc = 'Toggle twilight' },
    },
  },

  -- Render-markdown: inline markdown rendering (headings, bullets, tables, checkboxes)
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown' },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = {},
  },

  -- Markdown preview in browser
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview' },
    ft = 'markdown',
    build = 'cd app && npx --yes yarn install',
    keys = {
      { '<leader>wp', '<cmd>MarkdownPreviewToggle<cr>', desc = 'Markdown preview' },
    },
  },

  -- Obsidian: Zettelkasten / vault integration
  -- Only loads when a vault directory actually exists.
  -- To use: create ~/vaults/personal (or change the path below).
  {
    'epwalsh/obsidian.nvim',
    version = '*',
    lazy = true,
    ft = 'markdown',
    cond = function()
      -- Don't load if the vault doesn't exist yet
      return vim.fn.isdirectory(vim.fn.expand('~/vaults/personal')) == 1
    end,
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      workspaces = {
        { name = 'personal', path = '~/vaults/personal' },
      },
      daily_notes = {
        folder = 'daily',
        date_format = '%Y-%m-%d',
      },
      note_id_func = function(title)
        -- Zettelkasten-style: timestamp prefix
        local suffix = ''
        if title ~= nil then
          suffix = title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
        else
          suffix = tostring(os.time())
        end
        return tostring(os.date('%Y%m%d%H%M')) .. '-' .. suffix
      end,
      -- Uses your picker (snacks.picker or telescope)
      picker = { name = 'snacks.picker' },
    },
    keys = {
      { '<leader>on', '<cmd>ObsidianNew<cr>', desc = 'New note' },
      { '<leader>od', '<cmd>ObsidianToday<cr>', desc = 'Daily note' },
      { '<leader>os', '<cmd>ObsidianSearch<cr>', desc = 'Search vault' },
      { '<leader>ob', '<cmd>ObsidianBacklinks<cr>', desc = 'Backlinks' },
      { '<leader>ot', '<cmd>ObsidianTags<cr>', desc = 'Tags' },
      { '<leader>oq', '<cmd>ObsidianQuickSwitch<cr>', desc = 'Quick switch note' },
    },
  },

  -- Orgmode: structured notes, agenda, capture, GTD
  {
    'nvim-orgmode/orgmode',
    event = 'VeryLazy',
    ft = { 'org' },
    config = function()
      require('orgmode').setup({
        org_agenda_files = { '~/org/**/*' },
        org_default_notes_file = '~/org/refile.org',
        org_capture_templates = {
          t = { description = 'Task', template = '* TODO %?\n  %u' },
          j = { description = 'Journal', template = '* %U\n  %?', target = '~/org/journal.org' },
          n = { description = 'Note', template = '* %?\n  %u\n  %a' },
          i = { description = 'Idea', template = '* %?\n  %u', target = '~/org/ideas.org' },
        },
        org_todo_keywords = { 'TODO(t)', 'IN-PROGRESS(i)', 'WAITING(w)', '|', 'DONE(d)', 'CANCELLED(c)' },
      })
    end,
  },

  -- Org-bullets: pretty heading symbols for .org files
  {
    'akinsho/org-bullets.nvim',
    ft = 'org',
    opts = {},
  },
}
