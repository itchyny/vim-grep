" =============================================================================
" Filename: autoload/grep.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/07/14 22:24:57.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! grep#start(args, visual) abort
  let [args, dir] = s:extract_target(a:args)
  if args ==# ''
    let args = s:get_text(a:visual)
    if args ==# ''
      echo 'Grep: no word to grep'
      return
    endif
    echo 'Grep' args
    call s:save_cmd(args)
  endif
  call s:save_search(args)
  if dir ==# ''
    let dir = s:git_root(expand('%:p:h'))
    if dir ==# ''
      let dir = expand('%:p:h')
    endif
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

function! s:get_text(visual) abort
  let text = ''
  if a:visual
    let reg = '"'
    let [save_reg, save_type] = [getreg(reg), getregtype(reg)]
    silent normal! gv""y
    let text = getreg(reg)
    call setreg(reg, save_reg, save_type)
  elseif expand('<cword>') !=# ''
    let text = expand('<cword>')
  elseif getreg('*') !~# '^\s\+$'
    let text = getreg('*')
  endif
  let text = substitute(text, '\v^[[:space:][:return:]]+|[[:space:][:return:]]+$|\n.*', '', 'g')
  let text = substitute(text, '\v\s+\zs\S+\s*$', '\=substitute(submatch(0), "[\\/]", ".", "g")', 'g')
  return substitute(text, '\v[$"*]|^''|''$|^\^', '.', 'g')
endfunction

function! s:save_cmd(text) abort
  if histget(':', -1) =~# '\vGrep\s*$'
    call histdel(':', -1)
  endif
  call histadd(':', 'Grep ' . a:text)
endfunction

function! s:save_search(text) abort
  let flags = '\c' . (a:text =~# '[$.\[\]*~]' ? '\m' : '')
  if a:text =~# '\v^(".*"|''.*'')$'
    let text = flags . escape(a:text[1:len(a:text) - 2], '~')
  else
    let text = flags . escape(a:text, '\[]~')
  endif
  let @/ = text
  call histadd('/', text)
endfunction

function! s:get_cmd(dir) abort
  let git_root = s:git_root(a:dir)
  if !executable('git') || git_root ==# '' || !s:git_tracked(a:dir, git_root)
    return 'grep --exclude-dir=.git --exclude=tags -HIsinr -- {pat} {dir}'
  endif
  if git_root ==# s:git_root(getcwd())
    return 'git grep -HIin -- {pat} {dir}'
  endif
  return 'git -C ' . shellescape(git_root) . ' grep -HIin -- {pat} {dir} | sed "s|^|' . escape(git_root, ' ') . '/|"'
endfunction

function! s:git_tracked(dir, git_root) abort
  if a:dir ==# '' || a:git_root ==# ''
    return 0
  endif
  return !system('git -C ' . shellescape(a:git_root) . ' ls-files ' . shellescape(a:dir) . ' --error-unmatch >/dev/null 2>/dev/null; echo $?')
endfunction

function! s:run(cmd, dir, pat) abort
  let errorformat = &errorformat
  try
    let &errorformat = '%f:%l:%m'
    let cmd = s:replace(s:replace(a:cmd, '{pat}', a:pat), '{dir}', shellescape(a:dir))
    lexpr system(cmd)
  finally
    let &errorformat = errorformat
  endtry
endfunction

function! s:replace(str, part, target) abort
  let str = a:str
  let ret = ''
  while 1
    let pos = match(str, a:part)
    if pos < 0
      let ret .= str
      break
    endif
    if 0 < pos
      let ret .= str[:(pos - 1)]
    endif
    let ret .= a:target
    let str = str[(pos + len(a:part)):]
  endwhile
  return ret
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
    elseif type ==# 'file' && get(readfile(dir), 0, '') =~# '^gitdir: '
      return fnamemodify(dir, ':h')
    endif
    let prev = path
    let path = fnamemodify(path, ':h')
  endwhile
  return ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
