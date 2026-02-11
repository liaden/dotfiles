return {
  {
    'saghen/blink.cmp',
    version = '*',
    event = 'InsertEnter',
    dependencies = {
      'rafamadriz/friendly-snippets', -- community snippet collection
    },
    opts = {
      -- NOTE: The 'default' preset already includes <C-space>, <C-e>, <CR>,
      -- <Tab>/<S-Tab>, <C-n>/<C-p>, <C-d>/<C-u> — no need to restate them.
      keymap = { preset = 'default' },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      completion = {
        documentation = { auto_show = true },
        ghost_text = { enabled = true },
      },
      signature = { enabled = true }, -- built-in signature help
      appearance = {
        nerd_font_variant = 'mono',
      },
    },
  },
}
