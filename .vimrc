call plug#begin('~/.vim/plugged')

if has('nvim')
    Plug 'neoclide/coc.nvim', {'branch': 'release'} " Code Completion
endif
Plug 'christoomey/vim-tmux-navigator' " Easier Tmux and Vim split navigation
Plug 'romainl/Apprentice' " A pretty color scheme
call plug#end()
colorscheme apprentice
syntax on
set clipboard=unnamedplus

set autoindent
set expandtab
set tabstop=2
set shiftwidth=2
set colorcolumn=101

set number
set relativenumber

let g:netrw_banner = 0
autocmd vimenter * if !argc() | E | endif


" coc.nvim bindings
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
