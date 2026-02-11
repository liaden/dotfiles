-- LaTeX-specific settings
vim.opt_local.spell = true
vim.opt_local.spelllang = { 'en_us' }
vim.opt_local.spelloptions:append('camel')
vim.opt_local.spellcapcheck = '' -- don't flag lowercase after periods in LaTeX

-- Soft wrap for long paragraphs
vim.opt_local.wrap = true
vim.opt_local.linebreak = true      -- wrap at word boundaries, not mid-character
vim.opt_local.breakindent = true    -- indent wrapped lines to match indent level

-- Navigate by visual lines when wrapped
vim.keymap.set('n', 'j', 'gj', { buffer = true, desc = 'Down (visual line)' })
vim.keymap.set('n', 'k', 'gk', { buffer = true, desc = 'Up (visual line)' })

-- 80-char textwidth for hard-wrapping (use `gq` to reflow); set to 0 if you prefer soft-wrap only
vim.opt_local.textwidth = 0

-- Conceal level: show rendered symbols (e.g., \alpha → α) but reveal on cursor line
vim.opt_local.conceallevel = 2
vim.opt_local.concealcursor = ''    -- reveal conceal on current line in all modes
