return {
  -- VimTeX: comprehensive LaTeX editing support
  -- Compilation, PDF viewer sync, motions, text objects, TOC, folding
  {
    'lervag/vimtex',
    lazy = false, -- VimTeX handles its own lazy-loading via ftplugin
    init = function()
      -- PDF viewer with SyncTeX (forward/inverse search)
      --
      -- macOS:  Skim (brew install --cask skim)
      --         Inverse search: Skim → Preferences → Sync → Preset: Custom
      --           Command: nvim, Arguments: --headless -c "VimtexInverseSearch %line '%file'"
      --
      -- Linux:  Zathura (best), Okular, or Evince — auto-detected below
      --         Zathura: sudo apt install zathura / pacman -S zathura zathura-pdf-mupdf
      --
      if vim.fn.has('macunix') == 1 then
        vim.g.vimtex_view_method = 'skim'
      elseif vim.fn.executable('zathura') == 1 then
        vim.g.vimtex_view_method = 'zathura' -- lightweight, great SyncTeX support
      elseif vim.fn.executable('okular') == 1 then
        vim.g.vimtex_view_method = 'general'
        vim.g.vimtex_view_general_viewer = 'okular'
        vim.g.vimtex_view_general_options = '--unique file:@pdf\\#src:@line@tex'
      elseif vim.fn.executable('evince') == 1 then
        vim.g.vimtex_view_method = 'general'
        vim.g.vimtex_view_general_viewer = 'evince'
      else
        vim.g.vimtex_view_method = 'general' -- fallback: xdg-open
      end

      -- Compiler: latexmk (default) with continuous mode
      vim.g.vimtex_compiler_method = 'latexmk'
      vim.g.vimtex_compiler_latexmk = {
        options = {
          '-pdf',
          '-shell-escape',     -- needed for minted, tikz externalize, etc.
          '-verbose',
          '-file-line-error',
          '-synctex=1',
          '-interaction=nonstopmode',
        },
      }

      -- Don't open quickfix on warnings, only errors
      vim.g.vimtex_quickfix_mode = 2
      vim.g.vimtex_quickfix_open_on_warning = 0

      -- Use treesitter for syntax highlighting inside code blocks
      vim.g.vimtex_syntax_conceal_disable = 0

      -- Disable default mappings that conflict; we'll define our own under <leader>l
      vim.g.vimtex_mappings_prefix = '<localleader>'
    end,
    keys = {
      { '<leader>ll', '<cmd>VimtexCompile<cr>',        desc = 'LaTeX: Toggle continuous compile' },
      { '<leader>lv', '<cmd>VimtexView<cr>',            desc = 'LaTeX: View PDF (forward search)' },
      { '<leader>lt', '<cmd>VimtexTocToggle<cr>',       desc = 'LaTeX: Toggle table of contents' },
      { '<leader>le', '<cmd>VimtexErrors<cr>',          desc = 'LaTeX: Show errors' },
      { '<leader>lc', '<cmd>VimtexClean<cr>',           desc = 'LaTeX: Clean aux files' },
      { '<leader>lC', '<cmd>VimtexClean!<cr>',          desc = 'LaTeX: Clean aux + output files' },
      { '<leader>ls', '<cmd>VimtexStop<cr>',            desc = 'LaTeX: Stop compiler' },
      { '<leader>li', '<cmd>VimtexInfo<cr>',            desc = 'LaTeX: Show VimTeX info' },
    },
    -- VimTeX provides these text objects out of the box:
    --   ie / ae  → LaTeX environment (\begin{...} ... \end{...})
    --   i$ / a$  → Inline math
    --   id / ad  → Delimiter pairs (\left( ... \right))
    --   ic / ac  → LaTeX command
    -- And motions:
    --   ]]  → next section
    --   [[  → prev section
    --   ]m  → next environment
    --   [m  → prev environment
  },
}
