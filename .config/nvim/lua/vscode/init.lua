-- vscode/init.lua — Config for when nvim runs inside Cursor/VSCode
-- Only loads keybindings and text manipulation — UI/LSP/completion handled by Cursor

-- Load text manipulation plugins via lazy.nvim (minimal set)
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.opt.rtp:prepend(lazypath)
  require('lazy').setup({
    -- Text manipulation only (no UI, no LSP, no completion)
    { 'kylechui/nvim-surround', opts = {} },
    { 'tpope/vim-abolish' },
    { 'numToStr/Comment.nvim', opts = {} },
    { 'folke/flash.nvim', opts = {} },
  }, {
    defaults = { lazy = false },
    install = { colorscheme = {} },
    checker = { enabled = false },
    performance = { rtp = { disabled_plugins = {} } },
  })
end

-- Load VSCode-specific keymaps
require('vscode.keymaps')
