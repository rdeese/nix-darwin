" Turn off mouse
set mouse=

" use two spaces for indents, and make them actual spaces
set shiftwidth=2
set tabstop=2
set autoindent
set expandtab

set number
syntax enable
set background=light
colorscheme solarized8
set nobackup
filetype indent on
filetype plugin on
set noincsearch

" try out syntax folding by default
let php_folding=2
set foldminlines=5
autocmd Syntax * setlocal foldmethod=syntax
autocmd Syntax * normal zR

" Set <Leader> key
let mapleader=','

" reduce length of timeout waiting for rest of command
set timeoutlen=300 " ms

" Keep space around the cursor when scrolling
set scrolloff=8

" To encourage macro usage
nnoremap <Space> @q

" Shortcut for deleting into the null register ("_), to preserve clipboard
" contents
nnoremap -d "_d

" change split opening to bottom and right instead of top and left
set splitbelow
set splitright

" Clear search highlighting with Esc in normal mode
nnoremap <silent> <Esc> :nohlsearch<CR>

" remap windowswap to a ctrl-w command
let g:windowswap_map_keys = 0 "prevent default bindings
nnoremap <silent> <C-W>y :call WindowSwap#EasyWindowSwap()<CR>

" Grepper

" Use rg over grep
if executable('rg')
  set grepprg=rg\ --nogroup\ --nocolor
endif

" Use Grepper to search for the word under the cursor using rg
" (replaces backwards identifier search)
nnoremap # :Grepper -cword -noprompt<CR>

" Use \ as a shortcut for :Grepper
nnoremap \ :Grepper<CR>

nmap gw <plug>(GrepperOperator)
xmap gw <plug>(GrepperOperator)

" let g:grepper.tools =
"   \ ['rg', 'git', 'ack']
