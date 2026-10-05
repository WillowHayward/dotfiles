" A vimrc disables the built-in defaults (syntax, incsearch, ...); load them back.
unlet! skip_defaults_mod
source $VIMRUNTIME/defaults.vim

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

" Ctrl-h/j/k/l move between splits and, past the edge, between tmux panes. The tmux side is the
" vim-tmux-navigator plugin (shell/.tmux.conf); this is its Vim half without a plugin manager.
function! s:TmuxNavigate(key, direction) abort
  let l:window = winnr()
  execute 'wincmd ' . a:key
  if l:window == winnr() && !empty($TMUX)
    silent call system('tmux select-pane -' . a:direction)
  endif
endfunction
nnoremap <silent> <C-h> :call <SID>TmuxNavigate('h', 'L')<CR>
nnoremap <silent> <C-j> :call <SID>TmuxNavigate('j', 'D')<CR>
nnoremap <silent> <C-k> :call <SID>TmuxNavigate('k', 'U')<CR>
nnoremap <silent> <C-l> :call <SID>TmuxNavigate('l', 'R')<CR>

