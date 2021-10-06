vim.o.completeopt = "menu,menuone,noselect"

local cmp = require'cmp'
local lspkind = require'lspkind'
lspkind.init{with_test = true}

cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = {
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
  },
  completion = {
    completopt = 'menu,menuone,noinsert',
  },
  formatting = {
    format = function(entry, vim_item)
      vim_item.kind = lspkind.presets.default[vim_item.kind] .. " " .. vim_item.kind
      vim_item.menu = ({
        buffer = "[Buffer]",
        nvim_lsp = "[LSP]",
        luasnip = "[LuaSnip]",
        nvim_lua = "[Lua]",
      })[entry.source.name]
      return vim_item
    end
  }
})


--vim.api.nvim_set_keymap("i", "<Tab>", "compe#confirm({ 'keys': '<CR>', 'select': v:true })", { expr = true })
--vim.api.nvim_set_keymap("i", "<S-Tab>", "compe#complete()", { expr = true })
--vim.api.nvim_set_keymap("i", "<S-CR>", "compe#confirm({ 'keys': '<CR>', 'select': v:true })", { expr = true })
--vim.api.nvim_set_keymap("i", "<C-Space>", "compe#complete()", { expr = true })
