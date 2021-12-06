local nvim_lsp = require('lspconfig')

local on_attach = function(client, bufnr)
  -- require('completion').on_attach()

  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', 'gD',         '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd',         '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K',          '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi',         '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>',      '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workleader_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workleader_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workleader_folders()))<CR>', opts)
  buf_set_keymap('n', '<leader>D',  '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', 'gr',         '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<leader>e',   '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d',         '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d',         '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<leader>q',  '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

  -- Set some keybinds conditional on server capabilities
  if client.resolved_capabilities.document_formatting then
    buf_set_keymap("n", "<leader>=", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  elseif client.resolved_capabilities.document_range_formatting then
    buf_set_keymap("n", "<leader>=", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  end

  -- Set autocommands conditional on server_capabilities
  if client.resolved_capabilities.document_highlight then
    vim.api.nvim_exec([[
    augroup lsp_document_highlight
    autocmd! * <buffer>
    autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
    autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
    augroup END
    ]], false)
  end
end

local function make_config()
  local capabilities = require'cmp_nvim_lsp'.update_capabilities(vim.lsp.protocol.make_client_capabilities())

  return {
    capabilities = capabilities,
    on_attach = on_attach,
  }
end

local function setup_servers()
  vim.lsp.set_log_level("debug")
  local lsp_installer = require("nvim-lsp-installer")
  local servers = {
    -- "ansiblels",
    "bashls",
    "cssls",
    "eslint",
    "html",
    -- "gopls",
    "rust_analyzer",
    "solargraph",
    "tailwindcss",
    "terraformls",
    "tflint",
    "vimls",
    "yamlls",
  }

  for _, name in pairs(servers) do
    local ok, server = lsp_installer.get_server(name)
    if ok then
      if not server:is_installed() then
        print("Installing " .. name)
        server:install()
      end
    end
  end

  lsp_installer.on_server_ready(function(server)
    local config = make_config()

    if server.name == "solargraph" then
      config.settings = {
        solargraph = {
          diagnostics = true,
          completion = true,
          definitions = true,
          folding = true,
          hover = true,
          references = true,
          symbols = true,
          useBundler = true,
          bundlerPath = "/home/joel/.asdf/shims/bundle"
        }
      }
    elseif server.name == "tailwindcss" then
      config.settings = {
        tailwindCSS = {
          experimental = {
            classRegex = {  -- for haml :D
              "%\\w+([^\\s]*)",
              "\\.([^\\.]*)",
              ":class\\s*=>\\s*\"([^\"]*)",
              "class:\\s+\"([^\"]*)"
            }
          }
        }
      }
    end

    server:setup(config)
    vim.cmd([[ do User LspAttachBuffers ]])
  end)
end

-- code actions
vim.cmd [[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]]
vim.api.nvim_set_keymap('n', '<leader>a', ':CodeActionMenu<CR>', {noremap = true})

setup_servers()
