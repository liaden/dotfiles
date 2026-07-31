local M = {}

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    lazyrepo, lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local editing_plugins = {
  { 'kylechui/nvim-surround', opts = {} },
  { 'tpope/vim-abolish' },
  { 'numToStr/Comment.nvim', opts = {} },
  { 'folke/flash.nvim', opts = {} },
}

local profiles = {
  full = {
    spec = { { import = 'plugins' } },
    colorschemes = { 'nightfox', 'habamax' },
  },
  firenvim = {
    spec = vim.list_extend({
      {
        'glacambre/firenvim',
        lazy = false,
        build = function() vim.fn['firenvim#install'](0) end,
      },
    }, editing_plugins),
    colorschemes = {},
  },
  vscode = {
    spec = editing_plugins,
    colorschemes = {},
  },
}

function M.setup(profile)
  local selected = assert(profiles[profile], 'unknown lazy profile: ' .. tostring(profile))
  require('lazy').setup({
    spec = selected.spec,
    defaults = { lazy = false },
    install = { colorscheme = selected.colorschemes },
    checker = { enabled = false },
    performance = {
      rtp = {
        disabled_plugins = profile == 'full' and {
          'netrwPlugin',
          'tutor',
          'tohtml',
          'zipPlugin',
          'tarPlugin',
          'gzip',
        } or {},
      },
    },
  })
  if profile == 'firenvim' then
    vim.cmd.runtime('autoload/firenvim.vim')
  end
end

return M
