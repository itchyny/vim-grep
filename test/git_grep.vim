let s:suite = themis#suite('git_grep')
let s:assert = themis#helper('assert')

let s:dir = ''

function! s:suite.before()
  let dir = tempname() . '/test-git-grep'
  let s:dir = dir
  call mkdir(dir, 'p')
  cd `=dir`
  call system('git init')
  let name1 = 'text1.txt'
  call writefile(['foo', 'bar', 'baz', 'foobar'], name1)
  call system('git add ' . name1)
  call mkdir('dir', 'p')
  let name2 = 'dir/text2.txt'
  call writefile(['[]!"#$%&''()=^\@*{}+<>~?/`+ ../', ' foobaz qux'], name2)
  call system('git add ' . name2)
  set clipboard=unnamed,unnamedplus
endfunction

function! s:suite.before_each()
  lclose
  for bufnr in filter(range(1, bufnr('$')), 'bufexists(v:val)')
    execute bufnr 'bwipeout!'
  endfor
  tabnew
  lcd `=s:dir`
endfunction

function! s:suite.after()
  call delete(s:dir, 'rf')
endfunction

function! s:suite.git_grep()
  Grep foo
  call s:assert.equals(LoclistText(), [' foobaz qux', 'foo', 'foobar'])
  call s:assert.equals(LoclistBufname(0), ['dir/text2.txt', 'text1.txt', 'text1.txt'])
endfunction

function! s:suite.git_grep_pattern()
  Grep fo.*AR$
  call s:assert.equals(LoclistText(), ['foobar'])
endfunction

function! s:suite.git_grep_current()
  Grep foo .
  call s:assert.equals(LoclistText(), [' foobaz qux', 'foo', 'foobar'])
endfunction

function! s:suite.git_grep_dir()
  Grep foo dir
  call s:assert.equals(LoclistText(), [' foobaz qux'])
  call s:assert.equals(LoclistBufname(0), ['dir/text2.txt'])
endfunction

function! s:suite.git_grep_dir_current()
  lcd dir
  Grep foo
  call s:assert.equals(LoclistText(), [' foobaz qux', 'foo', 'foobar'])
  Grep foo .
  call s:assert.equals(LoclistText(), [' foobaz qux'])
endfunction

function! s:suite.git_grep_parent()
  lcd dir
  Grep foo ../
  call s:assert.equals(LoclistText(), [' foobaz qux', 'foo', 'foobar'])
  call s:assert.equals(LoclistBufname(0), ['../text1.txt', '../text1.txt', 'text2.txt'])
  Grep foo ../dir
  call s:assert.equals(LoclistText(), [' foobaz qux'])
  call s:assert.equals(LoclistBufname(0), ['text2.txt'])
endfunction

function! s:suite.git_grep_outside_dir()
  lcd /
  execute 'Grep foo' s:dir
  call s:assert.equals(LoclistText(), [' foobaz qux', 'foo', 'foobar'])
  call s:assert.equals(LoclistBufname(0), map(['dir/text2.txt', 'text1.txt', 'text1.txt'], 's:dir . "/" . v:val'))
  execute 'Grep foo' s:dir . '/dir'
  call s:assert.equals(LoclistText(), [' foobaz qux'])
  call s:assert.equals(LoclistBufname(0), map(['dir/text2.txt'], 's:dir . "/" . v:val'))
endfunction

function! s:suite.git_grep_cword()
  edit text1.txt
  Grep
  call s:assert.equals(LoclistText(), [' foobaz qux', 'foo', 'foobar'])
  edit text1.txt
  call cursor(2, 1)
  Grep
  call s:assert.equals(LoclistText(), ['bar', 'foobar'])
endfunction

function! s:suite.git_grep_yanked()
  edit text1.txt
  call cursor(4, 1)
  yank
  tabnew
  Grep
  call s:assert.equals(LoclistText(), ['foobar'])
endfunction

function! s:suite.git_grep_special()
  edit dir/text2.txt
  call feedkeys("ggV:Grep\<CR>", 'ntx')
  call s:assert.equals(LoclistText(), ['[]!"#$%&''()=^\@*{}+<>~?/`+ ../'])
  call s:assert.equals(histget('/', -1), '\c\m\[\]!.#.%&''()=^\\@.{}+<>\~?/`+ ...')
  call s:assert.equals(histget(':', -1), 'Grep []!.#.%&''()=^\@.{}+<>~?/`+ ...')
  call feedkeys("j:Grep\<CR>", 'ntx')
  call s:assert.equals(LoclistText(), [' foobaz qux'])
  call s:assert.equals(histget('/', -1), '\cfoobaz')
  call s:assert.equals(histget(':', -1), 'Grep foobaz')
  call feedkeys(":\<Up>\<Up>\<CR>", 'ntx')
  call s:assert.equals(LoclistText(), ['[]!"#$%&''()=^\@*{}+<>~?/`+ ../'])
  call s:assert.equals(histget('/', -1), '\c\m\[\]!.#.%&''()=^\\@.{}+<>\~?/`+ ...')
  call s:assert.equals(histget(':', -1), 'Grep []!.#.%&''()=^\@.{}+<>~?/`+ ...')
  call feedkeys(":\<Up>\<Up>\<CR>", 'ntx')
  call s:assert.equals(LoclistText(), [' foobaz qux'])
  call s:assert.equals(histget('/', -1), '\cfoobaz')
  call s:assert.equals(histget(':', -1), 'Grep foobaz')
endfunction
