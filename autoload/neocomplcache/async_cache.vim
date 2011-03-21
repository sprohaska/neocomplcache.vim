set cpo&vim

"=============================================================================
" FILE: async_cache.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 21 Mar 2011.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following condition
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

function! s:load_from_file(filename, pattern, mark, minlen, maxfilename)"{{{
  if bufloaded(a:filename)
    let l:lines = getbufline(bufnr(a:filename), 1, '$')
  elseif filereadable(a:filename)
    let l:lines = readfile(a:filename)
  else
    " File not found.
    return []
  endif

  let l:max_lines = len(l:lines)
  " let l:menu = printf('[%s] %.' . a:maxfilename . 's', a:mark, fnamemodify(a:filename, ':t'))
  let l:menu = 'hoge'

  let l:keyword_list = []
  let l:dup_check = {}
  let l:keyword_pattern2 = '^\%('.a:pattern.'\m\)'

  for l:line in l:lines"{{{
    let l:match = match(l:line, a:pattern)
    while l:match >= 0"{{{
      let l:match_str = matchstr(l:line, l:keyword_pattern2, l:match)

      if !has_key(l:dup_check, l:match_str) && len(l:match_str) >= a:minlen
        " Append list.
        call add(l:keyword_list, { 'word' : l:match_str, 'menu' : l:menu })

        let l:dup_check[l:match_str] = 1
      endif

      let l:match = match(l:line, a:pattern, l:match + len(l:match_str))
    endwhile"}}}
  endfor"}}}

  return l:keyword_list
endfunction"}}}

" args: filename pattern mark minlen maxfilename outputname
let [l:filename, l:filetype, l:mark, l:minlen, l:maxfilename, l:outputname]
      \ = argv()[1:]

" let l:keyword_list = s:load_from_file(l:filename, l:pattern, l:mark, l:minlen)
let l:keyword_list = s:load_from_file(l:filename, '\h\w*', l:mark, l:minlen)

" Create dictionary key.
" for keyword in [{'word':'test'}, {'word':'piyo'}]
for keyword in l:keyword_list
  let keyword.kind = ''
  let keyword.class = ''
  let keyword.abbr = keyword.word

  call append('$', keyword.word)
  " call append('$', printf('%s|||%s|||%s|||%s|||%s',
  "       \ keyword.word, keyword.abbr, keyword.menu, keyword.kind, keyword.class))
endfor

" Output cache.
1delete _
write!

qall!

" vim: foldmethod=marker