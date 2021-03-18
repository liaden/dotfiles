nnoremap <leader>bs :CocCommand fzf-preview.Buffers<CR>
nnoremap <leader>fs :CocCommand fzf-preview.ProjectFiles<CR>
nnoremap <leader>fr :CocCommand fzf-preview.ProjectMruFiles<CR>
nnoremap <leader>fq :CocCommand fzf-preview.QuickFix<CR>
nnoremap <leader>fr :CocCommand fzf-preview.Yankround<CR>
nnoremap <leader>fh :CocCommand fzf-preview.Jumps<CR>

" command history search
nnoremap <leader>cs :CocCommand fzf-preview.CommandPalette<CR>
cnoremap <c-f> <c-b>CocCommand fzf-preview.CommandPalette --add-fzf-arg=--query="<c-e>"<CR>

let g:fzf_preview_dev_icon_prefix_string_length = 3
