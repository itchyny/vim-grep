" =============================================================================
" Filename: autoload/grep.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/06/25 00:14:19.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! grep#start(args, visual) abort
  let [args, dir] = s:extract_target(a:args)
  if args ==# ''
    let [orig, args] = s:get_pattern(a:visual)
    echo 'Grep' orig
    call s:save_cmd(substitute(orig, '[$"*]', '.', 'g'))
    call s:save_search(orig, '\[]~$*')
  else
    call s:save_search(args, '\[]~')
    let args = s:quote(args)
  endif
  if args ==# ''
    echo 'Grep: no word to grep'
    return
  endif
  if dir ==# ''
    let dir = s:git_root(expand('%:p:h'))
  endif
  call s:run(s:get_cmd(dir), dir, s:quote(args))
endfunction

function! s:extract_target(args) abort
  let xs = split(a:args, '\v\s+\ze\S+\s*$', 1)
  if len(xs) < 2 || xs[0] ==# ''
    return [a:args, '']
  endif
  let dir = s:resolve_path(substitute(xs[1], '\v\s*$', '', ''))
  if !isdirectory(dir)
    return [a:args, '']
  endif
  return [substitute(xs[0], '\v\s*$', '', ''), dir]
endfunction

function! s:resolve_path(path) abort
  if a:path =~# '\v^\.\.?/'
    return fnamemodify(expand('%:p:h') . '/' . a:path, ':p:h')
  endif
  return fnamemodify(a:path, ':p')
endfunction

function! s:get_pattern(visual) abort
  if a:visual
    let reg = '"'
    let [save_reg, save_type] = [getreg(reg), getregtype(reg)]
    normal! gv""y
    let text = getreg(reg)
    call setreg(reg, save_reg, save_type)
    return s:normalize_text(text)
  else
    return s:normalize_text(expand('<cword>') !=# '' ? expand('<cword>') : getreg('*') !~# '^\s\+$' ? getreg('*') : '')
  endif
endfunction

function! s:normalize_text(text) abort
  let text = substitute(a:text, '\v^[[:space:][:return:]]+|[[:space:][:return:]]+$|\n.*', '', 'g')
  return [text, "'" . escape(substitute(text, "'", '.', 'g'), '\"[]*') . "'"]
endfunction

function! s:save_cmd(text) abort
  if histget(':', -1) =~# '\vGrep\s*$'
    call histdel(':', -1)
  endif
  call histadd(':', 'Grep ' . a:text)
endfunction

function! s:save_search(text, esc) abort
  let text = escape(a:text, a:esc)
  let @/ = text
  call histadd('/', text)
endfunction

function! s:get_cmd(dir) abort
  if !executable('git')
    return 'grep --exclude-dir=.git --exclude=tags -HIsinr -- {pat} {dir}'
  endif
  let git_root = s:git_root(a:dir)
  if git_root ==# s:git_root(getcwd())
    return 'git grep -HIin -- {pat} {dir}'
  endif
  return 'git -C ' . shellescape(git_root) . ' grep -HIin -- {pat} {dir} | sed "s|^|' . escape(git_root, ' ') . '/|"'
endfunction

function! s:run(cmd, dir, pat) abort
  let errorformat = &errorformat
  try
    let &errorformat = '%f:%l:%m'
    let cmd = substitute(s:replace(a:cmd, '{pat}', a:pat), '{dir}', shellescape(a:dir), 'g')
    lexpr system(cmd)
  finally
    let &errorformat = errorformat
  endtry
endfunction

function! s:replace(str, part, target) abort
  return join(split(a:str, a:part), a:target)
endfunction

function! s:quote(pat) abort
  if a:pat =~# '\v^(".*"|''.*'')$'
    return a:pat
  end
  return "'" . escape(substitute(a:pat, "'", '.', 'g'), '\"[]') . "'"
endfunction

function! s:git_root(dir) abort
  let path = fnamemodify(a:dir, ':p:h')
  let prev = ''
  while path !=# prev
    let dir = path . '/.git'
    let type = getftype(dir)
    if type ==# 'dir' && isdirectory(dir.'/objects') && isdirectory(dir.'/refs') && getfsize(dir.'/HEAD') > 10
      return fnamemodify(dir, ':h')
    elseif type ==# 'file'
      let reldir = get(readfile(dir), 0, '')
      if reldir =~# '^gitdir: '
        return fnamemodify(simplify(path . '/' . reldir[8:]), ':h')
      endif
    endif
    let prev = path
    let path = fnamemodify(path, ':h')
  endwhile
  return fnamemodify(a:dir, ':p:h')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
