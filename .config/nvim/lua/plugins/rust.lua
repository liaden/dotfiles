return {
  -- Rustaceanvim: all-in-one Rust plugin (LSP, DAP, extras)
  {
    'mrcjkb/rustaceanvim',
    version = '^9',
    lazy = false, -- already lazy by design (only loads for .rs files)
    init = function()
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            ['rust-analyzer'] = {
              cargo = { features = 'all' },
              checkOnSave = true,
              check = { command = 'clippy' },
            },
          },
        },
      }
    end,
  },

  -- Crates: inline Cargo.toml dependency info
  {
    'saecki/crates.nvim',
    event = { 'BufRead Cargo.toml' },
    opts = {},
  },
}
