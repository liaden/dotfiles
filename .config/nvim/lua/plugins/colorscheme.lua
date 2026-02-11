return {
  -- Primary: nightfox.nvim with protanopia correction
  {
    'EdenEast/nightfox.nvim',
    lazy = false,
    priority = 1000, -- load before all other plugins
    config = function()
      require('nightfox').setup({
        options = {
          colorblind = {
            enable = true,
            simulate_only = false, -- actually shift colors
            severity = {
              protan = 1.0,  -- full protanopia correction
              deutan = 0.0,
              tritan = 0.0,
            },
          },
          styles = {
            comments = 'italic',
            keywords = 'bold',
            functions = 'NONE',
          },
          dim_inactive = true,
        },
      })
      vim.cmd('colorscheme nightfox')
    end,
  },

  -- Secondary themes (lazy-loaded, available via :colorscheme)
  { 'catppuccin/nvim', name = 'catppuccin', lazy = true },
  { 'folke/tokyonight.nvim', lazy = true },
  { 'rebelot/kanagawa.nvim', lazy = true },
}
