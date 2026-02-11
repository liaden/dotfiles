vim.opt_local.spell = true
vim.opt_local.spelllang = { 'en_us' }
vim.opt_local.spelloptions:append('camel')
vim.opt_local.textwidth = 72
vim.opt_local.colorcolumn = '50,72'
-- Auto-enter insert mode for new commits
if vim.fn.getline(1) == '' then
  vim.cmd('startinsert')
end
