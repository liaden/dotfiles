return {
  -- conform.nvim: formatting for non-Ruby/non-Rust files
  -- Ruby uses ruby-lsp's built-in formatting
  -- Rust uses rust-analyzer's built-in formatting
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    cmd = 'ConformInfo',
    opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        yaml = { 'prettier' },
        json = { 'prettier' },
        html = { 'prettier' },
        css = { 'prettier' },
        javascript = { 'prettier' },
        typescript = { 'prettier' },
        markdown = { 'prettier' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
      },
      format_on_save = {
        timeout_ms = 3000,
        lsp_format = 'fallback', -- use LSP formatting if no conform formatter
      },
    },
  },
}
