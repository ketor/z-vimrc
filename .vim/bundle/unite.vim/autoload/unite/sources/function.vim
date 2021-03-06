"=============================================================================
" FILE: function.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#function#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'function',
      \ 'description' : 'candidates from functions',
      \ 'default_action' : 'call',
      \ 'max_candidates' : 200,
      \ 'action_table' : {},
      \ 'matchers' : 'matcher_regexp',
      \ }

let s:cached_result = []
function! s:source.gather_candidates(args, context) "{{{
  if a:context.is_redraw || empty(s:cached_result)
    let s:cached_result = s:make_cache_functions()
  endif

  " Get command list.
  redir => cmd
  silent! function
  redir END

  let result = []
  for line in split(cmd, '\n')[1:]
    let line = line[9:]
    if line =~ '^<SNR>'
      continue
    endif
    let word = matchstr(line, '\h[[:alnum:]_:#.]*\ze()\?')
    if word == ''
      continue
    endif

    let dict = {
          \ 'word' : word  . '(',
          \ 'abbr' : line,
          \ 'action__description' : line,
          \ 'action__function' : word,
          \ 'action__text' : word . '(',
          \ }
    let dict.action__description = dict.abbr

    call add(result, dict)
  endfor

  return unite#util#sort_by(
        \ s:cached_result + result, 'tolower(v:val.word)')
endfunction"}}}

function! s:make_cache_functions() "{{{
  let helpfile = expand(findfile('doc/eval.txt', &runtimepath))
  if !filereadable(helpfile)
    return []
  endif

  let lines = readfile(helpfile)
  let functions = []
  let start = match(lines, '^abs')
  let end = match(lines, '^abs', start, 2)
  for i in range(end-1, start, -1)
    let func = matchstr(lines[i], '^\s*\zs\w\+(.\{-})')
    if func != ''
      let word = substitute(func, '(.\+)', '', '')
      call insert(functions, {
            \ 'word' : word . '(',
            \ 'abbr' : lines[i],
            \ 'action__description' : lines[i],
            \ 'action__function' : word,
            \ 'action__text' : word . '(',
            \ })
    endif
  endfor

  return functions
endfunction"}}}

" Actions "{{{
let s:source.action_table.preview = {
      \ 'description' : 'view the help documentation',
      \ 'is_quit' : 0,
      \ }
function! s:source.action_table.preview.func(candidate) "{{{
  let winnr = winnr()

  try
    execute 'help' a:candidate.action__function.'()'
    normal! zv
    normal! zt
    setlocal previewwindow
    setlocal winfixheight
  catch /^Vim\%((\a\+)\)\?:E149/
    " Ignore
  endtry

  execute winnr.'wincmd w'
endfunction"}}}
let s:source.action_table.call = {
      \ 'description' : 'call the function and print result',
      \ }
function! s:source.action_table.call.func(candidate) "{{{
  if has_key(a:candidate, 'action__description')
    " Print description.

    " For function.
    let prototype_name = matchstr(
          \ a:candidate.action__description, '[^(]*')
    echohl Identifier | echon prototype_name | echohl None
    if prototype_name != a:candidate.action__description
      echon substitute(a:candidate.action__description[
            \ len(prototype_name) :], '^\s\+', ' ', '')
    endif
  endif

  let args = unite#util#input('call ' .
        \ a:candidate.action__function.'(', '', 'expression')
  if args != '' && args =~ ')$'
    redraw
    execute 'echo' a:candidate.action__function . '(' . args
  endif
endfunction"}}}
"}}}

let s:source.action_table.edit = {
      \ 'description' : 'edit the function from the source',
      \ }
function! s:source.action_table.edit.func(candidates) "{{{
  redir => func
  silent execute 'verbose function '.a:candidates.action__function
  redir END
  let path = matchstr(split(func,'\n')[1], 'Last set from \zs.*$')
  execute 'edit' fnameescape(path)
  execute search('^[ \t]*fu\%(nction\)\?[ !]*'.
        \ a:candidates.action__function)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
