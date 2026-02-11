let g:firenvim_config = {
    \ 'globalSettings': {
        \ 'alt': 'all',
    \  },
    \ 'localSettings': {
        \ '.*': {
            \ 'cmdline': 'neovim',
            \ 'content': 'text',
            \ 'priority': 0,
            \ 'selector': 'textarea',
            \ 'takeover': 'always',
        \ },
    \ }
    \ }

let fc = g:firenvim_config['localSettings']

let fc['.*notion\.so.*'] = { 'priority': 9, 'takeover': 'never', }
let fc['.*docs\.google\.com.*'] = { 'priority': 9, 'takeover': 'never', }
let fc['.*chat\.google\.com.*'] = { 'priority': 9, 'takeover': 'never', }

au BufEnter github.com_*.txt set filetype=markdown
au BufEnter gitlab.com_*.txt set filetype=markdown
