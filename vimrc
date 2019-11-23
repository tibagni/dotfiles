" How many lines of history VIM has to remember
set history=100

" Filetype plugins
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from outside
set autoread
au FocusGained,BufEnter * checktime

" Graphical menu for autocomplete
set wildmenu

" Always show cursor position
set ruler

" Configure backspace to work properly in INSERT mode
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Highlight search results
set hlsearch
set incsearch

" Enable syntax highlighting
syntax enable              

" Use spaces for tabs
set expandtab

" TAB = 4 spaces
set tabstop=4
set shiftwidth=4
set softtabstop=4

" Set an hybrid of absolute and relative numbers
set number relativenumber 

" Highlight matching
set showmatch

" Shows the last command in the bottom right
set showcmd

" Draws a horizontal highlight on the line the cursor is currently on
set cursorline

" With a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader=","

" Map ,<space> to clear search highlight
nnoremap <leader><space> :nohlsearch<CR>

" Map ,ss to toggle and untoggle spell checking
map <leader>ss :setlocal spell!<CR>

" Map ,t to open a new tab
map <leader>t :tabnew<CR>

" Map ,g to perform vimgrep recursively
map <leader>g :vimgrep  **/*<left><left><left><left><left>
