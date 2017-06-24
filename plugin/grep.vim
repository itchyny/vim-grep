" =============================================================================
" Filename: plugin/grep.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/06/24 19:47:47.
" =============================================================================

if exists('g:loaded_grep') || v:version < 704
  finish
endif
let g:loaded_grep = 1

let s:save_cpo = &cpo
set cpo&vim

command! -range=% -nargs=* Grep call grep#start(<q-args>, <line1>, <line2>)

let &cpo = s:save_cpo
unlet s:save_cpo
