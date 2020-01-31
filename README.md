# vim-grep [![CI Status](https://github.com/itchyny/vim-grep/workflows/CI/badge.svg)](https://github.com/itchyny/vim-grep/actions)
Example configuration
```vim
nnoremap gr :<C-u>Grep<Space>
nnoremap <silent> K :<C-u>Grep<CR>
vnoremap <silent> K :Grep<CR>
```

Example features (the result is set in the location list)
```vim
" git grep function (with grep command fallback outside of a git repository)
:Grep function

" grep at the current directory
:Grep function .

" grep from the other git repository
:Grep function ~/vim/grep/

" grep with the word under the cursor
:Grep

" grep with the selected text in the visual mode
:'<'>Grep
```

## Installation
Install with your favorite plugin manager.

## Author
itchyny (https://github.com/itchyny)

## License
This software is released under the MIT License, see LICENSE.
