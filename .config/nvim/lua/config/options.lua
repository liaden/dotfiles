-- config/options.lua — Shared vim.opt settings for ALL contexts
local opt = vim.opt

-- Leader key (must be set before lazy.nvim)
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
-- NOTE: hlsearch and incsearch are already nvim 0.11 defaults

-- UI
-- NOTE: termguicolors is auto-detected by nvim 0.10+ (iTerm2/Kitty both support 24-bit)
opt.signcolumn = 'yes'
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.showmode = false        -- lualine shows mode
opt.splitbelow = true
opt.splitright = true
opt.mouse = 'a'
opt.updatetime = 250
opt.timeoutlen = 300

-- Persistent undo
opt.undofile = true
opt.undolevels = 10000

-- NOTE: completeopt defaults to 'menu,popup' in nvim 0.11; blink.cmp bypasses native completion

-- Grep: nvim 0.11 auto-detects rg but defaults to `rg --vimgrep -uu`
-- We override to use --smart-case and respect .gitignore (no -uu)
if vim.fn.executable('rg') == 1 then
  opt.grepprg = 'rg --vimgrep --smart-case'
  -- NOTE: grepformat is auto-set by nvim when rg is detected
end

-- Code-Aware Spell Checking
-- Replaces spelunker.vim: splits CamelCase identifiers for spell checking
-- getUserName → checks "get", "User", "Name" individually
-- snake_case_var → underscores naturally split words
opt.spell = false             -- off by default; enabled per-filetype in after/ftplugin/
opt.spelllang = { 'en_us' }
opt.spelloptions:append('camel')  -- CamelCase splitting (nvim 0.8+)

-- Custom spell dictionary for programming terms
-- Words added here won't be flagged (e.g., struct, impl, async, params)
local spell_dir = vim.fn.stdpath('config') .. '/spell'
if vim.fn.isdirectory(spell_dir) == 0 then
  vim.fn.mkdir(spell_dir, 'p')
end
opt.spellfile = spell_dir .. '/code.utf-8.add'

-- Clipboard: let Neovim auto-detect the provider.
-- On macOS this uses pbcopy/pbpaste natively. If you later need OSC 52
-- (SSH, remote tmux), you can set vim.g.clipboard to the OSC 52 provider.

-- NOTE: Unused built-in plugins (netrwPlugin, tutor, tohtml, etc.) are disabled
-- in lazy.lua's performance.rtp.disabled_plugins to avoid duplication.

-- Project-local config support (loads .nvim.lua from project root if trusted)
-- NOTE: editorconfig is enabled by default in nvim 0.11 (.editorconfig auto-applied)
opt.exrc = true
