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

