" ┌───────────────────────────────────────────────────────────┐
" │ arpatek – .vimrc                                          │
" │ Minimalist Vim config for DevOps, automation, and CLI     │
" │ workflows. Designed for speed, clarity, and compatibility │
" │ across provisioned Debian-based systems.                  │
" └───────────────────────────────────────────────────────────┘

" Disable compatibility with vi (removes legacy quirks)
set nocompatible

" Enable filetype detection
filetype on

" Load filetype-specific plugins
filetype plugin on

" Load filetype-specific indentation rules
filetype indent on

" Enable syntax highlighting
syntax on

" Show line numbers
set number

" Use 4 spaces per indentation level (Python/dev-friendly)
set shiftwidth=4

" Set tab character to display as 4 columns wide
set tabstop=4

" Convert tabs to spaces
set expandtab

" Enable automatic indentation for new lines
set smartindent

" Highlight search results
set hlsearch

" Show matching brackets when cursor is over them
set showmatch

" Enable incremental search (shows matches as you type)
set incsearch

" Case-insensitive search unless capital letters are used
set ignorecase
set smartcase

" Show cursor position (line and column)
set ruler

" Keep 5 lines visible when scrolling
set scrolloff=5

" Show command in bottom bar
set showcmd

" Disable error bells (audible beeps)
set noerrorbells
set visualbell

" Enable mouse support in all modes
set mouse=a

" Use system clipboard
set clipboard=unnamedplus

" Keep undo history across sessions (requires Vim compiled with +persistent_undo)
if has("persistent_undo")
  set undofile
  set undodir=~/.vim/undodir
endif

" Set background to dark for better theme contrast
set background=dark
