-- config/lazy.lua — Bootstrap lazy.nvim and load plugin specs

-- Auto-install lazy.nvim if not present
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    lazyrepo, lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load all plugin specs from lua/plugins/ directory
require('lazy').setup({
  spec = {
    { import = 'plugins' },  -- auto-imports all files in lua/plugins/
  },
  -- NOTE: defaults.lazy=false, defaults.version=false, checker.enabled=false
  -- are all lazy.nvim defaults — no need to set them explicitly.
  install = {
    colorscheme = { 'nightfox', 'habamax' },  -- fallback during first install
  },
  performance = {
    rtp = {
      -- Disable unused built-in plugins (consolidated here, not in options.lua)
      disabled_plugins = {
        'netrwPlugin',    -- replaced by oil.nvim
        'tutor',
        'tohtml',
        'zipPlugin',
        'tarPlugin',
        'gzip',
      },
    },
  },
})
