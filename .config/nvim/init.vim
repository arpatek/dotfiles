" ┌───────────────────────────────────────────────────────────┐
" │ arpatek – init.vim for Neovim                             │
" │ Zero-dependency fallback for systems where LazyVim is not │
" │ available: nvim < 0.9, no outbound network, or containers │
" └───────────────────────────────────────────────────────────┘
"
" Usage: nvim -u ~/.config/nvim/init.vim
"   or symlink as ~/.config/nvim/init.vim when LazyVim is not installed

set nocompatible
filetype plugin indent on
syntax on

" Line numbers
set number
set relativenumber

" Indentation: 4 spaces
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent

" Search
set hlsearch
set incsearch
set ignorecase
set smartcase

" Display
set ruler
set scrolloff=5
set showcmd
set showmatch
set matchtime=2
set cursorline
set laststatus=2

" Bells
set noerrorbells
set visualbell

" Mouse and clipboard
set mouse=a
if has('clipboard')
  set clipboard=unnamedplus
endif

" Persistent undo
if has('persistent_undo')
  set undofile
  if !isdirectory(expand('~/.vim/undodir'))
    call mkdir(expand('~/.vim/undodir'), 'p')
  endif
  set undodir=~/.vim/undodir
endif

set background=dark
