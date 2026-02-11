-- firenvim/init.lua — Minimal config for browser textareas (Linux desktop)

vim.o.laststatus = 0
vim.o.showtabline = 0
vim.o.wrap = true
vim.o.linebreak = true

vim.g.firenvim_config = {
  globalSettings = { alt = 'all' },
  localSettings = {
    ['.*'] = {
      cmdline = 'neovim',
      content = 'text',
      priority = 0,
      selector = 'textarea',
      takeover = 'always',
    },
    ['.*notion\\.so.*'] = { priority = 9, takeover = 'never' },
    ['.*docs\\.google\\.com.*'] = { priority = 9, takeover = 'never' },
    ['.*chat\\.google\\.com.*'] = { priority = 9, takeover = 'never' },
  },
}

-- Auto-detect filetype from URL
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = 'github.com_*.txt',
  callback = function() vim.bo.filetype = 'markdown' end,
})
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = 'gitlab.com_*.txt',
  callback = function() vim.bo.filetype = 'markdown' end,
})
