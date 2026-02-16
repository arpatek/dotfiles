" ┌───────────────────────────────────────────────────────────┐
" │ arpatek – init.vim for Neovim                             │
" │ Minimalist configuration for DevOps and CLI workflows     │
" │ Focus on speed, clarity, and cross-system compatibility   │
" └───────────────────────────────────────────────────────────┘

" Disable vi compatibility (removes legacy quirks)
set nocompatible

" Enable filetype detection and plugins
filetype plugin indent on

" Syntax highlighting
syntax on

" Line numbers and relative numbers
set number
set relativenumber

" Indentation: 4 spaces (Python/dev-friendly)
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent

" Search behavior
set hlsearch        " highlight matches
set incsearch       " incremental search
set ignorecase      " case-insensitive
set smartcase       " but respect uppercase

" Cursor and scrolling
set ruler           " show line/column
set scrolloff=5     " keep 5 lines visible around cursor
set showcmd         " show command in status line
set showmatch       " highlight matching brackets

" Disable bells
set noerrorbells
set visualbell

" Mouse support in all modes
set mouse=a

" System clipboard
set clipboard=unnamedplus

" Persistent undo (requires +persistent_undo)
if has("persistent_undo")
  set undofile
  if !isdirectory(expand("~/.vim/undodir"))
    call mkdir(expand("~/.vim/undodir"), "p")
  endif
  set undodir=~/.vim/undodir
endif

" Dark background
set background=dark

" Optional: Faster redraw on large files
set lazyredraw

" Optional: Highlight current line
set cursorline

" Optional: Show matching parentheses more aggressively
set showmatch
set matchtime=2
