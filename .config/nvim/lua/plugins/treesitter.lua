return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master', -- pin to legacy branch; 'main' requires tree-sitter-cli
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'master' },
      'RRethy/nvim-treesitter-endwise',
    },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'ruby', 'rust', 'lua', 'vim', 'vimdoc', 'query',
          'bash', 'json', 'yaml', 'toml', 'html', 'css',
          'javascript', 'typescript', 'markdown', 'markdown_inline',
          'regex', 'diff', 'gitcommit', 'git_rebase',
          'dockerfile', 'terraform', 'sql', 'c', 'latex', 'bibtex',
          -- Note: 'org' parser is installed by orgmode.nvim, not nvim-treesitter
        },
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = { 'org' }, -- for orgmode
        },
        indent = { enable = true },
        endwise = { enable = true }, -- auto-insert `end` for Ruby, Lua, etc.
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- jump forward to textobject
            keymaps = {
              ['af'] = { query = '@function.outer', desc = 'outer function' },
              ['if'] = { query = '@function.inner', desc = 'inner function' },
              ['ac'] = { query = '@class.outer', desc = 'outer class' },
              ['ic'] = { query = '@class.inner', desc = 'inner class' },
              ['aa'] = { query = '@parameter.outer', desc = 'outer argument' },
              ['ia'] = { query = '@parameter.inner', desc = 'inner argument' },
              ['ai'] = { query = '@conditional.outer', desc = 'outer conditional' },
              ['ii'] = { query = '@conditional.inner', desc = 'inner conditional' },
              ['al'] = { query = '@loop.outer', desc = 'outer loop' },
              ['il'] = { query = '@loop.inner', desc = 'inner loop' },
              ['ab'] = { query = '@block.outer', desc = 'outer block' },
              ['ib'] = { query = '@block.inner', desc = 'inner block' },
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              [']f'] = '@function.outer',
              [']c'] = '@class.outer',
            },
            goto_prev_start = {
              ['[f'] = '@function.outer',
              ['[c'] = '@class.outer',
            },
          },
          swap = {
            enable = true,
            swap_next = { ['<leader>xp'] = '@parameter.inner' },
            swap_previous = { ['<leader>xP'] = '@parameter.inner' },
          },
        },
      })
    end,
  },
}
