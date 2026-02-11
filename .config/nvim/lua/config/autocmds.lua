-- config/autocmds.lua — Autocommands for standalone neovim
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Highlight on yank (replaces vim-highlightedyank plugin)
autocmd('TextYankPost', {
  group = augroup('highlight_yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 200 })
  end,
})

-- Resize splits when terminal is resized
autocmd('VimResized', {
  group = augroup('resize_splits', { clear = true }),
  callback = function()
    vim.cmd('tabdo wincmd =')
  end,
})

-- Go to last cursor position when opening a file
autocmd('BufReadPost', {
  group = augroup('last_cursor_position', { clear = true }),
  callback = function(event)
    local exclude = { 'gitcommit' }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_pos then
      return
    end
    vim.b[buf].last_pos = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close some filetypes with <q>
autocmd('FileType', {
  group = augroup('close_with_q', { clear = true }),
  pattern = { 'help', 'lspinfo', 'notify', 'qf', 'checkhealth' },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
  end,
})

-- Auto-create parent directories when saving a file
autocmd('BufWritePre', {
  group = augroup('auto_create_dir', { clear = true }),
  callback = function(event)
    if event.match:match('^%w%w+:[\\/][\\/]') then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
})

-- Strip trailing whitespace on save (replaces vim-better-whitespace)
autocmd('BufWritePre', {
  group = augroup('trim_whitespace', { clear = true }),
  pattern = '*',
  callback = function()
    if not vim.bo.modifiable or vim.bo.readonly then return end
    local save_cursor = vim.fn.getpos('.')
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos('.', save_cursor)
  end,
})

-- Auto-compile custom spell dictionary if edited outside of Neovim
-- (zg adds words AND compiles automatically; this catches manual edits to the .add file)
autocmd('VimEnter', {
  group = augroup('compile_spellfile', { clear = true }),
  callback = function()
    local add_file = vim.fn.stdpath('config') .. '/spell/code.utf-8.add'
    local spl_file = add_file .. '.spl'
    local add_stat = vim.uv.fs_stat(add_file)
    local spl_stat = vim.uv.fs_stat(spl_file)
    if add_stat and (not spl_stat or add_stat.mtime.sec > spl_stat.mtime.sec) then
      vim.cmd('mkspell! ' .. vim.fn.fnameescape(add_file))
    end
  end,
})

-- Detect bare git repo for dotfiles fugitive integration
autocmd('BufEnter', {
  group = augroup('dotfiles_fugitive', { clear = true }),
  callback = function()
    local home = vim.env.HOME
    local cfg_dir = home .. '/.cfg'
    if vim.fn.getcwd() == home and vim.fn.isdirectory(cfg_dir) == 1 then
      vim.env.GIT_DIR = cfg_dir
      vim.env.GIT_WORK_TREE = home
    end
  end,
})
