-- init.lua — Neovim Configuration Entry Point
-- Detects runtime context and delegates to appropriate config modules

-- Compatibility shim: Cursor's embedded Neovim (0.11.5) calls vim.lsp.util
-- which requires 'vim.uri', but the module was restructured in recent builds.
-- Provide it if missing to prevent Cursor from crashing.
if not pcall(require, 'vim.uri') then
  package.preload['vim.uri'] = function()
    return {
      uri_from_fname = vim.uri_from_fname,
      uri_from_bufnr = vim.uri_from_bufnr,
      uri_to_fname = vim.uri_to_fname,
    }
  end
end

local profile = 'full'

if vim.g.vscode then
  profile = 'vscode'
elseif vim.g.started_by_firenvim then
  profile = 'firenvim'
end

require('config.options')
require('config.lazy').setup(profile)

if profile == 'vscode' then
  require('config.vscode')
elseif profile == 'firenvim' then
  require('config.keymaps')
  require('firenvim.init')
else
  require('config.keymaps')
  require('config.autocmds')
end
