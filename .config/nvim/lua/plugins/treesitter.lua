-- nvim-treesitter `main` branch: the frozen `master` branch broke on nvim 0.12
-- (query-directive API changes crash markdown injection parsing). `main` has no
-- module system: parsers install explicitly, highlight/indent enable per-buffer.
-- Requires tree-sitter-cli (npm i -g tree-sitter-cli).

-- Parsers beyond nvim 0.12's bundled set (markdown, markdown_inline, lua, vim,
-- vimdoc, c, query ship with nvim itself).
local ensure_installed = {
  'ruby', 'rust', 'bash', 'json', 'yaml', 'toml', 'html', 'css',
  'javascript', 'typescript', 'regex', 'diff', 'gitcommit', 'git_rebase',
  'dockerfile', 'terraform', 'sql', 'latex', 'bibtex',
  -- Note: 'org' parser is installed by orgmode.nvim, not nvim-treesitter
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    lazy = false, -- main branch registers no lazy-loadable modules; load eagerly
    config = function()
      require('nvim-treesitter').install(ensure_installed)

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter_start', { clear = true }),
        callback = function(event)
          -- Skip org: orgmode manages its own treesitter + regex highlighting
          if event.match == 'org' then return end
          local ok = pcall(vim.treesitter.start, event.buf)
          if ok then
            vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('nvim-treesitter-textobjects').setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      local function select_map(lhs, query, desc)
        vim.keymap.set({ 'x', 'o' }, lhs, function()
          require('nvim-treesitter-textobjects.select').select_textobject(query, 'textobjects')
        end, { desc = desc })
      end

      select_map('af', '@function.outer', 'outer function')
      select_map('if', '@function.inner', 'inner function')
      select_map('ac', '@class.outer', 'outer class')
      select_map('ic', '@class.inner', 'inner class')
      select_map('aa', '@parameter.outer', 'outer argument')
      select_map('ia', '@parameter.inner', 'inner argument')
      select_map('ai', '@conditional.outer', 'outer conditional')
      select_map('ii', '@conditional.inner', 'inner conditional')
      select_map('al', '@loop.outer', 'outer loop')
      select_map('il', '@loop.inner', 'inner loop')
      select_map('ab', '@block.outer', 'outer block')
      select_map('ib', '@block.inner', 'inner block')

      local move = require('nvim-treesitter-textobjects.move')
      local function move_map(lhs, fn, query, desc)
        vim.keymap.set({ 'n', 'x', 'o' }, lhs, function()
          fn(query, 'textobjects')
        end, { desc = desc })
      end

      move_map(']f', move.goto_next_start, '@function.outer', 'Next function start')
      move_map(']c', move.goto_next_start, '@class.outer', 'Next class start')
      move_map('[f', move.goto_previous_start, '@function.outer', 'Prev function start')
      move_map('[c', move.goto_previous_start, '@class.outer', 'Prev class start')

      vim.keymap.set('n', '<leader>xp', function()
        require('nvim-treesitter-textobjects.swap').swap_next('@parameter.inner')
      end, { desc = 'Swap next parameter' })
      vim.keymap.set('n', '<leader>xP', function()
        require('nvim-treesitter-textobjects.swap').swap_previous('@parameter.inner')
      end, { desc = 'Swap previous parameter' })
    end,
  },

  -- nvim-treesitter-endwise dropped: it depends on master's module system and
  -- master is frozen/incompatible with nvim 0.12. Revisit an alternative for
  -- auto-`end` in Ruby/Lua if its absence stings.
}
