" ------------------------------------------------------------------------------
" File:		thlnkarr.vim -- module implementing an associative array (a map)
"			        Part of the Thlnk plugin, see ./thlnk.vim
" Author:	Stefan Bittner <stb@bf-consulting.de>
" Licence:	This program is free software; you can redistribute it and/or
"		modify it under the terms of the GNU General Public License.
"		See http://www.gnu.org/copyleft/gpl.txt
" Last Change:	13-Jun-2002/STB
" Version:	thlnk-1.2
" ------------------------------------------------------------------------------


" Implements a general associative array (map). (Rudiment only.)
" (Written ad hoc for thlnk.vim but in no way special to it)
"
" Usage:
"
" call ThlnkArr_set('myKey', 'myValue')
" call ThlnkArr_set('another key', 'another value')
" call ThlnkArr_set('myKey', 'myValue 2')	" overrides value of mykey
" if ThlnkArr_find('another key', 'my_global_variable')       " 
"     echo g:my_global_variable
" else
"     echo "key `another key' not mapped"
" endif
" call ThlnkArr_dump()  " should yield 2 key/value pairs
"
" Details:
" - no restriction is posed onto the contents of key or values
" - no `undef' value supported (to be handled by appl. if needed)
" - No ThlnkArr_erase() and ThlnkArr_clear() implemented yet
" - Only one incarnation (object) possible (i.e. a Map is not (yet) a
"   vim data object)
" - Map may persist by means of <URL:vim_h:%3amksession> when you
"   :set sessionoptions+=globals (see
"   <URL:vim_h:session-file#tn=^2. Restores global variables>).
"
" Internals:
" - Internal Data Structure:
"   thlnkarr.vim defines script-variables named
"   s:ThlnkArr_lastIdx
"   s:ThlnkArr_key_<i>
"   s:ThlnkArr_val_<i>
"   For an associative array with say 10 key/val pairs 21 Variables exist
"

if exists("loaded_thlnkarr")
    finish
endif
let loaded_thlnkarr = 1
let s:save_cpo = &cpo
set cpo&vim

"    echo 'DBG initializing Map'
let s:ThlnkArr_lastIdx = 0   " index-start with 1 (not 0)

let thlnkarr_vim = expand("<sfile>")

"-------------------------------------------------------------------------------
" Lookup Key in Map.
" Returns: Key found? (0=false, else true)
"	   If found, retVal holds the corresponding value (as described in
"	   <URL:vim_h:%3areturn#tn=^To return more than one value>
"
fu! ThlnkArr_find(key, retVal)
    let idx=1
    while idx <= s:ThlnkArr_lastIdx
"	echo 'DBG idx=`'.idx."'"
	exe "let exists = exists('s:ThlnkArr_key_".idx."')"
	if exists 
	    exe "let key = s:ThlnkArr_key_".idx
"	    echo 'DBG key=`'.key."'"
	    if key == a:key
"		echo 'DBG found key=`'.key."'"
		exe 'let g:'.a:retVal." = s:ThlnkArr_val_".idx
		return idx
	    endif
	endif
	let idx = idx+1
    endwhile
"   echo 'DBG not found a:key=`'.a:key."'"
    return 0
endfu

"-------------------------------------------------------------------------------
" Inserts a new key/value pair. If key already exists it, just the value is
" overridden
" 
fu! ThlnkArr_set(key, val)
"    echo 'DBG ---beg------ThlnkArr_set'
    let idx = ThlnkArr_find(a:key, 'assoc_dummyVal')
    if ! idx
	"upd search first free index
	let s:ThlnkArr_lastIdx = s:ThlnkArr_lastIdx+1
	let idx = s:ThlnkArr_lastIdx
    endif
"    echo 'DBG let s:ThlnkArr_key_'.idx." = '".a:key."'"
    exe 'let s:ThlnkArr_key_'.idx." = '".a:key."'"
    exe 'let s:ThlnkArr_val_'.idx." = '".a:val."'"
"    echo 'DBG ------end---ThlnkArr_set'
endfu

"-------------------------------------------------------------------------------
" Dump (insert) contents of the Map at current buffer at current position
"
fu! ThlnkArr_dump()

    " (change this parameter if you like)
    let VALCOL = '                                        '

    let idx=0
    while idx <= s:ThlnkArr_lastIdx
	exe "let exists = exists('s:ThlnkArr_key_".idx."')"
	if exists 
	    exe "let key = s:ThlnkArr_key_".idx
	    exe "let val = s:ThlnkArr_val_".idx

	    " beautify
	    "upd: should be tab-padded for having tab-separated-values for
	    "	  potential re'sourcing of dumped maps
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

