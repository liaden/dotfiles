-- config/keymaps.lua — Base keymaps for standalone neovim
local map = vim.keymap.set

-- Better escape
map('i', 'jk', '<Esc>', { desc = 'Escape insert mode' })

-- Window navigation (non-tmux, overridden by vim-tmux-navigator later)
map('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
map('n', '<C-j>', '<C-w>j', { desc = 'Move to below window' })
map('n', '<C-k>', '<C-w>k', { desc = 'Move to above window' })
map('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- Window resize
map('n', '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Increase window height' })
map('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease window height' })
map('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease window width' })
map('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase window width' })

-- Buffer navigation
map('n', '<S-h>', '<cmd>bprevious<cr>', { desc = 'Prev buffer' })
map('n', '<S-l>', '<cmd>bnext<cr>', { desc = 'Next buffer' })
map('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = 'Delete buffer' })

-- Better movement
map('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Clear search highlight
map('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })

-- Better indenting (stay in visual mode)
map('v', '<', '<gv')
map('v', '>', '>gv')

-- Move lines in visual mode
map('v', 'J', ":m '>+1<cr>gv=gv", { desc = 'Move selection down' })
map('v', 'K', ":m '<-2<cr>gv=gv", { desc = 'Move selection up' })

-- Diagnostic float (]d/[d navigation is an nvim 0.11 default, no need to remap)
map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Diagnostic float' })

-- NOTE: ]q/[q (quickfix), ]l/[l (loclist), ]d/[d (diagnostic) navigation
-- are all nvim 0.11 defaults — don't redefine them here.

-- Spell shortcuts (for when spell is enabled per-filetype)
map('n', '<leader>ss', '<cmd>set spell!<cr>', { desc = 'Toggle spell' })
map('n', '<leader>sn', ']s', { desc = 'Next misspelling' })
map('n', '<leader>sp', '[s', { desc = 'Prev misspelling' })
map('n', '<leader>sa', 'zg', { desc = 'Add to spell dictionary' })
map('n', '<leader>sf', 'z=', { desc = 'Fix spelling (suggest)' })
