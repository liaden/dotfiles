require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  },
  folding = {
    enable = true,
  },
  playground = {
    enable = true,
  },
  textobjects = {
    select = {
      enable = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["aC"] = "@class.outer",
        ["iC"] = "@class.inner",
        ["a#"] = "@comment.outer",
        ["al"] = "@loop.outer",
        ["il"] = "@loop.inner",
        ["aP"] = "@parameter.outer",
        ["iP"] = "@paramter.inner",
        ["a?"] = "@conditional.outer",
        ["i?"] = "@conditional.inner",
      },
    },
    swap = {
      enable = true,
    },
    move = {
      enable = true,

    },
  },
}
