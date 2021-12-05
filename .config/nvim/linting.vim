let g:ale_open_list = 0
let g:ale_set_loclist = 1
let g:ale_set_quickfix = 0

nnoremap <leader>xx <cmd>LspTroubleToggle<cr>
nnoremap <leader>xw <cmd>LspTroubleToggle lsp_workspace_diagnostics<cr>
nnoremap <leader>xd <cmd>LspTroubleToggle lsp_document_diagnostics<cr>
nnoremap <leader>xq <cmd>LspTroubleToggle quickfix<cr>
nnoremap <leader>xl <cmd>LspTroubleToggle loclist<cr>
" nnoremap gR <cmd>LspTroubleToggle lsp_references<cr>
