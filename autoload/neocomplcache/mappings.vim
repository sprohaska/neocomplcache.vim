"=============================================================================
" FILE: mappings.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 May 2013.
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

function! neocomplcache#mappings#define_default_mappings() "{{{
  inoremap <expr><silent> <Plug>(neocomplcache_start_unite_complete)
        \ unite#sources#neocomplcache#start_complete()
  inoremap <expr><silent> <Plug>(neocomplcache_start_unite_quick_match)
        \ unite#sources#neocomplcache#start_quick_match()
  inoremap <silent> <Plug>(neocomplcache_start_auto_complete)
        \ <C-x><C-u><C-r>=neocomplcache#mappings#popup_post()<CR>
  inoremap <silent> <Plug>(neocomplcache_start_auto_complete_no_select)
        \ <C-x><C-u><C-p>
  " \ <C-x><C-u><C-p>
  inoremap <silent> <Plug>(neocomplcache_start_omni_complete)
        \ <C-x><C-o><C-p>
endfunction"}}}

function! neocomplcache#mappings#smart_close_popup() "{{{
  return g:neocomplcache_enable_auto_select ?
        \ neocomplcache#mappings#cancel_popup() :
        \ neocomplcache#mappings#close_popup()
endfunction
"}}}
function! neocomplcache#mappings#close_popup() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.complete_str = ''
  let neocomplcache.skip_next_complete = 2
  let neocomplcache.candidates = []

  return pumvisible() ? "\<C-y>" : ''
endfunction
"}}}
function! neocomplcache#mappings#cancel_popup() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.skip_next_complete = 1
  call neocomplcache#helper#clear_result()

  return pumvisible() ? "\<C-e>" : ''
endfunction
"}}}

function! neocomplcache#mappings#popup_post() "{{{
  return  !pumvisible() ? "" :
        \ g:neocomplcache_enable_auto_select ? "\<C-p>\<Down>" :
        \ "\<C-p>"
endfunction"}}}

function! neocomplcache#mappings#undo_completion() "{{{
  if !exists(':NeoComplCacheDisable')
    return ''
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  " Get cursor word.
  let [complete_pos, complete_str] =
        \ neocomplcache#match_word(neocomplcache#get_cur_text(1))
  let old_keyword_str = neocomplcache.complete_str
  let neocomplcache.complete_str = complete_str

  return (!pumvisible() ? '' :
        \ complete_str ==# old_keyword_str ? "\<C-e>" : "\<C-y>")
        \. repeat("\<BS>", len(complete_str)) . old_keyword_str
endfunction"}}}

function! s:common_head(strs)
  if empty(a:strs)
    return ''
  endif
  let len = len(a:strs)
  if len == 1
    return a:strs[0]
  endif
  let strs = len == 2 ? a:strs : sort(copy(a:strs))
  let pat = substitute(strs[0], '.', '[\0]', 'g')
  return pat == '' ? '' : matchstr(strs[-1], '^\%[' . pat . ']')
endfunction

function! neocomplcache#mappings#complete_common_string() "{{{
  if !exists(':NeoComplCacheDisable')
    return ''
  endif

  " Save options.
  let ignorecase_save = &ignorecase

  if neocomplcache#is_text_mode()
    let &ignorecase = 1
  else
    let &ignorecase = g:neocomplcache_enable_ignore_case
  endif

  let is_fuzzy = g:neocomplcache_enable_fuzzy_completion

  echom "XXX"

  let complete_str = ''
  let common_str = ''
  let a:minlen = 3
  try
    let g:neocomplcache_enable_fuzzy_completion = 0
    let neocomplcache = neocomplcache#get_current_neocomplcache()
    let cur_line = neocomplcache#get_cur_text(1)

    " echom "keys(neocomplcache): " . string(keys(neocomplcache))
    " echom "neocomplcache: " . string(neocomplcache)
    " echom "neocomplcache.complete_results: " . string(neocomplcache.complete_results)
    " echom "neocomplcache.complete_results...complete_pos: " . string(map(copy(neocomplcache.complete_results), 'v:val.neocomplcache__context.complete_pos'))
    " echom "neocomplcache.cur_text: " . neocomplcache.cur_text
    " echom "neocomplcache#get_cur_text(1): " . neocomplcache#get_cur_text(1)
    " echom "neocomplcache.complete_str: " . neocomplcache.complete_str
    " echom "neocomplcache.complete_pos: " . neocomplcache.complete_pos

    " Try to match substrings of each candidate word of complete_results.  The
    " match is a substring of the current line and may be longer than the
    " substring of the candidate word that was used as a pattern.  Accept a
    " word only if it starts with the match.  All accepted matches are equal,
    " and any of them can be used as complete_str.  Hence, the search is
    " started with a substring that is at least as long as complete_str.
    let matched_common = []
    let matched_words = []
    for r in neocomplcache.complete_results
        let cur_compl_text = cur_line[r.neocomplcache__context.complete_pos:]

        let candidates = r.neocomplcache__context.candidates
        let words = map(copy(candidates), 'v:val.word')
        let words = filter(copy(words), 'len(v:val) >= '. a:minlen)

        " echom "r: " . string(r)
        echom "cur_line: " . cur_line
        echom "cur_compl_text: " . cur_compl_text
        echom "words: " . string(words)

        for w in words
            let m = ''
            let start = max([a:minlen - 1, len(complete_str) - 1])
            for i in range(start, max([start - 1, len(w) - 1]), 1)
                let pattern = '\V' . escape(w[0:i], '\')
                let [_, str] = neocomplcache#match_word(cur_compl_text, pattern)
                if str == ''
                    break
                endif
                let m = str
            endfor

            echom "word: " . w . ", match: " . m

            if m != ''
                if stridx(w, m) == 0
                    let complete_str = m
                    let matched_words += [w]
                    let matched_common += [m]

                    echom "Accepted"

                endif
            endif
        endfor
    endfor

    echom "matched_common: " . string(matched_common)
    echom "matched_words: " . string(matched_words)

    let common_str = s:common_head(matched_words)
  finally
    let g:neocomplcache_enable_fuzzy_completion = is_fuzzy
  endtry

  echom "complete_str: " . complete_str
  echom "common_str: " . common_str

  if &ignorecase
    let common_str = tolower(common_str)
  endif

  let &ignorecase = ignorecase_save

  if common_str == '' || complete_str == ''

    echom "neocomplcache: " . string(neocomplcache)

    return ''
  endif

  return (pumvisible() ? "\<C-e>" : '')
        \ . repeat("\<BS>", len(complete_str)) . common_str
endfunction"}}}

" Manual complete wrapper.
function! neocomplcache#mappings#start_manual_complete(...) "{{{
  if !neocomplcache#is_enabled()
    return ''
  endif

  " Set context filetype.
  call neocomplcache#context_filetype#set()

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  let sources = get(a:000, 0,
        \ keys(neocomplcache#available_sources()))
  let neocomplcache.manual_sources = neocomplcache#helper#get_sources_list(
        \ neocomplcache#util#convert2list(sources))

  " Set function.
  let &l:completefunc = 'neocomplcache#complete#sources_manual_complete'

  " Start complete.
  return "\<C-x>\<C-u>\<C-p>"
endfunction"}}}

function! neocomplcache#mappings#start_manual_complete_list(complete_pos, complete_str, candidates) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let [neocomplcache.complete_pos,
        \ neocomplcache.complete_str, neocomplcache.candidates] =
        \ [a:complete_pos, a:complete_str, a:candidates]

  " Set function.
  let &l:completefunc = 'neocomplcache#complete#auto_complete'

  " Start complete.
  return "\<C-x>\<C-u>\<C-p>"
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
