-- AI plugins: DEFERRED
-- Uncomment when ready to activate. Detection logic is in place.

local has_ollama = vim.fn.executable('ollama') == 1
local has_anthropic_key = vim.env.ANTHROPIC_API_KEY ~= nil
local is_linux = vim.fn.has('linux') == 1

return {
  -- Inline completions (ghost text)
  -- Uncomment ONE of these when ready:

  -- Option A: Supermaven (free tier available, no Copilot needed)
  -- {
  --   'supermaven-inc/supermaven-nvim',
  --   cond = not vim.g.vscode and not vim.g.started_by_firenvim,
  --   event = 'InsertEnter',
  --   opts = {},
  -- },

  -- Option B: Codeium (free for individuals)
  -- {
  --   'Exafunction/codeium.vim',
  --   cond = not vim.g.vscode and not vim.g.started_by_firenvim,
  --   event = 'InsertEnter',
  -- },

  -- Chat / interactive AI
  -- {
  --   'olimorris/codecompanion.nvim',
  --   cond = not vim.g.vscode and not vim.g.started_by_firenvim,
  --   dependencies = {
  --     'nvim-lua/plenary.nvim',
  --     'nvim-treesitter/nvim-treesitter',
  --   },
  --   config = function()
  --     local adapter = 'anthropic'
  --     if has_ollama and is_linux then
  --       adapter = 'ollama'
  --     end
  --     require('codecompanion').setup({
  --       strategies = {
  --         chat = { adapter = adapter },
  --         inline = { adapter = adapter },
  --       },
  --       adapters = {
  --         ollama = function()
  --           return require('codecompanion.adapters').extend('ollama', {
  --             schema = {
  --               model = { default = 'qwen2.5-coder:7b' },
  --             },
  --           })
  --         end,
  --       },
  --     })
  --   end,
  --   keys = {
  --     { '<leader>ai', '<cmd>CodeCompanionChat Toggle<cr>', desc = 'AI Chat' },
  --     { '<leader>ae', '<cmd>CodeCompanionActions<cr>', desc = 'AI Actions' },
  --     { '<leader>aa', '<cmd>CodeCompanionChat Add<cr>', mode = 'v', desc = 'AI Add selection' },
  --   },
  -- },
}
