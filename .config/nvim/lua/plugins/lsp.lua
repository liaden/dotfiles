return {
  -- Mason: auto-install LSP servers (for non-Ruby/non-Rust)
  {
    'mason-org/mason.nvim',
    cmd = 'Mason',
    opts = {},
  },
  {
    'mason-org/mason-lspconfig.nvim',
    dependencies = { 'mason-org/mason.nvim', 'neovim/nvim-lspconfig' },
    opts = {
      ensure_installed = {
        'lua_ls',
        'yamlls',
        'bashls',
        'html',
        'cssls',
        'jsonls',
        'terraformls',
        'texlab',
      },
      -- automatic_enable = true (default) — mason-lspconfig v2 automatically
      -- calls vim.lsp.enable() for all mason-installed servers.
    },
  },

  -- nvim-lspconfig: provides default configs consumed by vim.lsp.config()
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
    },
    config = function()
      -- LspAttach: keymaps set when any LSP client attaches to a buffer
      --
      -- Nvim 0.11 built-in LSP keymaps (DO NOT redefine here):
      --   K          → hover          grn → rename       gO  → document symbols
      --   grr        → references     gra → code action  <C-S> → signature help (insert)
      --   gri        → implementation grt → type definition
      --
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp_keymaps', { clear = true }),
        callback = function(event)
          local bufnr = event.buf
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then return end

          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = 'LSP: ' .. desc })
          end

          -- Go to definition/declaration (not built-in keymaps, though <C-]> works via tagfunc)
          map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
          map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')

          -- <leader> aliases for discoverability (complement the gr* defaults)
          map('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')
          map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
          map('n', '<leader>lf', function() vim.lsp.buf.format({ async = true }) end, 'Format')

          -- Inlay hints toggle (not a built-in keymap)
          if client:supports_method('textDocument/inlayHint') then
            map('n', '<leader>ih', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
            end, 'Toggle inlay hints')
          end
        end,
      })

      -- Diagnostic configuration
      vim.diagnostic.config({
        underline = true,
        severity_sort = true,
        virtual_text = {
          spacing = 4,
          prefix = '●',
        },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = '✘',
            [vim.diagnostic.severity.WARN] = '▲',
            [vim.diagnostic.severity.HINT] = '⚑',
            [vim.diagnostic.severity.INFO] = 'ℹ',
          },
        },
        float = {
          border = 'rounded',
          source = true,
        },
      })

      -- Shared capabilities (integrate with blink.cmp if loaded)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, blink = pcall(require, 'blink.cmp')
      if ok then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      -- Apply shared capabilities to ALL servers
      vim.lsp.config('*', {
        capabilities = capabilities,
      })

      -- Per-server config overrides (consumed by vim.lsp.enable via lspconfig defaults)
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            diagnostics = { globals = { 'vim' } },
          },
        },
      })

      -- Ruby LSP uses asdf to select the project runtime. Ruby LSP manages its
      -- composed bundle itself, so do not wrap the server with bundle exec. Clear
      -- stale chruby variables before asdf selects the project runtime.
      local ruby_lsp_cmd = {
        'env',
        '-u', 'GEM_HOME',
        '-u', 'GEM_PATH',
        '-u', 'GEM_ROOT',
        '-u', 'RUBY_ROOT',
        '-u', 'RUBY_ENGINE',
        '-u', 'RUBY_VERSION',
        'asdf', 'exec', 'ruby-lsp',
      }
      vim.lsp.config('ruby_lsp', {
        cmd = function(dispatchers, config)
          return vim.lsp.rpc.start(ruby_lsp_cmd, dispatchers, { cwd = config.root_dir })
        end,
        root_markers = { 'Gemfile', '.ruby-version', '.ruby-gemset' },
        workspace_required = true, -- don't start in single-file mode outside a project
        init_options = {
          formatter = 'auto',      -- auto-detects rubocop from bundle
          linters = { 'rubocop' }, -- uses project's rubocop
        },
      })
      vim.lsp.enable('ruby_lsp')

      -- Debug command: show what LSP servers are running and how they were found
      vim.api.nvim_create_user_command('LspDebug', function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          print('No LSP clients attached to this buffer')
          return
        end
        for _, client in ipairs(clients) do
          print(string.format(
            'LSP: %s | cmd: %s | root: %s',
            client.name,
            vim.inspect(client.config.cmd),
            client.root_dir or 'nil'
          ))
        end
      end, { desc = 'Show LSP debug info for current buffer' })
    end,
  },
}
