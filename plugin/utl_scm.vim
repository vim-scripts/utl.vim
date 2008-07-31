" ------------------------------------------------------------------------------
" File:		plugin/utl_scm.vim -- callbacks implementing the different
"	        schemes
"			        Part of the Utl plugin, see ./utl.vim
" Author:	Stefan Bittner <stb@bf-consulting.de>
" Licence:	This program is free software; you can redistribute it and/or
"		modify it under the terms of the GNU General Public License.
"		See http://www.gnu.org/copyleft/gpl.txt
" Version:	utl 3.0a
" ------------------------------------------------------------------------------


" In this file some scheme specific retrieval functions are defined.
" For each scheme one function named Utl_AddrScheme_xxx() is needed.
"
" - If a scheme (i.e. functions) is missing, the caller Utl_processUrl()
"   will notice it and show an appropriate message to the user.
"
" - You can define your own functions:


" How to write a Utl_AddrScheme_xxx function		(id=implscmfunc)
" ------------------------------------------
" To implement a specific scheme (e.g. `file', `http') you have to write
" write a handler function named `Utl_AddrScheme_<scheme>' which obeys the
" following rules:
"
" - It takes three arguments:
"
"   1. Arg: Absolute URI
"   (See <URL:vimhelp:utl-uri-relabs> to get an absolute URI explained). The
"   given `auri' will not have a fragment (without #... at the end).
"
"   2. Arg: Fragment
"   Where the value will be '<undef>' if there is no fragment. In most cases a
"   handler will not actually deal with the fragment but leaves that job for
"   standard fragment processing in Utl by returning a non empty list (see
"   next). Examples for fragment processing handlers are
"   Utl_AddressScheme_http and Utl_AddressScheme_foot.
"
"   3. Arg: display Mode (dispMode)
"   Most handlers will ignore this argument. Exception for instance handlers
"   which actually display the retrieved or determined file like 
"   Utl_AddressScheme_foot. If your function is smart it might, if applicable,
"   support the special dispMode values copyFileName (see examples in this file).
"
"
" - It then does what ever it wants.
"   But what it normally wants is: retrieve, load, query, address the resource
"   identified by `auri'.

" - It Returns a list with 0 (empty list), 1 or 2 elements.    [id=scm_ret_list]
"   (See vimhelp:List if you don't know what a list is in Vim)
"
"   * Empty list means: no subsequent processing by Utl.vim
"     Examples where this makes sense:
"     ° If the retrieve was not successful, or
"     ° if handler already cared for displaying the file (e.g. URL
"       delegated to external handler)
"
"   * 1st list element = file name (called localPath) provided means:
"     a) Utl.vim will delegate localPath to the appropriate file type handler
"        or display it the file in Vim-Window.
"        It also possible, that the localPath is already displayed in this case
"        (Utl.vim will check if the localPath corresponds to a buffer name.)
"        Note : It is even possible that localPath does not correspond to
"        an existing file or to a file at all. Executing a http URL with
"        netrw is an example for this, see: ../plugin/utl_rc.vim#http_netrw.
"        Netrw uses the URL as buffer name.
"     c) Fragment will be processed (if any).
"
"     Details :
"     ° File name should be a pathname to (an existing) local file or directory.
"       Note : the 
"     ° File name's path separator should be slash (not backslash).
"     ° It does not hurt if file is already displayed (an example for this is
"       vimhelp scheme).
"
"   * 2nd list element = fragment Mode (fragMode). Allowed values:
"     `abs', 'rel'. Defaults to `abs' if no 2nd list element.
"     `abs': Fragment will be addressed to beginning of file. 
"     `rel': Fragment will be addressed relative to current cursor position
"            (example: Vimhelp scheme).

" 
" Specification of 'scheme handler variable interface'	(id=spec_ihsv)
" ----------------------------------------------------
" 
" - Variable naming: utl_cfg_hdl_scm_<scheme>
" 
" - Variables executed by :exe  (see <vimhelp::exe>).
"   This implies that the variable has to a valid ex command. (to execute more
"   than one line of ex commands a function can be called).
" 
" - Should handle the actual link, e.g. download the file.
"   But it can do whatever it wants :-)
" 
" - Input data: scheme specific conversion specifiers should appear in the
"   variable. They will be replaced by Utl.vim when executing an URL, e.g %u
"   will be replaced by the actual URL. The available conversion specifiers are
"   defined at <url:../plugin/utl_rc.vim#r=utl_cfg_hdl_scm_http> for http etc.
" 
" - Output data: an optional global list, which is the same as that of the
"   handler itself, see <url:../plugin/utl_scm.vim#r=scm_ret_list>. Since the
"   variable's value can be any ex command (and, for instance, not always a
"   function) a global variable is used:
"       g:utl_hdl_scm_ret_list
"   This variable will be initialized to an empty list [] by Utl.vim before
"   executing the contents of the variable. 
" 
" - Exception handling: Normally nothing needs to be done in the variable code.
"   Utl.vim checks for v:shell_error and v:errmsg after execution. There are
"   situation where setting v:errmsg makes sense. The variable might want to
"   issue the error message (Utl.vim does not).
" 


if exists("loaded_utl_scm") || &cp || v:version < 700
    finish
endif
let loaded_utl_scm = 1
let s:save_cpo = &cpo
set cpo&vim
let g:utl__file_scm = expand("<sfile>")

let s:utl_esccmdspecial = '%#'  " keep equal to utl.vim#__esc

"-------------------------------------------------------------------------------
" Addresses/retrieves a local file.
"
" - If `auri' gives a query, then the file is executed (it should be an
"   executable program) with the query expression passed as arguments
"   arguments. The program's output is written to a (tempname constructed)
"   result file.  
"   
" - else, the local file itself is the result file and is returned.
" 
fu! Utl_AddressScheme_file(auri, fragment, dispMode)
    call Utl_trace("- start execution of Utl_AddressScheme_file",1,1) 

    " authority: can be a
    " - windows drive, e.g. `c:'
    " - server name - interpret URL as a network share
    let authority = UtlUri_authority(a:auri)
    let path = ''
    if authority =~? '^[a-z]:$'
        if has("win32") || has("win16") || has("win64") || has("dos32") || has("dos16")
	    call Utl_trace("- Am under Windows. Server part denotes a Windows drive: `".authority."'")
	    let path = authority
	endif
    elseif authority != '<undef>' && authority != ''
        if has("win32") || has("win16") || has("win64") || has("dos32") || has("dos16")
	    call Utl_trace("- Am under Windows. Server part specified: `".authority."',")
	    call Utl_trace("  will convert to UNC path //server/sharefolder/path.")
	    let path = '//' . authority
	elseif has("unix")
	    call Utl_trace("- Am under Unix. Server part specified: `".authority."',")
	    call Utl_trace("  will convert to  server:/path")
	    " don't know if this really makes sense. See <http://en.wikipedia.org/wiki/Path_%28computing%29>
	    let path = authority . ':'
	endif
    endif

    let path = path . UtlUri_unescape(UtlUri_path(a:auri))
    call Utl_trace("- local path constructed from URL: `".path."'")

    " Support of tilde ~ notation.
    if stridx(path, "~") != -1
	let tildeuser = expand( substitute(path, '\(.*\)\(\~[^/]*\)\(.*\)', '\2', "") )
	let path = tildeuser .  substitute(path, '\(.*\)\(\~[^/]*\)\(.*\)', '\3', "")
	call Utl_trace("- found a ~ (tilde) character in path, expand to $HOME in local path:")
	let path = Utl_utilBack2FwdSlashes( path )
	call Utl_trace("  ".path."'")
    endif

    if a:dispMode =~ '^copyFileName'
	call Utl_trace("- mode is `copyFileName to clipboard': so quit after filename is known now") 
	call Utl_trace("- end execution of Utl_AddressScheme_file",1,-1) 
	return [path]
    endif

    " If Query defined, then execute the Path	    (id=filequery)
    let query = UtlUri_query(a:auri)
    if query != '<undef>'   " (N.B. empty query is not undef)
	call Utl_trace("- URL contains query expression (".query.") - so try to execute path") 

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
	let cacheFile = ''
	" If redirection char '>' at the end:
	" Supply a temp file for redirection and execute the program
	" synchronously to wait for its output
	if strlen(query)!=0 && stridx(query, '>') == strlen(query)-1 
	    call Utl_trace("- query with > character at end: assume output to a temp file and use it as local path")
	    let cacheFile = Utl_utilBack2FwdSlashes( tempname() )
	    let cmd = "!".path." ".query." ".cacheFile
	    call Utl_trace("- trying to execute command `".cmd."'")
	    exe cmd
	" else start it detached
	else
	    if has("win32") || has("win16") || has("win64") || has("dos32") || has("dos16")
		let cmd = "!start ".path." ".query
	    else
		let cmd = "!".path." ".query.'&'
	    endif
	    call Utl_trace("- trying to execute command `".cmd."'")
	    exe cmd
	endif
	
	if v:shell_error
	    let v:errmsg = 'Shell Error from execute searchable Resource'
	    echohl ErrorMsg | echo v:errmsg | echohl None
	    if cacheFile != ''
		call delete(cacheFile)
	    endif
	    call Utl_trace("- end execution of Utl_AddressScheme_file",1,-1) 
	    return []
	endif
	call Utl_trace("- end execution of Utl_AddressScheme_file",1,-1) 
	if cacheFile == ''
	    return []
	else 
	    return [cacheFile]
	endif

    endif

    call Utl_trace("- end execution of Utl_AddressScheme_file",1,-1) 
    return [path]
endfu


"-------------------------------------------------------------------------------
"
fu! Utl_AddressScheme_ftp(auri, fragment, dispMode)
    call Utl_trace("- start execution of Utl_AddressScheme_ftp",1,1) 
    call Utl_trace("- delegating to http scheme handler")
    let ret = Utl_AddressScheme_http(a:auri, a:fragment, a:dispMode)
    call Utl_trace("- end execution of Utl_AddressScheme_ftp",1,-1) 
    return ret
endfu


"-------------------------------------------------------------------------------
"
fu! Utl_AddressScheme_https(auri, fragment, dispMode)
    call Utl_trace("- start execution of Utl_AddressScheme_https",1,1) 
    call Utl_trace("- delegating to http scheme handler")
    let ret = Utl_AddressScheme_http(a:auri, a:fragment, a:dispMode)
    call Utl_trace("- end execution of Utl_AddressScheme_https",1,-1) 
    return ret
endfu

"-------------------------------------------------------------------------------
"
fu! Utl_AddressScheme_http(auri, fragment, dispMode)
    call Utl_trace("- start execution of Utl_AddressScheme_http",1,1) 

    if a:dispMode =~ '^copyFileName'
	echohl ErrorMsg | echo "function `copyFileName to clipboard' not possible for scheme `http:'" | echohl None
	call Utl_trace("- end execution of Utl_AddressScheme_http",1,-1) 
	return []
    endif

    if ! exists('g:utl_cfg_hdl_scm_http')    " Entering setup
	call Utl_trace("- Vim variable g:utl_cfg_hdl_scm_http does not exist")
	echohl WarningMsg
	call input("No scheme handler variable g:utl_cfg_hdl_scm_http defined yet. Entering Setup now. <RETURN>")
	echohl None
	Utl openLink config:#r=utl_cfg_hdl_scm_http split " (recursion, setup)
	call Utl_trace("- end execution of Utl_AddressScheme_http",1,-1) 
	return []
    endif
    call Utl_trace("- Vim variable g:utl_cfg_hdl_scm_http exists, value=`".g:utl_cfg_hdl_scm_http."'")

    let convSpecDict= { 'u': a:auri, 'f': a:fragment, 'd': a:dispMode }
    let [errmsg,cmd] = Utl_utilExpandConvSpec(g:utl_cfg_hdl_scm_http, convSpecDict)
    if errmsg != ""
	echohl ErrorMsg
	echo "The content of your Vim variable `".g:utl_cfg_hdl_scm_http."' is invalid and has to be fixed!"
	echo "Reason: `".errmsg."'"
	echohl None
	call Utl_trace("- end execution of Utl_AddressScheme_http",1,-1) 
	return []
    endif

    call Utl_trace("- Escape cmdline-special characters (".s:utl_esccmdspecial.") before execution")
    " see <URL:vimhelp:cmdline-special>).
    let cmd = escape( cmd, s:utl_esccmdspecial)

    let g:utl__hdl_scm_ret_list=[]
    let v:errmsg = ""
    call Utl_trace("- trying to execute command: `".cmd."'")
    exe cmd

    if v:shell_error || v:errmsg!=""
	call Utl_trace("- execution of scm handler returned with v:shell_error or v:errmsg set")
	call Utl_trace("  v:shell_error=`".v:shell_error."'")
	call Utl_trace("  v:errmsg=`".v:errmsg."'")
	call Utl_trace("- end execution of Utl_AddressScheme_http (not successful)",1,-1) 
	return []
    endif

    call Utl_trace("- end execution of Utl_AddressScheme_http (successful)",1,-1) 
    return g:utl__hdl_scm_ret_list
endfu

"-------------------------------------------------------------------------------
" Retrieve file via scp.
"
fu! Utl_AddressScheme_scp(auri, fragment, dispMode)
    call Utl_trace("- start execution of Utl_AddressScheme_scp",1,1) 

    if a:dispMode =~ '^copyFileName'
	echohl ErrorMsg | echo "function `copyFileName name to clipboard' not possible for scheme `scp:'" | echohl None
	call Utl_trace("- end execution of Utl_AddressScheme_scp",1,-1) 
	return []
    endif

    if ! exists('g:utl_cfg_hdl_scm_scp')    " Entering setup
	call Utl_trace("- Vim variable g:utl_cfg_hdl_scm_scp does not exist")
	echohl WarningMsg
	call input("No scheme handler variable g:utl_cfg_hdl_scm_scp defined yet. Entering Setup now. <RETURN>")
	echohl None
	Utl openLink config:#r=utl_cfg_hdl_scm_scp split " (recursion, setup)
	call Utl_trace("- end execution of Utl_AddressScheme_scp",1,-1) 
	return []
    endif
    call Utl_trace("- Vim variable g:utl_cfg_hdl_scm_scp exists, value=`".g:utl_cfg_hdl_scm_scp."'")

    let convSpecDict= { 'u': a:auri, 'f': a:fragment, 'd': a:dispMode }
    let [errmsg,cmd] = Utl_utilExpandConvSpec(g:utl_cfg_hdl_scm_scp, convSpecDict)
    if errmsg != ""
	echohl ErrorMsg
	echo "The content of your Vim variable `".g:utl_cfg_hdl_scm_scp."' is invalid and has to be fixed!"
	echo "Reason: `".errmsg."'"
	echohl None
	call Utl_trace("- end execution of Utl_AddressScheme_scp",1,-1) 
	return []
    endif

    call Utl_trace("- Escape cmdline-special characters (".s:utl_esccmdspecial.") before execution")
    " see <URL:vimhelp:cmdline-special>).
    let cmd = escape( cmd, s:utl_esccmdspecial)

    let g:utl__hdl_scm_ret_list=[]
    let v:errmsg = ""
    call Utl_trace("- trying to execute command: `".cmd."'")
    exe cmd

    if v:shell_error || v:errmsg!=""
	call Utl_trace("- execution of scm handler returned with v:shell_error or v:errmsg set")
	call Utl_trace("- end execution of Utl_AddressScheme_scp (not successful)",1,-1) 
	return []
    endif

    call Utl_trace("- end execution of Utl_AddressScheme_scp",1,-1) 
    return g:utl__hdl_scm_ret_list

endfu


"-------------------------------------------------------------------------------
" The mailto scheme.
" It was mainly implemented to serve as a demo. To show that a resource
" needs not to be a file or document.
"
" Returns empty list. But you could create one perhaps containing
" the return receipt, e.g. 'mail sent succesfully'.
"
fu! Utl_AddressScheme_mailto(auri, fragment, dispMode)
    call Utl_trace("- start execution of Utl_AddressScheme_mailto",1,1) 

    if a:dispMode =~ '^copyFileName'
	echohl ErrorMsg | echo "function `copyFileName name to clipboard' not possible for scheme `http:'" | echohl None
	call Utl_trace("- end execution of Utl_AddressScheme_http",1,-1) 
	return []
    endif

    if ! exists('g:utl_cfg_hdl_scm_mailto')    " Entering setup
	call Utl_trace("- Vim variable g:utl_cfg_hdl_scm_mailto does not exist")
	echohl WarningMsg
	call input("No scheme handler variable g:utl_cfg_hdl_scm_mailto defined yet. Entering Setup now. <RETURN>")
	echohl None
	Utl openLink config:#r=utl_cfg_hdl_scm_mailto split " (recursion, setup)
	call Utl_trace("- end execution of Utl_AddressScheme_mailto",1,-1) 
	return []
    endif
    call Utl_trace("- Vim variable g:utl_cfg_hdl_scm_mailto exists, value=`".g:utl_cfg_hdl_scm_mailto."'")

    let convSpecDict= { 'u': UtlUri_build_2(a:auri,a:fragment) }
    let [errmsg,cmd] = Utl_utilExpandConvSpec(g:utl_cfg_hdl_scm_mailto, convSpecDict)
    if errmsg != ""
	echohl ErrorMsg
	echo "The content of your Vim variable `".g:utl_cfg_hdl_scm_mailto."' is invalid and has to be fixed!"
	echo "Reason: `".errmsg."'"
	echohl None
	call Utl_trace("- end execution of Utl_AddressScheme_mailto",1,-1) 
	return []
    endif


    call Utl_trace("- Escape cmdline-special characters (".s:utl_esccmdspecial.") before execution")
    let cmd = escape( cmd, s:utl_esccmdspecial)

    let g:utl__hdl_scm_ret_list=[]
    let v:errmsg = ""
    call Utl_trace("- trying to execute command: `".cmd."'")
    exe cmd

    if v:shell_error || v:errmsg!=""
	call Utl_trace("- execution of scm handler returned with v:shell_error or v:errmsg set")
	call Utl_trace("- end execution of Utl_AddressScheme_mailto (not successful)",1,-1) 
	return []
    endif

    call Utl_trace("- end execution of Utl_AddressScheme_mailto",1,-1) 
    return g:utl__hdl_scm_ret_list
endfu

"-------------------------------------------------------------------------------
" Scheme for accessing Unix Man Pages.
" Useful for commenting program sources.
"
" Example: /* "See <URL:man:fopen#r+> for the r+ argument" */
"
" Possible enhancement: Support sections, i.e. <URL:man:fopen(3)#r+>
"
fu! Utl_AddressScheme_man(auri, fragment, dispMode)
    call Utl_trace("- start execution of Utl_AddressScheme_man",1,1) 

    if a:dispMode =~ '^copyFileName'
	echohl ErrorMsg | echo "function `copyFileName name to clipboard' not possible for scheme `man:'" | echohl None
	call Utl_trace("- end execution of Utl_AddressScheme_man",1,-1) 
	return []
    endif

    exe "Man " . UtlUri_unescape( UtlUri_opaque(a:auri) )
    if v:errmsg =~ '^Sorry, no man entry for'
	return []
    endif
    call Utl_trace("- end execution of Utl_AddressScheme_man",1,-1) 
    return [Utl_utilBack2FwdSlashes( expand("%:p") ), 'rel']
endfu

"-------------------------------------------------------------------------------
" Scheme for footnotes. Normally by heuristic URL like [1], which is
" transformed into foot:1 before calling this handler. Given
" foot:1  as reference, a referent is searched beginning from
" the end of the current file.  The referent can look like:
"   [1]	    or
"   [1]:
" where only whitespace can appear in front in the same line. If the reference
" has a fragment, e.g. [1]#string or even an empty fragment, e.g. [1]# 
" the value of the footnote is tried to derefence, i.e. automatic forwarding.
"
fu! Utl_AddressScheme_foot(auri, fragment, dispMode)
    call Utl_trace("- start execution of Utl_AddressScheme_foot",1,1) 

    if a:dispMode =~ '^copyFileName'
	echohl ErrorMsg | echo "function `copyFileName name to clipboard' not possible for scheme `foot:'" | echohl None
	call Utl_trace("- end execution of Utl_AddressScheme_foot",1,-1) 
	return []
    endif

    let opaque = UtlUri_unescape( UtlUri_opaque(a:auri) )

    let reftPat = '\c\m^\s*\(\['.opaque.'\]:\?\)'
    call Utl_trace("- searching for referent pattern `".reftPat."' bottom up until current line...",0)

    let refcLine = line('.') | let refcCol = col('.')
    call cursor( line('$'), col('$') )

    let reftLine = search(reftPat, 'Wb', refcLine+1)
    if reftLine==0
	call Utl_trace("not found")
    endif

    if reftLine==0
	call Utl_trace("- now searching for referent pattern `".reftPat."' top down until current line...",0)
	call cursor(1, 1)
	" (avoid stopline==0, this is special somehow. With -1 instead,
	"  stopping works in the case of reference in line 1)
	let reftLine = search(reftPat, 'Wc', refcLine==1 ? -1 : refcLine-1 )
	if reftLine==0
	    call Utl_trace("not found. Giving up")
	    call cursor(refcLine, refcCol)
	endif
    endif

    if reftLine==0
	let v:errmsg = "Reference has not target in current buffer. Provide another line starting with `[".opaque."]' or `".opaque.".' !"
	echohl ErrorMsg | echo v:errmsg | echohl None
	return []
    endif
    call Utl_trace("found, in line `".reftLine."'")

    " Feature automatic forwarding
    if a:fragment != '<undef>'
	call Utl_trace("- fragment is defined, so try dereferencing foonote's content")
	call Utl_trace("  by trying to position one character past referent")
	" This should exactly fail in case there is no one additional non white character
	let l=search(reftPat.'.', 'ce', reftLine)
	if l == 0 
	    let v:errmsg = "Cannot dereference footnote: Empty footnote"
	    echohl ErrorMsg | echo v:errmsg | echohl None
	    return []
	elseif l != reftLine
	    let v:errmsg = "Cannot dereference footnote: Internal Error: line number mismatch"
	    echohl ErrorMsg | echo v:errmsg | echohl None
	    return []
	endif
	call Utl_trace("- fine, footnote not empty and cursor positioned to start of its")
	call Utl_trace("  content (column ".col('.').") and try to get URL from under the cursor")

	let uriRef = Utl_getUrlUnderCursor()
	if uriRef == ''
	    let v:errmsg = "Cannot not dereference footnote: No URL under cursor"
	    echohl ErrorMsg | echo v:errmsg | echohl None
	    return []
	endif
	call Utl_trace("- combine URL / URL-reference under cursor with fragment of [] reference")
	let uri = UriRef_getUri(uriRef)
	let fragmentOfReferent = UriRef_getFragment(uriRef)
	if fragmentOfReferent != '<undef>' 
	    call Utl_trace("- discard non empty fragment `".fragmentOfReferent."' of referent")
	endif
	call Utl('openLink', UtlUri_build_2(uri, a:fragment), a:dispMode)
	endif

	call Utl_trace("- end execution of Utl_AddressScheme_foot",1,-1) 
	return []
    endif

    call Utl_trace("- end execution of Utl_AddressScheme_foot",1,-1) 
    return [Utl_utilBack2FwdSlashes( expand("%:p") )]
endfu

"-------------------------------------------------------------------------------
" A scheme for quickly going to the setup file utl_rc.vim, e.g.
"	:Gu config:
"
fu! Utl_AddressScheme_config(auri, fragment, dispMode)
    call Utl_trace("- start execution of Utl_AddressScheme_config",1,1) 
    let path = g:utl__file_rc 
    call Utl_trace("- set local path to equal utl variable g:utl__file_scm: `".path."'")
    call Utl_trace("- end execution of Utl_AddressScheme_config",1,-1) 
    return [ Utl_utilBack2FwdSlashes(path) ]
endfu

"id=vimscript-------------------------------------------------------------------
" A non standard scheme for executing vim commands
"	<URL:vimscript:set ts=4>
"
fu! Utl_AddressScheme_vimscript(auri, fragment, dispMode)
    call Utl_trace("- start execution of Utl_AddressScheme_vimscript",1,1) 

    if a:dispMode =~ '^copyFileName'
	echohl ErrorMsg | echo "function `copyFileName name to clipboard' not possible for scheme `vimscript:'" | echohl None
	call Utl_trace("- end execution of Utl_AddressScheme_vimscript",1,-1) 
	return []
    endif

    let exCmd = UtlUri_unescape( UtlUri_opaque(a:auri) )
    call Utl_trace("- executing Vim Ex-command: `:".exCmd."'\n")	    " CR054_extra_nl
    "echo "                                DBG utl_opt_verbose=`".g:utl_opt_verbose."'"
    exe exCmd
    "echo "                                DBG (after) utl_opt_verbose=`".g:utl_opt_verbose."'"
    call Utl_trace("- end execution of Utl_AddressScheme_vimscript (successful)",1,-1) 
    return  []
endfu

fu! Utl_AddressScheme_vimtip(auri, fragment, dispMode)
    call Utl_trace("- start execution of Utl_AddressScheme_vimtip",1,1) 
    let url = "http://vim.sf.net/tips/tip.php?tip_id=". UtlUri_unescape( UtlUri_opaque(a:auri) )
    call Utl_trace("- delegating to http scheme handler with URL `".url."'")
    let ret = Utl_AddressScheme_http(url, a:fragment, a:dispMode)
    call Utl_trace("- end execution of Utl_AddressScheme_vimtip",1,-1) 
    return ret
endfu

"-------------------------------------------------------------------------------
" A non standard scheme for getting Vim help
"
fu! Utl_AddressScheme_vimhelp(auri, fragment, dispMode)
    call Utl_trace("- start execution of Utl_AddressScheme_vimhelp",1,1) 

    if a:dispMode =~ '^copyFileName'
	echohl ErrorMsg | echo "function `copyFileName name to clipboard' not possible for scheme `vimhelp:'" | echohl None
	call Utl_trace("- end execution of Utl_AddressScheme_vimhelp",1,-1) 
	return []
    endif

    let exCmd = "help ".UtlUri_unescape( UtlUri_opaque(a:auri) )
    call Utl_trace("- executing Vim Ex-command: `:".exCmd."'\n")	    " CR054_extra_nl
    exe exCmd
    if v:errmsg =~ '^Sorry, no help for'
	call Utl_trace("- end execution of Utl_AddressScheme_vimhelp",1,-1) 
	return []
    endif
    call Utl_trace("- end execution of Utl_AddressScheme_vimhelp (successful)",1,-1) 
    return [ Utl_utilBack2FwdSlashes( expand("%:p") ), 'rel' ]
endfu

"-------------------------------------------------------------------------------
" The mail-scheme.
" This is not an official scheme in the internet. I invented it to directly
" access individual Mails from a mail client.
"
" Synopsis :
"   mail://<box-path>?query
"
"   where query = [date=]<date>[&from=<from>][&subject=<subject>]
"
" Examples :
"   <url:mail:///Inbox?24.07.2007 13:23>
"   <url:mail://archive/Inbox?24.07.2007 13:23>
"
fu! Utl_AddressScheme_mail(auri, fragment, dispMode)
    call Utl_trace("- start execution of Utl_AddressScheme_mail",1,1) 

    if a:dispMode =~ '^copyFileName'
	echohl ErrorMsg | echo "function `copyFileName name to clipboard' not possible for scheme `mail:'" | echohl None
	call Utl_trace("- end execution of Utl_AddressScheme_mail",1,-1) 
	return []
    endif

    if ! exists('g:utl_cfg_hdl_scm_mail')    " Entering setup
	call Utl_trace("- Vim variable g:utl_cfg_hdl_scm_mail does not exist")
	echohl WarningMsg
	call input("No scheme handler variable g:utl_cfg_hdl_scm_mail defined yet. Entering Setup now. <RETURN>")
	echohl None
	Utl openLink config:#r=utl_cfg_hdl_scm_mail split
	call Utl_trace("- end execution of Utl_AddressScheme_mail",1,-1) 
	return []
    endif
    call Utl_trace("- Vim variable g:utl_cfg_hdl_scm_mail exists, value=`".g:utl_cfg_hdl_scm_mail."'")

    let authority = UtlUri_unescape( UtlUri_authority(a:auri) )
    let path = UtlUri_unescape( UtlUri_path(a:auri) )
    let query = UtlUri_unescape( UtlUri_query(a:auri) )
    call Utl_trace("- URL path components: authority=`".authority."', path=`".path."'" )

    " Parse query expression
    if query == '<undef>' || query == ""
	let v:errmsg = 'Query expression missing'
	echohl ErrorMsg | echo v:errmsg | echohl None
	return []
    endif
    let q_from =    ''
    let q_subject = ''
    let q_date =    ''
    while 1
	let pos = stridx(query, '&')
	if pos == -1
	    let entry = query
	else
	    let entry = strpart(query, 0, pos)
	    let query = strpart(query, pos+1)
	endif

	if entry =~ '^from='
	    let q_from = substitute(entry, '.*=', '', '')
	elseif entry =~ '^subject='
	    let q_subject = substitute(entry, '.*=', '', '')
	elseif entry =~ '^date='
	    let q_date = substitute(entry, '.*=', '', '')
	else
	    let q_date = entry
	endif
	if pos == -1
	    break
	endif
    endwhile
    call Utl_trace("- URL query attributes: date=`".q_date."', subject=`".q_subject."', from=`".q_from."'" )

    let convSpecDict= { 'a': authority, 'p': path, 'd': q_date, 'f': q_from, 's': q_subject }
    let [errmsg,cmd] = Utl_utilExpandConvSpec(g:utl_cfg_hdl_scm_mail, convSpecDict)
    if errmsg != ""
	echohl ErrorMsg
	echo "The content of your Vim variable g:utl_cfg_hdl_scm_mail=".g:utl_cfg_hdl_scm_mail."' is invalid and has to be fixed!"
	echo "Reason: `".errmsg."'"
	echohl None
	call Utl_trace("- end execution of Utl_AddressScheme_mail (not successful)",1,-1) 
	return []
    endif

    call Utl_trace("- Escape cmdline-special characters (".s:utl_esccmdspecial.") before execution")
    let cmd = escape( cmd, s:utl_esccmdspecial)

    let g:utl__hdl_scm_ret_list=[]
    let v:errmsg = ""
    call Utl_trace("- trying to execute command `".cmd."'")
    exe cmd

    if v:shell_error || v:errmsg!=""
	call Utl_trace("- execution of scm handler returned with v:shell_error or v:errmsg set")
	call Utl_trace("- end execution of Utl_AddressScheme_mail (not successful)",1,-1) 
	return []
    endif

    call Utl_trace("- end execution of Utl_AddressScheme_mail (successful)",1,-1) 
    return g:utl__hdl_scm_ret_list
endfu

let &cpo = s:save_cpo

