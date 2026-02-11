-- Ruby-specific settings
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.expandtab = true
vim.opt_local.spell = true
vim.opt_local.spelloptions:append('camel')
vim.opt_local.spellcapcheck = '' -- don't flag lowercase "sentence starts" in code

-- Ruby postfix conditional toggle mappings (preserved from old config)
-- <leader>i: expand postfix conditional → block form
--   do_something if condition  →  if condition\n  do_something\nend
vim.keymap.set('n', '<leader>i', function()
  local line = vim.api.nvim_get_current_line()
  local indent = line:match('^(%s*)')
  local body, keyword, condition = line:match('^%s*(.+)%s+(if%s+.+)$')
  if not body then
    body, keyword, condition = line:match('^%s*(.+)%s+(unless%s+.+)$')
  end
  if body and keyword then
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, {
      indent .. keyword,
      indent .. '  ' .. body,
      indent .. 'end',
    })
  end
end, { buffer = true, desc = 'Expand postfix conditional to block' })

-- <leader>I: collapse block conditional → postfix form
--   if condition\n  do_something\nend  →  do_something if condition
vim.keymap.set('n', '<leader>I', function()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, row - 1, row + 2, false)
  if #lines < 3 then return end
  local indent = lines[1]:match('^(%s*)')
  local keyword_cond = lines[1]:match('^%s*(if%s+.+)$') or lines[1]:match('^%s*(unless%s+.+)$')
  local body = lines[2]:match('^%s*(.+)$')
  local is_end = lines[3]:match('^%s*end%s*$')
  if keyword_cond and body and is_end then
    vim.api.nvim_buf_set_lines(0, row - 1, row + 2, false, {
      indent .. body .. ' ' .. keyword_cond,
    })
  end
end, { buffer = true, desc = 'Collapse block conditional to postfix' })
