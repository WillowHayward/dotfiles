call plug#begin('~/.vim/plugged')

if has('nvim')
    Plug 'neoclide/coc.nvim', {'branch': 'release'} " Code Completion
    "Plug 'neovim/nvim-lspconfig' " Code completion, when I get around to
    "setting it up properly
endif
Plug 'christoomey/vim-tmux-navigator' " Easier Tmux and Vim split navigation
Plug 'Yggdroot/indentLine' " Vertical lines to visually indicate indentation levels
Plug 'romainl/Apprentice' " A pretty color scheme
call plug#end()
colorscheme apprentice
syntax on

" Disable automatic line wrapping in git commits
autocmd Syntax gitcommit setlocal nowrap

" indentLine settings
let g:indentLine_setColors = 0

set autoindent
set expandtab
set tabstop=4
set shiftwidth=4
set colorcolumn=101

set number
set relativenumber

set ignorecase
set smartcase

let g:netrw_banner = 0

" Indenting a visual selection remains in visual mode afterwards
vnoremap > >gv
vnoremap < <gv

" provide hjkl movements in Insert mode via the <Alt> modifier key
inoremap <A-h> <C-o>h
inoremap <A-j> <C-o>j
inoremap <A-k> <C-o>k
inoremap <A-l> <C-o>l

" Alt-jk in normal mode centres screen
nnoremap <A-j> zzj
nnoremap <A-k> zzk

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
