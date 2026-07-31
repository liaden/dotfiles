return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      -- Adapters:
      'olimorris/neotest-rspec',
      'mrcjkb/rustaceanvim',
    },
    cmd = 'Neotest',
    config = function()
      require('neotest').setup({
        adapters = {
          require('neotest-rspec')({
            rspec_cmd = function()
              return { 'bundle', 'exec', 'rspec' }
            end,
          }),
          require('rustaceanvim.neotest'),
        },
      })
    end,
    keys = {
      { '<leader>tn', function() require('neotest').run.run() end, desc = 'Run nearest test' },
      { '<leader>tf', function() require('neotest').run.run(vim.fn.expand('%')) end, desc = 'Run file tests' },
      { '<leader>ts', function() require('neotest').summary.toggle() end, desc = 'Toggle test summary' },
      { '<leader>to', function() require('neotest').output.open({ enter = true }) end, desc = 'Show test output' },
      { '<leader>tp', function() require('neotest').output_panel.toggle() end, desc = 'Toggle output panel' },
      { '<leader>tl', function() require('neotest').run.run_last() end, desc = 'Re-run last test' },
    },
  },
}
