" ------------------------------------------------------------------------------
" File:		utl_arr.vim -- module implementing an associative array (a map)
"			       Part of the Utl plugin, see ./utl.vim
" Author:	Stefan Bittner <stb@bf-consulting.de>
" Licence:	This program is free software; you can redistribute it and/or
"		modify it under the terms of the GNU General Public License.
"		See http://www.gnu.org/copyleft/gpl.txt
" Version:	utl 2.0, $Revision: 1.7 $
" ------------------------------------------------------------------------------


" Rudimentary implementation of a general associative array (map).
" Written ad hoc for utl.vim but in no way special to it.
"
" Usage:
"
" call UtlArr_set('myKey', 'myValue')
" call UtlArr_set('another key', 'another value')
" call UtlArr_set('myKey', 'myValue 2')	" overrides value of mykey
" if UtlArr_find('another key', 'my_global_variable')       " 
"     echo g:my_global_variable
" else
"     echo "key `another key' not mapped"
" endif
" call UtlArr_dump()  " should yield 2 key/value pairs
"
" Details:
" - no restriction is posed onto the contents of key or values
" - no `undef' value supported (to be handled by appl. if needed)
" - No UtlArr_erase() and UtlArr_clear() implemented yet
" - Only one incarnation (object) possible (i.e. a Map is not (yet) a
"   vim data object)
" - Map may persist by means of <URL:vimhelp:%3amksession> when you
"   :set sessionoptions+=globals (see
"   <URL:vimhelp:session-file#^2. Restores global variables>).
"
" Internals:
" - Internal Data Structure:
"   utlarr.vim defines script-variables named
"   s:UtlArr_lastIdx
"   s:UtlArr_key_<i>
"   s:UtlArr_val_<i>
"   For an associative array with say 10 key/val pairs 21 Variables exist
"

if exists("loaded_utl_arr")
    finish
endif
let loaded_utl_arr = 1
let s:save_cpo = &cpo
set cpo&vim
let g:utl_arr_vim = expand("<sfile>")

let s:UtlArr_lastIdx = 0   " index-start with 1 (not 0)

"-------------------------------------------------------------------------------
" Lookup Key in Map.
" Returns: Key found? (0=false, else true)
"	   If found, retVal holds the corresponding value (as described in
"	   <URL:vim_h:%3areturn#^To return more than one value>
"
fu! UtlArr_find(key, retVal)
    let idx=1
    while idx <= s:UtlArr_lastIdx
	exe "let exists = exists('s:UtlArr_key_".idx."')"
	if exists 
	    exe "let key = s:UtlArr_key_".idx
	    if key == a:key
		exe 'let g:'.a:retVal." = s:UtlArr_val_".idx
		return idx
	    endif
	endif
	let idx = idx+1
    endwhile
    return 0
endfu

"-------------------------------------------------------------------------------
" Inserts a new key/value pair. If key already exists it, just the value is
" overridden
" 
fu! UtlArr_set(key, val)
    let idx = UtlArr_find(a:key, 'assoc_dummyVal')
    if ! idx
	"possible enhancement: search first free index
	let s:UtlArr_lastIdx = s:UtlArr_lastIdx+1
	let idx = s:UtlArr_lastIdx
    endif
    exe 'let s:UtlArr_key_'.idx." = '".a:key."'"
    exe 'let s:UtlArr_val_'.idx." = '".a:val."'"
endfu

"-------------------------------------------------------------------------------
" Dump (insert) contents of the Map at current buffer at current position
"
fu! UtlArr_dump()

    " (change this parameter if you like)
    let VALCOL = '                                        '

    let idx=0
    while idx <= s:UtlArr_lastIdx
	exe "let exists = exists('s:UtlArr_key_".idx."')"
	if exists 
	    exe "let key = s:UtlArr_key_".idx
	    exe "let val = s:UtlArr_val_".idx

	    " beautify
	    " (should be tab-padded for having tab-separated-values for
	    "  potential re'sourcing of dumped maps)
	    let padding=' '
	    if strlen(key) < strlen(VALCOL)-1
		let padding = strpart(VALCOL,0, strlen(VALCOL)-strlen(key)-1)
	    endif
	    let line = key . padding . val

	    put =line
	endif
	let idx = idx+1
    endwhile
    $delete
endfu

let &cpo = s:save_cpo

