-- NOTE: snacks.picker is configured here. The snacks.nvim base plugin
-- is installed in lua/plugins/snacks.lua (Phase 16). If that phase
-- hasn't been done yet, move the base snacks.nvim spec into this file.

return {
  {
    'folke/snacks.nvim',
    keys = {
      { '<leader>ff', function() Snacks.picker.files() end, desc = 'Find files' },
      { '<leader>fg', function() Snacks.picker.grep() end, desc = 'Grep' },
      { '<leader>fw', function() Snacks.picker.grep_word() end, desc = 'Grep word under cursor', mode = { 'n', 'x' } },
      { '<leader>fb', function() Snacks.picker.buffers() end, desc = 'Buffers' },
      { '<leader>fh', function() Snacks.picker.help() end, desc = 'Help tags' },
      { '<leader>fr', function() Snacks.picker.recent() end, desc = 'Recent files' },
      { '<leader>fs', function() Snacks.picker.lsp_symbols() end, desc = 'LSP symbols' },
      { '<leader>fS', function() Snacks.picker.lsp_workspace_symbols() end, desc = 'Workspace symbols' },
      { '<leader>fd', function() Snacks.picker.diagnostics() end, desc = 'Diagnostics' },
      { '<leader>fc', function() Snacks.picker.colorschemes() end, desc = 'Colorschemes' },
      { '<leader>fk', function() Snacks.picker.keymaps() end, desc = 'Keymaps' },
      { '<leader>f/', function() Snacks.picker.grep_buffers() end, desc = 'Grep open buffers' },
      { '<leader>f:', function() Snacks.picker.command_history() end, desc = 'Command history' },
      { '<leader>fm', function() Snacks.picker.marks() end, desc = 'Marks' },
      { '<leader>fR', function() Snacks.picker.registers() end, desc = 'Registers' },
      { '<leader>fp', function() Snacks.picker.projects() end, desc = 'Projects' },
      -- Git pickers
      { '<leader>fgc', function() Snacks.picker.git_log() end, desc = 'Git commits' },
      { '<leader>fgs', function() Snacks.picker.git_status() end, desc = 'Git status' },
      { '<leader>fgb', function() Snacks.picker.git_branches() end, desc = 'Git branches' },
      -- Resume last picker
      { '<leader><leader>', function() Snacks.picker.resume() end, desc = 'Resume last picker' },
    },
  },
}
