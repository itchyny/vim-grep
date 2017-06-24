" =============================================================================
" Filename: plugin/grep.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/06/25 00:14:12.
" =============================================================================

if exists('g:loaded_grep') || v:version < 704
  finish
endif
let g:loaded_grep = 1

let s:save_cpo = &cpo
set cpo&vim

command! -range=% -nargs=* Grep call grep#start(<q-args>, [<line1>, <line2>] != [1, line('$')])

let &cpo = s:save_cpo
unlet s:save_cpo
