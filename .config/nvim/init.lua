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

-- Context detection
local context = 'full' -- default: standalone neovim

if vim.g.vscode then
  context = 'vscode'
elseif vim.g.started_by_firenvim then
  context = 'firenvim'
end

-- Load shared options (always, all contexts)
require('config.options')

if context == 'vscode' then
  -- Lightweight: keymaps + text plugins only
  require('vscode.init')
elseif context == 'firenvim' then
  -- Minimal: basic editing for browser textareas
  require('firenvim.init')
else
  -- Full standalone neovim
  require('config.lazy')     -- bootstrap lazy.nvim, load all plugins
  require('config.keymaps')  -- keymaps (after plugins so we can reference them)
  require('config.autocmds') -- autocommands
end
