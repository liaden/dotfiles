return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      -- DAP UI
      {
        'rcarriga/nvim-dap-ui',
        dependencies = { 'nvim-neotest/nvim-nio' },
        opts = {},
        keys = {
          { '<leader>du', function() require('dapui').toggle() end, desc = 'DAP UI toggle' },
        },
      },
      -- Inline variable values
      {
        'theHamsta/nvim-dap-virtual-text',
        opts = {},
      },
    },
    keys = {
      { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Toggle breakpoint' },
      { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input('Condition: ')) end, desc = 'Conditional breakpoint' },
      { '<leader>dc', function() require('dap').continue() end, desc = 'Continue' },
      { '<leader>dC', function() require('dap').run_to_cursor() end, desc = 'Run to cursor' },
      { '<leader>di', function() require('dap').step_into() end, desc = 'Step into' },
      { '<leader>do', function() require('dap').step_over() end, desc = 'Step over' },
      { '<leader>dO', function() require('dap').step_out() end, desc = 'Step out' },
      { '<leader>dr', function() require('dap').repl.open() end, desc = 'REPL' },
      { '<leader>dl', function() require('dap').run_last() end, desc = 'Run last' },
      { '<leader>dx', function() require('dap').terminate() end, desc = 'Terminate' },
    },
    config = function()
      local dap = require('dap')

      -- Ruby DAP adapter (rdbg from debug gem, Ruby 3.1+)
      dap.adapters.ruby = function(callback, config)
        callback({
          type = 'server',
          host = '127.0.0.1',
          port = '${port}',
          executable = {
            command = 'bundle',
            args = { 'exec', 'rdbg', '-n', '--open', '--port', '${port}',
                     '-c', '--', config.command, unpack(config.args or {}) },
          },
        })
      end

      dap.configurations.ruby = {
        {
          type = 'ruby',
          name = 'Debug current file',
          request = 'launch',
          command = 'ruby',
          args = { '${file}' },
        },
        {
          type = 'ruby',
          name = 'Debug RSpec (current file)',
          request = 'launch',
          command = 'bundle',
          args = { 'exec', 'rspec', '${file}' },
        },
        {
          type = 'ruby',
          name = 'Attach to rdbg',
          request = 'attach',
          localfs = true,
        },
      }

      -- Rust DAP is auto-configured by rustaceanvim when nvim-dap is present
      -- Just ensure codelldb is installed: :MasonInstall codelldb

      -- Auto-open/close DAP UI
      local dapui = require('dapui')
      dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
      dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
      dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end
    end,
  },
}
