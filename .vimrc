call plug#begin('~/.vim/plugged')

if has('nvim')
    " Set up Neovim LSP
    Plug 'neovim/nvim-lspconfig'
    Plug 'jose-elias-alvarez/null-ls.nvim'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'jose-elias-alvarez/nvim-lsp-ts-utils'

    " Code Completion
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'hrsh7th/cmp-buffer'
    Plug 'hrsh7th/cmp-vsnip'
    Plug 'hrsh7th/vim-vsnip'
    Plug 'hrsh7th/nvim-cmp'
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

let g:netrw_banner = 0


" Neovim LSP
lua << EOF
EOF

" Code Completion
set completeopt=
