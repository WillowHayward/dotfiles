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

" Neovim LSP
" Courtesy of https://jose-elias-alvarez.medium.com/configuring-neovims-lsp-client-for-typescript-development-5789d58ea9c
lua << EOF
local lspconfig = require("lspconfig")local buf_map = function(bufnr, mode, lhs, rhs, opts)
    vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts or {
        silent = true,
    })
end
local on_attach = function(client, bufnr)
    vim.cmd("command! LspDef lua vim.lsp.buf.definition()")
    vim.cmd("command! LspFormatting lua vim.lsp.buf.formatting()")
    vim.cmd("command! LspCodeAction lua vim.lsp.buf.code_action()")
    vim.cmd("command! LspHover lua vim.lsp.buf.hover()")
    vim.cmd("command! LspRename lua vim.lsp.buf.rename()")
    vim.cmd("command! LspRefs lua vim.lsp.buf.references()")
    vim.cmd("command! LspTypeDef lua vim.lsp.buf.type_definition()")
    vim.cmd("command! LspImplementation lua vim.lsp.buf.implementation()")
    vim.cmd("command! LspDiagPrev lua vim.lsp.diagnostic.goto_prev()")
    vim.cmd("command! LspDiagNext lua vim.lsp.diagnostic.goto_next()")
    vim.cmd("command! LspDiagLine lua vim.lsp.diagnostic.show_line_diagnostics()")
    vim.cmd("command! LspSignatureHelp lua vim.lsp.buf.signature_help()")    buf_map(bufnr, "n", "gd", ":LspDef<CR>")
    buf_map(bufnr, "n", "gr", ":LspRename<CR>")
    buf_map(bufnr, "n", "gy", ":LspTypeDef<CR>")
    buf_map(bufnr, "n", "K", ":LspHover<CR>")
    buf_map(bufnr, "n", "[a", ":LspDiagPrev<CR>")
    buf_map(bufnr, "n", "]a", ":LspDiagNext<CR>")
    buf_map(bufnr, "n", "ga", ":LspCodeAction<CR>")
    buf_map(bufnr, "n", "<Leader>a", ":LspDiagLine<CR>")
    buf_map(bufnr, "i", "<C-x><C-x>", "<cmd> LspSignatureHelp<CR>")    
	if client.resolved_capabilities.document_formatting then
        vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()")
    end
end
lspconfig.tsserver.setup({
    on_attach = function(client, bufnr)
        client.resolved_capabilities.document_formatting = false
        client.resolved_capabilities.document_range_formatting = false
        local ts_utils = require("nvim-lsp-ts-utils")
        ts_utils.setup({
            eslint_bin = "eslint_d",
            eslint_enable_diagnostics = true,
            eslint_enable_code_actions = true,
            enable_formatting = true,
            formatter = "prettier",
        })
        ts_utils.setup_client(client)        
        buf_map(bufnr, "n", "gs", ":TSLspOrganize<CR>")
        buf_map(bufnr, "n", "gi", ":TSLspRenameFile<CR>")
        buf_map(bufnr, "n", "go", ":TSLspImportAll<CR>")        
        on_attach(client, bufnr)
    end,
})
require("null-ls").config({})
lspconfig["null-ls"].setup({ on_attach = on_attach })

EOF

" Code Completion
set completeopt=menu,menuone,noselect

lua <<EOF
  -- Setup nvim-cmp.
  local cmp = require'cmp'

  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
        -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
        -- require'snippy'.expand_snippet(args.body) -- For `snippy` users.
      end,
    },
    -- Keybindings
    mapping = {
      ['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
      ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
      ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
      ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
      ['<C-e>'] = cmp.mapping({
        i = cmp.mapping.abort(),
        c = cmp.mapping.close(),
      }),
      ['<CR>'] = cmp.mapping.confirm({ select = true }),
      ['<Tab>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 's' }),
      ['<S-Tab>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 's' })
    },
    experimental = {
        ghost_text = true,
    },
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'vsnip' }, 
    }, {
      { name = 'buffer' },
    })
  })

  -- Setup lspconfig.
  local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
  -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
  require('lspconfig')['tsserver'].setup {
    capabilities = capabilities
  }
EOF
