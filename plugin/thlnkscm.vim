" ------------------------------------------------------------------------------
" File:		thlnkscm.vim -- callbacks implementing the different schemes
"			        Part of the Thlnk plugin, see ./thlnk.vim
" Author:	Stefan Bittner <stb@bf-consulting.de>
" Licence:	This program is free software; you can redistribute it and/or
"		modify it under the terms of the GNU General Public License.
"		See http://www.gnu.org/copyleft/gpl.txt
" Last Change:	13-Jun-2002/STB
" Version:	thlnk-1.2
" ------------------------------------------------------------------------------


" In this file some scheme specific retrieval functions are defined.
" For each scheme one function named Thlnk_AddrScheme_xxx() is needed.
"
" - If a scheme (i.e. functions) is missing, the caller Thlnk_processUrl()
"   will notice it and show an appropriate message to the user.
"
" - You can define your own functions (<URL:#implscmfunc>), change the existing
"   ones (better adapat for Windows), delete the existing ones.


" How to write a Thlnk_AddrScheme_xxx function		(id=implscmfunc)
" ------------------------------------------
" To implement a specific scheme (e.g. `file', `http') you have to write
" write a function named `Thlnk_AddrScheme_<scheme>' which obeys the
" following rules:
" - It takes an absolute URI `auri' <URL:vim_h:thlnk-uri-relabs>
"   as its only argument. The given `auri' will not have a fragment, i.e.
"   `auri' is not an URI reference (fragments are treated by the caller).
" - Then does what ever it wants.
"     But what it normally wants is: retrieve, load, query, address the
"   resource identified by `auri'.
" - Returns a any pathname to an existing local file or directory
"   (may be be created by <URL:#tp=Then%20does>
"   An empty pathname is allowed (i.e. ``retrieve not successful'' or
"   ``no file corresponding'').
"     The meaning of the pathname is `localPath', see
"   <URL:vim_h:thlnk-internals#tn=LocalPath> (the MapSet() is done by
"   the caller). `LocalPath' normally will be the retrieved document (i.e. an
"   ad hoc generated file with random name) or just the determined local
"   resource or file (e.g. with scheme `file').
"     Thlnk_AddrScheme_<scheme> _may_ display the `localPath' (vim_h scheme!)
"   but normally it leaves that up to the caller (thlnk.vim) because the
"   display (more exact: processing) does not depend on the scheme rather
"   than on the media type.


if exists("loaded_thlnkscm")
    finish
endif
let loaded_thlnkscm = 1
let s:save_cpo = &cpo
set cpo&vim

let thlnkscm_vim = expand("<sfile>")

"-------------------------------------------------------------------------------
" Addresses/retrieves a local file (but when a host is given
" then delegate to Thlnk_AddressScheme_ftp).
"
" - If `auri' gives a query, then the file is executed (it should be an
"   executable program) with the query expression passed as arguments
"   arguments. The program's output is written to a (tempname constructed)
"   result file.  
"   
" - else, the local file itsself is the result file and is returned.
" 
"
fu! Thlnk_AddressScheme_file(auri)

    " authority: can be a
    " - windows drive `c:' `d:' etc
    " - host -> delegate then to ftp_scheme.
    "	Note: Also authority=`localhost' goes this way (is this wrong?)
    let authority = ThlnkUri_authority(a:auri)
"    echo 'DBG authority=`'.authority."'"
    let path = ''
    if authority =~? '^[a-z]:$'
	if has("win32") || has("win16") || has("dos32") || has("dos16")
"	    echo 'DBG authority is windows-drive:' . authority
	    let path = authority
	endif
    elseif authority != '<undef>' && authority != ''
	let ftpAbs = ThlnkUri_build('ftp', authority, ThlnkUri_path(a:auri), ThlnkUri_query(a:auri), '<undef>')
	return  Thlnk_AddressScheme_ftp(ftpAbs)
    endif

    let path = path . ThlnkUri_unescape(ThlnkUri_path(a:auri))

    " If Query defined, then execute the Path	    (id=filequery)
    " See <URL:vim_h:thlnk-filequery>
    let query = ThlnkUri_query(a:auri)
    if query != '<undef>'   " (N.B. empty query is not undef)

	"upd should make functions Query_form(), Query_keywords()
	if match(query, '&') != -1	    " id=query_form
	    "upd
	    " application/x-www-form-urlencoded query to be implemented
	    " (eg  `?foo=bar&otto=karl')
	    let v:errmsg = 'form encoded query to be implemented'
	    echohl ErrorMsg | echo v:errmsg | echohl None
	elseif match(query, '+') != -1		" id=query_keywords
	    let query = substitute(query, '+', ' ', 'g')
	endif
	let query = ThlnkUri_unescape(query)
	"upd Whitespace in keywords should now be escaped before handing
	"upd off to shell
"	echo 'DBG query=`'. query ."'"

	let cacheFile = Thlnk_utilSlash_Tempname()
	exe '!'.path." ". query ." ".cacheFile

	if v:shell_error
	    let v:errmsg = 'Shell Error from execute searchable Resource'
	    echohl ErrorMsg | echo v:errmsg | echohl None
	    call delete(cacheFile)
	    return ''
	endif
	return cacheFile

    endif

    " Test path for existence: don't like to get a ``[New File]'' in case
    " of a dangling link.  But bypass this test when its a directory to let
    " a possible file browser display the dir. (Works seamless with (or without)
    " file explorer, see <URL:vim_h:file-explorer> .)
    if isdirectory(path)
	"
    elseif ! filereadable(path)
	let v:errmsg = "file does not exist or is not readable: " . path
	echohl ErrorMsg | echo v:errmsg | echohl None
	return ''
    endif

    return path
endfu


"-------------------------------------------------------------------------------
"
fu! Thlnk_AddressScheme_ftp(auri)
    " (wget does both, and Thlnk_AddressScheme_http is not too specific)
    return  Thlnk_AddressScheme_http(a:auri)
endfu


"-------------------------------------------------------------------------------
" Retrieve resource with helper application `wget'
" - Always retrieves new document (like always saying `Reload' in Netscape;
"   a cache lookup is not done (yet))
"
fu! Thlnk_AddressScheme_http(auri)

    let path = ThlnkUri_path(a:auri)

    " Possibly transfer path's suffix to tempname  (id=tempsuff)
    " for media type handling (see <URL:vim_h:thlnk-defLocalPath>)
    " If no suffix then assume 'html' (this also holds for
    " URLs like `http://www.bf-consulting.de' where a file `index.html'
    " will be retrieved).
    " 
    "upd Should utilize HTTP HEADER or what?! The media type comes
    "upd with http (for example wget displays it). HTTP experts please!
    let suffix = fnamemodify(path, ":e")
    if suffix == ''
	let suffix = 'html'
    endif
"    echo 'DBG suffix=`'. suffix."'" 
    let cacheFile = Thlnk_utilSlash_Tempname() . '.' . suffix

    if has('unix')
	exe "!wget '".a:auri."' -O " . cacheFile
    else
	exe "!wget ".a:auri." -O " . cacheFile
    endif

    if v:shell_error
	let v:errmsg = 'Shell Error from wget retrieve'
	echohl ErrorMsg | echo v:errmsg | echohl None
	call delete(cacheFile)
	return ''
    endif

    return cacheFile
endfu


"-------------------------------------------------------------------------------
" Retrieve file via rcp.
"
fu! Thlnk_AddressScheme_rcp(auri)

    let path = ThlnkUri_path(a:auri)

    let cacheFile = Thlnk_utilSlash_Tempname()
    let suffix = fnamemodify(path, ":e")
    if suffix != ''
	let cacheFile = cacheFile . '.' . suffix
    endif

"    echo 'DBG suffix=`'. suffix."'" 

    let host = ThlnkUri_authority(a:auri)

    exe '!rcp ' . ThlnkUri_authority(a:auri).':'.path.' '.cacheFile
    if v:shell_error
	let v:errmsg = 'Shell Error from rcp'
	echohl ErrorMsg | echo v:errmsg | echohl None
	call delete(cacheFile)
	return ''
    endif

    return cacheFile
endfu


"-------------------------------------------------------------------------------
" A (hereby introduced) scheme for getting Vim help!
"
fu! Thlnk_AddressScheme_vim_h(auri)
    exe "help " . ThlnkUri_unescape( ThlnkUri_opaque(a:auri) )
    if v:errmsg =~ '^Sorry, no help for'
	return ''
    endif
    let curPath = Thlnk_utilSlash_ExpandFullPath()
    return curPath
endfu

"-------------------------------------------------------------------------------
" The mailto-URL.
" It was mainly implemented to serve as a demo. To show that a resource
" needs not to be a file or document.
"
" Returns '' als `localPath'. But you could create one perhaps containing
" the return receipt, e.g. 'mail sent succesfully'.
"
fu! Thlnk_AddressScheme_mailto(auri)

    if has('unix')
	" your favorite mailer here ->
	exe '!xterm -e mutt ' . ThlnkUri_opaque(a:auri)
	if v:shell_error
	    let v:errmsg = "Shell Error. Probably you have to edit Thlnk_AddressScheme_mailto()! "
	    echohl ErrorMsg | echo v:errmsg | echohl None
	endif
    else
	let v:errmsg = "Not implemented for your OS. Adapt Thlnk_AddressScheme_mailto() !"
	echohl ErrorMsg | echo v:errmsg | echohl None
    endif
    return ''
endfu

"-------------------------------------------------------------------------------
" Scheme for accessing Unix Man Pages.
" Useful for commenting program sources.
" Example: /* "See <URL:man:fopen#tn=r+> for the r+ argument" */
"upd: should support sections, i.e. <URL:man:fopen(3)#tn=r+>
"
fu! Thlnk_AddressScheme_man(auri)
    exe "Man " . ThlnkUri_unescape( ThlnkUri_opaque(a:auri) )
    if v:errmsg =~ '^Sorry, no man entry for'
	return ''
    endif
    let curPath = Thlnk_utilSlash_ExpandFullPath()
    return curPath
endfu

"-------------------------------------------------------------------------------
" ad hoc scheme quick and dirty
" Bsp: <lnk:vim_x:thlnk_vim#abc>
" erwartet eine Vim-Variable als Argument auri. Diese muss direkt
" einen lokalen Pfad angeben. Kein Query erlaubt.
" - Ohne Test, ob Variable definiert.
fu! Thlnk_AddressScheme_vim_x(auri)
    exe "let path = g:" . ThlnkUri_unescape( ThlnkUri_opaque(a:auri) )
    "uu test for existance (s. _file)
    return path
endfu

let &cpo = s:save_cpo
