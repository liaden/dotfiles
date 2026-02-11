return {
  -- Rustaceanvim: all-in-one Rust plugin (LSP, DAP, extras)
  {
    'mrcjkb/rustaceanvim',
    version = '^5',
    lazy = false, -- already lazy by design (only loads for .rs files)
    init = function()
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            ['rust-analyzer'] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
              },
              checkOnSave = {
                command = 'clippy', -- use clippy instead of cargo check
              },
              procMacro = { enable = true },
              diagnostics = {
                enable = true,
                experimental = { enable = true },
              },
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

  -- neotest-rust adapter (loaded by neotest in testing.lua)
  {
    'rouge8/neotest-rust',
    ft = 'rust',
  },
}
