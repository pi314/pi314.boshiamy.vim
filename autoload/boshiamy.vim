" vim:fdm=marker
" ============================================================================
" File:        boshiamy.vim
" Description: A Boshiamy Chinese input method plugin for vim
" Maintainer:  Pi314 <michael66230@gmail.com>
" License:     This program is free software. It comes without any warranty,
"              to the extent permitted by applicable law. You can redistribute
"              it and/or modify it under the terms of the Do What The Fuck You
"              Want To Public License, Version 2, as published by Sam Hocevar.
"              See http://sam.zoy.org/wtfpl/COPYING for more details.
" ============================================================================
let s:true = 1
let s:false = 0
let s:plugin_list = []
" Plugin struct
" {
"   'type': 'standalone' / 'embedded'
"   'icon': <icon>
"   'description': <description>
"   'pattern': <pattern>
"   'handler': <handler-function-reference>
" }


" Load plugins
let s:standalone_plugin_list = []
let s:embedded_plugin_list = []
function! s:LoadPlugins ()
    for l:plugin in g:boshiamy_plugins
        try
            let l:plugin_info = function('boshiamy_'. l:plugin .'#info')()
        catch
            echom v:exception
            continue
        endtry

        " sanity check
        if !has_key(l:plugin_info, 'type')
            continue
        endif

        if l:plugin_info['type'] == 'standalone' &&
                \ (!has_key(l:plugin_info, 'icon') ||
                \ !has_key(l:plugin_info, 'description'))
            continue
        endif

        if !has_key(l:plugin_info, 'pattern')
            continue
        endif

        if !has_key(l:plugin_info, 'handler')
            continue
        endif

        if l:plugin_info['type'] == 'standalone'
            call add(s:standalone_plugin_list, l:plugin_info)
        elseif l:plugin_info['type'] == 'embedded'
            call add(s:embedded_plugin_list, l:plugin_info)
        endif
    endfor


    call insert(s:standalone_plugin_list, {
                \ 'icon': '[嘸]',
                \ 'description': 'Chinese mode',
                \ }, 0)

    call add(s:embedded_plugin_list, {
                \ 'pattern': '\v(;[^;]+|;[^;]*;[346]?)$',
                \ 'handler': function('boshiamy#chewing#handler'),
                \ })

    for s:plugin in s:standalone_plugin_list
        let s:plugin['menu'] = s:plugin['icon'] .' - '. s:plugin['description']
        let s:plugin['word'] = ''
        let s:plugin['dup'] = s:true
        let s:plugin['empty'] = s:true
    endfor
endfunction
call s:LoadPlugins()


let s:boshiamy_english_enable = s:true
let s:boshiamy_mode = s:standalone_plugin_list[0]


function! s:SelectMode (new_mode) " {{{
    if type(a:new_mode) == type('ENGLISH') && a:new_mode == 'ENGLISH'
        let s:boshiamy_english_enable = s:true
    else
        let s:boshiamy_mode = a:new_mode
        let s:boshiamy_english_enable = s:false
    endif

    if s:boshiamy_english_enable == s:false
        inoremap <space> <C-R>=boshiamy#send_key()<CR>
    elseif !empty(maparg('<space>', 'i'))
        iunmap <space>
    endif

    redrawstatus!
    redraw!
endfunction " }}}


" ================
" Public Functions
" ================

function! boshiamy#send_key () " {{{
    if s:boshiamy_english_enable
        if !empty(maparg('<space>', 'i'))
            iunmap <space>
        endif
        return ' '
    endif

    let l:line = strpart(getline('.'), 0, (col('.') - 1) )

    if s:boshiamy_mode['icon'] != '[嘸]'
        let l:matchobj = matchlist(l:line, s:boshiamy_mode['pattern'])
        if len(l:matchobj) == 0
            return ' '
        endif

        let l:ret = s:boshiamy_mode['handler'](l:matchobj)
        if len(l:ret) == 0 || type(l:ret) != type([])
            return ' '
        endif

        call complete(col('.') - strlen(l:matchobj[0]), l:ret)
        return ''
    endif

    for l:plugin in s:embedded_plugin_list
        let l:matchobj = matchlist(l:line, l:plugin['pattern'])
        if len(l:matchobj) == 0
            continue
        endif

        let l:ret = l:plugin['handler'](l:matchobj)
        if len(l:ret) == 0 || type(l:ret) != type([])
            continue
        endif

        call complete(col('.') - strlen(l:matchobj[0]), l:ret)
        return ''
    endfor

    return boshiamy#boshiamy#handler(l:line)

    " if s:boshiamy_mode == 'WIDE'
    "    let l:wide_str = matchstr(l:line, '\([ a-zA-Z0-9]\|[-=,./;:<>?_+\\|!@#$%^&*(){}"]\|\[\|\]\|'."'".'\)\+$')
    "    return boshiamy#wide#handler(l:line, l:wide_str)
    " endif

    " if s:boshiamy_mode == 'KANA'
    "    let l:kana_str = matchstr(l:line, '[.a-z]\+$')
    "    return boshiamy#kana#handler(l:line, l:kana_str)
    " endif

    " if s:boshiamy_mode == 'RUNES'
    "    let l:runes_str = matchstr(l:line, '[.a-z,]\+$')
    "    return boshiamy#runes#handler(l:line, l:runes_str)
    " endif

    " if s:boshiamy_mode == 'BRAILLE'
    "    let l:braille_str = matchstr(l:line, '\v['. g:boshiamy_braille_keys .']*$')
    "    return boshiamy#braille#handler(l:line, l:braille_str)
    " endif

    " " Try chewing
    " let chewing_str = matchstr(l:line, ';[^;]*;[346]\?$')
    " if l:chewing_str == ''
    "     let chewing_str = matchstr(l:line, ';[^;]\+$')
    " endif
    " if l:chewing_str != ''
    "     if boshiamy#chewing#handler(l:line, l:chewing_str) == 0
    "         return ''
    "     endif
    " endif
    "
    " " Translating code point to unicode character
    " let unicode_pattern = matchstr(l:line, '\\[Uu][0-9a-fA-F]\+$')
    " if l:unicode_pattern != ''
    "     if boshiamy#unicode#handler_encode(l:line, l:unicode_pattern) == 0
    "         return ''
    "     endif
    " endif
    "
    " " Reverse lookup for code point
    " let unicode_pattern = matchstr(l:line, '\\[Uu]\[[^]]*\]$')
    " if l:unicode_pattern == ''
    "     let unicode_pattern = matchstr(l:line, '\\[Uu]\[\]\]$')
    " endif
    " if l:unicode_pattern != ''
    "     if boshiamy#unicode#handler_decode(l:line, l:unicode_pattern) == 0
    "         return ''
    "     endif
    " endif
    "
    " let htmlcode_pattern = matchstr(l:line, '&#x\?[0-9a-fA-F]\+;$')
    " if l:htmlcode_pattern != ''
    "     if boshiamy#html#handler(l:line, l:htmlcode_pattern) == 0
    "         return ''
    "     endif
    " endif
    "
    " let emoji_pattern = matchstr(l:line, ':\([0-9a-z_+-]\+:\?\)\?$')
    " " +-0123456789:_abcdefghijklmnopqrstuvwxyz
    " if emoji_pattern != ''
    "     if boshiamy#emoji#handler(l:line, l:emoji_pattern) == 0
    "         return ''
    "     endif
    " endif
endfunction " }}}


function! boshiamy#mode () " {{{
    if s:boshiamy_english_enable
        return '[英]'
    endif
    return get(s:boshiamy_mode, 'icon', '[？]')
endfunction " }}}


function! boshiamy#toggle () " {{{
    if s:boshiamy_english_enable
        call s:SelectMode(s:boshiamy_mode)
    else
        call s:SelectMode('ENGLISH')
    endif
    return ''
endfunction " }}}


function! boshiamy#_show_mode_menu () " {{{
    let l:fallback_style = g:boshiamy_select_mode_style

    if index(['menu', 'input', 'dialog'], l:fallback_style) == -1
        let l:fallback_style = 'menu'
    endif

    if l:fallback_style == 'menu' && !exists('##CompleteDone')
        let l:fallback_style = 'input'
    endif

    if l:fallback_style == 'menu'
        call boshiamy#_comp_show_mode_menu()
    elseif l:fallback_style == 'input'
        call boshiamy#_input_show_mode_menu()
    elseif l:fallback_style == 'dialog'
        call boshiamy#_dialog_show_mode_menu()
    endif
    return ''
endfunction " }}}


function! boshiamy#_comp_show_mode_menu () " {{{
    augroup boshiamy
        autocmd! boshiamy CompleteDone
        autocmd boshiamy CompleteDone * call boshiamy#_comp_select_mode()
    augroup end
    " let l:tmp = []
    " for l:mode in s:__mode_order
    "     call add(l:tmp, s:__mode2icon[(l:mode)])
    " endfor
    call complete(col('.'), s:standalone_plugin_list)
endfunction " }}}


function! boshiamy#_comp_select_mode () " {{{
    augroup boshiamy
        autocmd! boshiamy CompleteDone
        for l:plugin in s:standalone_plugin_list
            if v:completed_item['menu'] == l:plugin['menu']
                call s:SelectMode(l:plugin)
            endif
        endfor
    augroup end
endfunction " }}}


function! boshiamy#_input_show_mode_menu () " {{{
    let l:prompt = ['Select input mode:'] + map(copy(s:mode_list), '(v:key + 1) ." - ". v:val[1]')
    let l:user_input = inputlist(l:prompt)
    if l:user_input
        call s:SelectMode(s:__icon2mode[s:mode_list[l:user_input - 1][1]])
    endif
endfunction " }}}


function! boshiamy#_dialog_show_mode_menu () " {{{
    let l:prompt = ['Select input mode:'] + map(copy(s:mode_list), '(v:key + 1) ." - ". v:val[1]')
    let l:user_input = str2nr(inputdialog(join(l:prompt, "\n") ."\n> "))
    if 0 < l:user_input && l:user_input < len(l:prompt)
        call s:SelectMode(s:__icon2mode[s:mode_list[l:user_input - 1][1]])
    endif
endfunction " }}}
