" ------------------------------------------------------------------------------
" File:		utlscm.vim -- callbacks implementing the different schemes
"			        Part of the Utl plugin, see ./utl.vim
" Author:	Stefan Bittner <stb@bf-consulting.de>
" Licence:	This program is free software; you can redistribute it and/or
"		modify it under the terms of the GNU General Public License.
"		See http://www.gnu.org/copyleft/gpl.txt
" Version:	utl 2.0, $Revision: 1.10 $
" ------------------------------------------------------------------------------


" In this file some scheme specific retrieval functions are defined.
" For each scheme one function named Utl_AddrScheme_xxx() is needed.
"
" - If a scheme (i.e. functions) is missing, the caller Utl_processUrl()
"   will notice it and show an appropriate message to the user.
"
" - You can define your own functions (<URL:#r=implscmfunc>), change the existing
"   ones (better adapat for Windows), delete the existing ones.


" How to write a Utl_AddrScheme_xxx function		(id=implscmfunc)
" ------------------------------------------
" To implement a specific scheme (e.g. `file', `http') you have to write
" write a function named `Utl_AddrScheme_<scheme>' which obeys the
" following rules:
" - It takes an absolute URI `auri' <URL:vimhelp:utl-uri-relabs>
"   as its only argument. The given `auri' will not have a fragment, i.e.
"   `auri' is not an URI reference (fragments are treated by the caller).
" - Then does what ever it wants.
"     But what it normally wants is: retrieve, load, query, address the
"   resource identified by `auri'.
" - Returns any pathname to an existing local file or directory
"   (may be be created according to #line=-4
"   An empty pathname is allowed (i.e. ``retrieve not successful'' or
"   ``no file corresponding''). No further processing on the caller side then.
"     The meaning of the pathname is `localPath', see
"   <URL:vimhelp:utl-internals#LocalPath> (the MapSet() is done by
"   the caller). `LocalPath' normally will be the retrieved document (i.e. an
"   ad hoc generated file with random name) or just the determined local
"   resource or file (e.g. with scheme `file').
"     Utl_AddrScheme_<scheme> _may_ display the `localPath' (vimhelp scheme!)
"   but normally it leaves that up to the caller (utl.vim) because the
"   display (more exact: processing) does not depend on the scheme rather
"   than on the media type.


if exists("loaded_utl_scm")
    finish
endif
let loaded_utl_scm = 1
let s:save_cpo = &cpo
set cpo&vim
let g:utl_scm_vim = expand("<sfile>")

"-------------------------------------------------------------------------------
" Addresses/retrieves a local file (but when a host is given
" then delegate to Utl_AddressScheme_ftp).
"
" - If `auri' gives a query, then the file is executed (it should be an
"   executable program) with the query expression passed as arguments
"   arguments. The program's output is written to a (tempname constructed)
"   result file.  
"   
" - else, the local file itsself is the result file and is returned.
" 
fu! Utl_AddressScheme_file(auri)

    " authority: can be a
    " - windows drive `c:' `d:' etc
    " - host -> delegate then to ftp_scheme.
    "	Note: Also authority=`localhost' goes this way (is this wrong?)
    let authority = UtlUri_authority(a:auri)
    let path = ''
    if authority =~? '^[a-z]:$'
	if has("win32") || has("win16") || has("dos32") || has("dos16")
	    let path = authority
	endif
    elseif authority != '<undef>' && authority != ''
	let ftpAbs = UtlUri_build('ftp', authority, UtlUri_path(a:auri), UtlUri_query(a:auri), '<undef>')
	return  Utl_AddressScheme_ftp(ftpAbs)
    endif

    let path = path . UtlUri_unescape(UtlUri_path(a:auri))


    " Support of tilde ~ notation.
    if stridx(path, "~") != -1
	let tildeuser = expand( substitute(path, '\(.*\)\(\~[^/]*\)\(.*\)', '\2', "") )
	let path = tildeuser .  substitute(path, '\(.*\)\(\~[^/]*\)\(.*\)', '\3', "")
    endif


    " If Query defined, then execute the Path	    (id=filequery)
    " See <URL:vimhelp:utl-filequery>
    let query = UtlUri_query(a:auri)
    if query != '<undef>'   " (N.B. empty query is not undef)

	" (Should make functions Query_form(), Query_keywords())
	if match(query, '&') != -1	    " id=query_form
	    " (application/x-www-form-urlencoded query to be implemented
	    "  e.g.  `?foo=bar&otto=karl')
	    let v:errmsg = 'form encoded query to be implemented'
	    echohl ErrorMsg | echo v:errmsg | echohl None
	elseif match(query, '+') != -1		" id=query_keywords
	    let query = substitute(query, '+', ' ', 'g')
	endif
	let query = UtlUri_unescape(query)
	" (Whitespace in keywords should now be escaped before handing off to shell)
	"echo "DBG query=`".query."'"
	"echo "DBG strlen=`".strlen(query)."'"
	"echo "DBG stridx=`".stridx(query,'>')."'"
	let cacheFile = ''
	" If redirection char '>' at the end:
	" Supply a temp file for redirection and execute the program
	" synchronously to wait for its output
	if strlen(query)!=0 && stridx(query, '>') == strlen(query)-1 
	    let cacheFile = Utl_utilSlash_Tempname()
	    exe '!'.path." ". query ." ".cacheFile
	" else start it detached
	else
	    if has("win32")
		exe '!start '.path." ". query
	    else
		exe '!'.path." ". query. '&'
	    endif
	endif
	
	if v:shell_error
	    let v:errmsg = 'Shell Error from execute searchable Resource'
	    echohl ErrorMsg | echo v:errmsg | echohl None
	    if cacheFile != ''
		call delete(cacheFile)
	    endif
	    return ''
	endif
	return cacheFile

    endif

    return path
endfu


"-------------------------------------------------------------------------------
"
fu! Utl_AddressScheme_javascript(auri)
    return  Utl_AddressScheme_http(a:auri)
endfu

"-------------------------------------------------------------------------------
"
fu! Utl_AddressScheme_ftp(auri)
    return  Utl_AddressScheme_http(a:auri)
endfu


"-------------------------------------------------------------------------------
"
fu! Utl_AddressScheme_https(auri)
    return Utl_AddressScheme_http(a:auri)
endfu

"-------------------------------------------------------------------------------
"
fu! Utl_AddressScheme_http(auri)

    if ! exists('g:utl_rc_app_browser')    " Entering setup
	echohl WarningMsg
	call input("No browser defined yet. Entering Setup now. <RETURN>")
	echohl None
	call Utl_processUrl('config:#r=app_browser', 'split') " (recursion, setup)
	return ''
    endif

    let app_browser = g:utl_rc_app_browser

    " substitute %u in browser variable {
    let percPos = stridx(app_browser, '%')
    let percChar = strpart(app_browser, percPos+1, 1)
    if percChar ==# 'u'
	let app_browser = strpart(app_browser, 0, percPos) . a:auri . strpart(app_browser, percPos+2)
    else
	echohl ErrorMsg | echo "You have to supply a %u conversion specifier in variable utl_rc_app_browser!" | echohl None
    endif
    " Check for a second %u
    " Ad hoc and quick and dirty for firefox sample with two %u. Should allow
    " random number of %u, but implement that performant enough
    let percPos = stridx(app_browser, '%')
    if( percPos != -1 ) 
	let percChar = strpart(app_browser, percPos+1, 1)
	if percChar ==# 'u'
	    let app_browser = strpart(app_browser, 0, percPos) . a:auri . strpart(app_browser, percPos+2)
	endif
    endif
    " }


    " Prepare string to be executed as a ex command (i.e. escape some
    " characters from special treatment <URL:vimhelp:cmdline-special>).
    let app_browser = escape( app_browser, g:utl_esccmdspecial)

    exe app_browser

    if v:shell_error
	let v:errmsg = 'Shell error from calling browser'
	echohl ErrorMsg | echo v:errmsg | echohl None
	return ''
    endif

    return ''
endfu

"-------------------------------------------------------------------------------
" Retrieve file via scp.
"
fu! Utl_AddressScheme_scp(auri)

    let path = UtlUri_path(a:auri)

    let cacheFile = Utl_utilSlash_Tempname()
    let suffix = fnamemodify(path, ":e")
    if suffix != ''
	let cacheFile = cacheFile . '.' . suffix
    endif

    let host = UtlUri_authority(a:auri)

    exe '!scp ' . UtlUri_authority(a:auri).':'.path.' '.cacheFile
    if v:shell_error
	let v:errmsg = 'Shell Error from rcp'
	echohl ErrorMsg | echo v:errmsg | echohl None
	call delete(cacheFile)
	return ''
    endif

    return cacheFile
endfu


"-------------------------------------------------------------------------------
" The mailto-URL.
" It was mainly implemented to serve as a demo. To show that a resource
" needs not to be a file or document.
"
" Returns '' als `localPath'. But you could create one perhaps containing
" the return receipt, e.g. 'mail sent succesfully'.
"
fu! Utl_AddressScheme_mailto(auri)

    if ! exists('g:utl_rc_app_mailer')    " Entering setup
	echohl WarningMsg
	call input("No mail client defined yet. Entering Setup now. <RETURN>")
	echohl None
	call Utl_processUrl('utl_rc.vim#r=app_mailclient', 'split') " (recursion, setup)
	return ''
    endif

    let app_mailer = g:utl_rc_app_mailer

    " substitute %u in mailer variable
    let percPos = stridx(app_mailer, '%')
    let percChar = strpart(app_mailer, percPos+1, 1)
    if percChar ==# 'u'
	let app_mailer = strpart(app_mailer, 0, percPos) . a:auri . strpart(app_mailer, percPos+2)
    else
	echohl ErrorMsg | echo "You have to supply a %u conversion specifier in variable utl_rc_app_mailer!" | echohl None
    endif

    " Prepare string to be executed as a ex command (i.e. escape some
    " characters from special treatment <URL:vimhelp:cmdline-special>).
    let app_mailer = escape( app_mailer, g:utl_esccmdspecial)

    exe app_mailer

    if v:shell_error
	let v:errmsg = 'Shell error from calling mail client'
	echohl ErrorMsg | echo v:errmsg | echohl None
	return ''
    endif

    return ''
endfu

"-------------------------------------------------------------------------------
" Scheme for accessing Unix Man Pages.
" Useful for commenting program sources.
"
" Example: /* "See <URL:man:fopen#r+> for the r+ argument" */
"
" Possible enhancement: Support sections, i.e. <URL:man:fopen(3)#r+>
"
fu! Utl_AddressScheme_man(auri)
    exe "Man " . UtlUri_unescape( UtlUri_opaque(a:auri) )
    if v:errmsg =~ '^Sorry, no man entry for'
	return ''
    endif
    let curPath = Utl_utilSlash_ExpandFullPath()
    return curPath
endfu

"-------------------------------------------------------------------------------
" A scheme for quickly going to the setup file utl_rc.vim, e.g.
"	:Gu config:
" I think netscape did also support a config: scheme
"
fu! Utl_AddressScheme_config(auri)
    let path = g:utl_rc_vim 
    return  path
endfu

"id=vimscript-------------------------------------------------------------------
" A non standard scheme for executing vim commands
"	<URL:vimscript:set ts=4>
"
fu! Utl_AddressScheme_vimscript(auri)
    echo "executing vimscript: `" . UtlUri_unescape( UtlUri_opaque(a:auri) ) . "'"
    exe UtlUri_unescape( UtlUri_opaque(a:auri) )
    return  ''
endfu

"-------------------------------------------------------------------------------
" A non standard scheme for getting Vim help
"
fu! Utl_AddressScheme_vimhelp(auri)
    exe "help " . UtlUri_unescape( UtlUri_opaque(a:auri) )
    if v:errmsg =~ '^Sorry, no help for'
	return ''
    endif
    let curPath = Utl_utilSlash_ExpandFullPath()
    return curPath
endfu

"-------------------------------------------------------------------------------
" for backward compatibility
"
fu! Utl_AddressScheme_vim_h(auri)
    return  Utl_AddressScheme_vimhelp(a:auri)
endfu

"-------------------------------------------------------------------------------
" A private scheme for addressing entries of the `Perfect Tracker' bug
" tracking system in my job.
" See also <URL:utl.vim#r=heur_example>
"
fu! Utl_AddressScheme_bt(auri)
    let ptId = UtlUri_unescape( UtlUri_opaque(a:auri) )
    let ptUrl = 'http://bugtracker.ww010.siemens.net/bt/ticket/ticketView.ssp?ticket_id='.ptId
    return  Utl_AddressScheme_http(ptUrl)
endfu

let &cpo = s:save_cpo
