" ------------------------------------------------------------------------------
" File:		utl.vim - Universal Text Linking - 
"			  URL based Hyperlinking for plain text
" Author:	Stefan Bittner <stb@bf-consulting.de>
" Maintainer:	Stefan Bittner <stb@bf-consulting.de>
"
" Licence:	This program is free software; you can redistribute it and/or
"		modify it under the terms of the GNU General Public License.
"		See http://www.gnu.org/copyleft/gpl.txt
"		This program is distributed in the hope that it will be
"		useful, but WITHOUT ANY WARRANTY; without even the implied
"		warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
"
" Version:	utl 2.0, $Revision: 1.9 $
"
" Docs:		for online help type:	:help utl-plugin
"
" Files:	The Utl plugin consists of the following files:
"		plugin/{utl.vim,utl_scm.vim,utl_arr.vim,utl_uri.vim,utl_rc.vim}
"		doc/{utlusr.txt,utlref.txt}
"
" History:
" 1.0   2001-04-26
"		First release for vim5 under the name thlnk.vim
" 1.1   2002-05-07
"		As plugin for vim6 with heavily revised documentation and homepage
" 1.2   2002-06-14
"		Two bug fixes, better error messages, largely enhanced documentation
" 1.2.1 2002-06-15
"		Bug fix. Better 'ff' setting for distribution files
" --- Renamed plugin from Thlnk to Utl ---
" 2.0	2005-03-22
"		Configurable scheme and media type handlers, syntax
"		highlighting, naked URL support, #tn as default, heuristic
"		support and other new features. See ../doc/utl_usr.txt#utl-changes
" ------------------------------------------------------------------------------

if exists("loaded_utl")
    finish
endif
let loaded_utl = 1
let s:save_cpo = &cpo
set cpo&vim
let g:utl_vim = expand("<sfile>")


"--- Mappings (id=mappings)
"
" ... for executing the URL under the cursor
if ! hasmapto(":call Utl_goUrl('view')<CR>","n")
nmap <unique> <Leader>gv :call Utl_goUrl('view')<CR>
endif
if ! hasmapto(":call Utl_goUrl('edit')<CR>","n")
nmap <unique> <Leader>ge :call Utl_goUrl('edit')<CR>
" make a default hot key: gu = Go Url
nmap <unique> <Leader>gu :call Utl_goUrl('edit')<CR>
endif
if ! hasmapto(":call Utl_goUrl('sview')<CR>","n")
nmap <unique> <Leader>gV :call Utl_goUrl('sview')<CR>
endif
if ! hasmapto(":call Utl_goUrl('split')<CR>","n")
nmap <unique> <Leader>gE :call Utl_goUrl('split')<CR>
endif
if ! hasmapto(":call Utl_goUrl('vsplit')<CR>","n")
nmap <unique> <Leader>gS :call Utl_goUrl('vsplit')<CR>
endif
if ! hasmapto(":call Utl_goUrl('read')<CR>","n")
nmap <unique> <Leader>gr :call Utl_goUrl('read')<CR>
endif
"
" ... for executing the visual marked URL
if ! hasmapto("\"*y:call Utl_goUrlVis('view')<CR>","v")
vmap <unique> <Leader>gv "*y:call Utl_goUrlVis('view')<CR>
endif
if ! hasmapto("\"*y:call Utl_goUrlVis('edit')<CR>","v")
vmap <unique> <Leader>ge "*y:call Utl_goUrlVis('edit')<CR>
" make a default hot key: gu = Go Url (Visual Mode)
vmap <unique> <Leader>gu "*y:call Utl_goUrlVis('edit')<CR>
endif
if ! hasmapto("\"*y:call Utl_goUrlVis('sview')<CR>","v")
vmap <unique> <Leader>gV "*y:call Utl_goUrlVis('sview')<CR>
endif
if ! hasmapto("\"*y:call Utl_goUrlVis('split')<CR>","v")
vmap <unique> <Leader>gE "*y:call Utl_goUrlVis('split')<CR>
endif
if ! hasmapto("\"*y:call Utl_goUrlVis('vsplit')<CR>","v")
vmap <unique> <Leader>gS "*y:call Utl_goUrlVis('vsplit')<CR>
endif
if ! hasmapto("\"*y:call Utl_goUrlVis('read')<CR>","v")
vmap <unique> <Leader>gr "*y:call Utl_goUrlVis('read')<CR>
endif
"
" ... for displaying the cache
if ! hasmapto(":call Utl_viewResourceMap()<CR>","n")
nmap <unique> <Leader>gc :call Utl_viewResourceMap()<CR>
endif
"

" ... for showing the associated URL (if any) for the active buffer
if ! hasmapto(":call Utl_showCurUrl()<CR>","n")
nmap <unique> <Leader>gs :call Utl_showCurUrl()<CR>
endif
"

let g:utl_esccmdspecial = '%#'

" isfname adapted to URI Reference characters
let s:isuriref="@,48-57,#,;,/,?,:,@-@,&,=,+,$,,,-,_,.,!,~,*,',(,)"

" Last URL position - Start and end position of last executed URL. Defined by
" line/column. Always set when an URL from a buffer is executed (e.g. with
" \gu). S:lup_lbeg set to 0 when an URL is not executed from a buffer (e.g.
" with :Gu).
" - Introduced ad hoc for fragment processing (position the cursor out of the
"   URL body to avoid self references when searching)
" - Maybe used in future for parsing all URLs in a buffer
" - Is currently not fully correct: s:lup_lend wrong in multiline URLs and
"   is not accurat anyway (embedding counted y/n, ws before URL) - but
"   sufficient for the current task.
let s:lup_lbeg = 0  
let s:lup_cbeg = 0
let s:lup_lend = 0
let s:lup_cend = 0

fu! Utl_finish_installation()

    " 1. Uninstall any old thlnk installation
    if ! exists("g:thlnk_vim")
	echo "Info: Ok, no previous Utl/Thlnk installation found"
    else 
	echo "Info: Old thlnk.vim installation detected"
	echo "Info: I will try to rename to .ori. Otherwise collision with utl plugin"
	echo "Info: You can remove these thlnk*.ori files later if Utl works fine"
	let ffrom=g:thlnk_vim
	let fto=ffrom.".ori"
	if rename(ffrom, fto)==0
	    echo "Info: file ".ffrom. " renamed to ".fto
	else
	    echohl ErrorMsg
	    echo "Error: could not rename ".ffrom. " to ".fto.". Reason: ".v:errmsg
	    echohl None
	endif

	let ffrom=g:thlnkarr_vim
	let fto=ffrom.".ori"
	if rename(ffrom, fto)==0
	    echo "Info: file ".ffrom. " renamed to ".fto
	else
	    echohl ErrorMsg
	    echo "Error: could not rename ".ffrom. " to ".fto.". Reason: ".v:errmsg
	    echohl None
	endif

	let ffrom=g:thlnkscm_vim
	let fto=ffrom.".ori"
	if rename(ffrom, fto)==0
	    echo "Info: file ".ffrom. " renamed to ".fto
	else
	    echohl ErrorMsg
	    echo "Error: could not rename ".ffrom. " to ".fto.". Reason: ".v:errmsg
	    echohl None
	endif

	let ffrom=g:thlnkuri_vim
	let fto=ffrom.".ori"
	if rename(ffrom, fto)==0
	    echo "Info: file ".ffrom. " renamed to ".fto
	else
	    echohl ErrorMsg
	    echo "Error: could not rename ".ffrom. " to ".fto.". Reason: ".v:errmsg
	    echohl None
	endif

	" Rename thlnk help files

	let thlnk_doc_path = fnamemodify( g:thlnk_vim, ":h:h") . "/doc"

	let ffrom=thlnk_doc_path."/thlnkusr.txt"
	let fto=ffrom.".ori"
	if rename(ffrom, fto)==0
	    echo "Info: file ".ffrom. " renamed to ".fto
	else
	    echohl ErrorMsg
	    echo "Error: could not rename ".ffrom. " to ".fto.". Reason: ".v:errmsg
	    echohl None
	endif

	let ffrom=thlnk_doc_path."/thlnkref.txt"
	let fto=ffrom.".ori"
	if rename(ffrom, fto)==0
	    echo "Info: file ".ffrom. " renamed to ".fto
	else
	    echohl ErrorMsg
	    echo "Error: could not rename ".ffrom. " to ".fto.". Reason: ".v:errmsg
	    echohl None
	endif

    endif

    " 2. Create the help tags

    let doc_path = fnamemodify( g:utl_vim, ":h:h") . "/doc"
    exe 'helptags ' . doc_path
    echo "Info: helptags generated"

endfu


"--- Frontends [

"----------------------------------------------------------id=thl_gourl---------
" Process URL (or read: URI, if you like---Utl isn't exact there) under
" cursor: searches for something like <URL:myUrl> or <A HREF="myUrl"> (depending
" on the context), extracts myUrl, an processes that Url (e.g. retrieves the
" document and displays it).
"
" - Arg showAttr -> see <URL:#r=showAttr>
"
fu! Utl_goUrl(showAttr)

    let line = getline('.')
    let s:lup_lbeg = line(".")
    let s:lup_lend = s:lup_lbeg
    let icurs = col('.') - 1	" `Index-Cursor'
    let url = Utl_extractUrl(line, icurs)

    if url=='<undef>'	" multiline retry
	let lineno = line('.')
	" (lineno-1/2 can be negative -> getline gives empty string -> ok)
	let line = getline(lineno-2) . "\n" . getline(lineno-1) . "\n" .
		 \ getline(lineno) . "\n" .
		 \ getline(lineno+1) . "\n" . getline(lineno+2)
	" `Index of Cursor'
	" (icurs off by +2 because of 2 \n's, plus -1 because col() starts at 1 =    +1)
	let icurs = strlen(getline(lineno-2)) + strlen(getline(lineno-1)) + col('.') +1

	let url = Utl_extractUrl(line, icurs)
    endif

    if url=='<undef>'	" no embedding retry (will rarely fail)
	" Take <cfile> as URL. But adapt isfname to match all allowed URI
	" Reference characters
	let isfname_save = &isfname | let &isfname = s:isuriref " ([)
	let url = expand("<cfile>")
	let &isfname = isfname_save " (]) 
	" pragmatic solution: set lup cols to first/last col in line (no easy
	" way to get <cfile> start/end position)
	let s:lup_cbeg = 1
	let s:lup_cend = col('$')
    endif

    if url!=''
	call Utl_processUrl(url, a:showAttr)
    else
      let v:errmsg = "No Link under Cursor"
      echohl ErrorMsg | echo v:errmsg | echohl None
    endif
endfu


"-------------------------------------------------------------id=thl_gourlvis---
" Alternative to Utl_goUrl(). Call Utl_processUrl on a visual area.
" Useful, when Url not recognized by Utl_goUrl() because of an
" unknown embedding. It is assumend that the Visual Area is yanked into
" the * register; see "*y example below (Not explicit necessary for X11
" but important on Windows when not guioptions+=a set).
"
" Example: On a line like:
"   `Visite our homepage at http://www.foo.de and win a price'
"   you visual this         -----------------   and `"*y:call Utl_goUrlVis('view')
"
" - Arg showAttr -> <URL:#r=showAttr>
"
fu! Utl_goUrlVis(showAttr)
    " highlighted text into variable `url' ; seems too complicated, but
    " just let url=@* doesn't work on windows GUI without guioptions+=a
    " Using @* register isn't perfectly nice.
    normal `<"*y`>
    let url = @*
    normal `>"*yl
    let url = url . @*

    let s:lup_lbeg = line("'<")
    let s:lup_lend = s:lup_lbeg
    let s:lup_cbeg = col("'<")
    let s:lup_cend = col("'>")

    call Utl_processUrl(url, a:showAttr)
endfu


"-------------------------------------------------------------------------------
" Command `:Gu' - Go Url
" Make a command for Utl_processUrl(). So this is besides
" Utl_goUrl() and Utl_goUrlVis() the third alternative to hand over
" a link to Utl-processing.
" 
" This is like in a web browser the free input of an URL;
" contrasted to the hypertext URL, which is embedded in a (given) document!
"
" Usage:
"   :Gu /path/to/file.txt
"   :Gu other_file_in_directory_where_current_file_is.txt
"   :Gu /path/to/file.txt split
"
fu! Utl_goUrlCmd(uriref, ...)
    if exists('a:1')
	let showAttr = a:1
    else
	let showAttr = 'vie'
    endif

    let s:lup_lbeg = 0	" no buffer position involved

    call Utl_processUrl(a:uriref, showAttr)
endfu

if !exists(":Gu")
    command -nargs=+ Gu call Utl_goUrlCmd(<f-args>)
endif

"---]




"--------------------------------------------------------id=thl_curl------------
" `Utl_extractUrl' - Extracts embedded URLs from 'linestr':
" Extracts URL from given string 'linestr' (if any) at position 'icurs' (first
" character in linestr is 0). When there is no URL or icurs does not hit the
" URL (i.e. 'URL is not under curosr') returns '<undef>'. Note, that there can
" be more than one URL in linestr. Linestr may contain newlines (i.e. supports
" multiline URLs).
"
" Examples:
"   :echo Utl_extractUrl('Two Urls <URL:/foo/bar> in this <URL:/f/b> line', 35)
"   returns `/f/b'
"
"   :echo Utl_extractUrl('Two Urls <URL:/foo/bar> in this <URL:/f/b> line', 28)
"   returns `<undef>'
"
"   :echo Utl_extractUrl('Another embedding here <foo bar>', 27)
"   returns `foo bar'
"	
" Details:
" - The URL embedding (or if embedding at all) depends on the context: HTML
"   has different embedding than a txt file.
" - Non HTML embeddings are of the following form: <URL:...>, <LNK:...> or
"   <...>
" - Returns `<undef>' if `no link under cursor'. (Note that cannot cause
"   problems because `<' is not a valid URI character)
" - Empty Urls are legal, e.g. <URL:>
" - `Under cursor' is like with vim's gf-command: icurs may also point to
"   whitespace before the cursor. (Also pointing to the embedding characters
"   is valid.)
"
fu! Utl_extractUrl(linestr, icurs)

    if &ft == 'html'
	let embedType = 'html'
    else
	let embedType = 'txt'
    endif

    " (pat has to have the Url in first \(...\) because ({) )
    if  embedType == 'html'
	" Html-Pattern: 
	" - can have other attributes in <A>, like
	"   <A TITLE="foo" HREF="#bar">  (before and/or behind HREF)
	" - can have Whitespace embedding the `=' like
	"   <A HREF = "#bar">
	"   Note: Url must be surrounded by `"'. But that should not be mandatory...
	"   Regexp-Guru please help!
	let pat = '<A.\{-}HREF\s*=\s*"\(.\{-}\)".\{-}>'
    else
	" Allow different embeddings: <URL:myUrl>, <myUrl>.
	" Plus <LNK:myUrl> for backward compatibility utl-1.0 and future
	" extension.
	" ( % in pattern means that this group doesn't count as \1 )
	let pat = '<\%(URL:\|LNK:\|\)\([^<]\{-}\)>'

    endif

    let linestr = a:linestr
    let icurs = a:icurs

    " do match() and matchend() ic (i.e. allow url: urL: Url: lnk: lnk: LnK:
    " <a href= <A HREF= ...)
    let saveIgnorecase = &ignorecase |  set ignorecase	    " ([)

    while 1
	" (A so called literal \n here (and elsewhere), see
	" <URL:vimhelp:expr-==#^since a string>.
	" \_s* can't be used because a string is considered a single line.)
	let ibeg = match(linestr, "[ \\t \n]*".pat)
	let s:lup_cbeg = ibeg+1

	if ibeg == -1 || ibeg > icurs
	    let curl = '<undef>'
	    break
	else
	    " matchstart before cursor or same col as cursor,
	    " look if matchend is ok (i.e. after or equal cursor)
	    let iend = matchend(linestr, "[ \\t \n]*".pat) -1
	    let s:lup_cend = iend+1
	    if iend >= icurs
		" extract the URL itself from embedding
		let curl = substitute(linestr, '^.\{-}'.pat.'.*', '\1', '')   " (})
		break
	    else
		" match was before cursor. Check for a second URL in linestr;
		" redo with linestr = `subline' behind the match
		let linestr = strpart(linestr, iend+1, 9999)
		let icurs = icurs-iend-1
		continue
	    endif
	endif
    endwhile

    let &ignorecase = saveIgnorecase	    " (])
    return curl
endfu


"-------------------------------------------------------------------------------
" Switch syntax highlighting for URLs on or off. Depending on the config
" variable g:utl_config_highl
fu! Utl_setHighl()

    if !exists("g:utl_config_highl") || g:utl_config_highl ==? 'on'
	augroup utl_highl
	  au!
	  au BufWinEnter * syn case ignore
	  au BufWinEnter * hi link UtlTag Identifier

	  au BufWinEnter * hi link UtlUrl Underlined
	  au BufWinEnter * syn region UtlUrl matchgroup=UtlTag start="<URL:" end=">" containedin=ALL
	  au BufWinEnter * syn region UtlUrl matchgroup=UtlTag start="<LNK:" end=">" containedin=ALL
	  au BufWinEnter * syn case match
	augroup END

    else 
	augroup utl_highl
	  au!
	augroup END
	augroup! utl_highl
	" Clear for current buffer to make turn-off instantaneously visible.
	" ... but does not seem to work everywhere.
	if hlexists('UtlTag')
	    syntax clear UtlTag
	endif
	if hlexists('UtlUrl')
	    syntax clear UtlTag
	endif

    endif

endfu

call Utl_setHighl()

"-------------------------------------------------------------------------------
" Show URL associated with current buffer.
" Little wrapper around Utl_getCurResource.
" 
fu! Utl_showCurUrl()
    let urlText = Utl_getCurResource()
    if urlText == ''
	let urlText = 'no associated URL (Buffer not invoked via utl see <URL:vimhelp:utl-gs>)'
    else
	let urlText = 'URL=' . urlText
    endif
    echo urlText
endfu

"-------------------------------------------------------------------------------
" Get the absolute URI corresponding to the actual buffer - if any.
" (Does this by looking up Utl's cache map.)
"
" - Returns '' if not mapped (meaning that the current buffer
"   was not loaded by means of utl.
" 
fu! Utl_getCurResource()
    if UtlArr_find( Utl_utilSlash_ExpandFullPath(), 'utl_globalVal')
	return g:utl_globalVal
    endif
    return ''
endfu


"-------------------------------------------------------------------------------
" Process given Url. This is the central function of Utl.
"
" Processing means: retrieve or address or load or switch-to or query or
" whatever the resource given by `url'.
" When succesful, then a local file will (not necessarly) exist, and
" is displayed by vim.  Or is displayed by a helper application (e.g.
" when the Url identifies an image).  Often the local file is cache
" file created ad hoc (e.g. in case of network retrieve).
"
" - The uriref argument can contain line breaks. \s*\n\s* Sequences are
"   collapsed. Other Whitespace is left as is (CR019).
"   See also <URL:http://www.ietf.org/rfc/rfc2396.txt> under
"   chapter E, Recommendations.
" 
" Examples:
"   call Utl_processUrl('file:///path/to/file.txt', 'edit')
"
"   call Utl_processUrl('file:///usr/local/share/vim/', 'vie')
"		" may call Vim's explorer
"
"   call Utl_processUrl('http://www.vim.org', 'edit')
"		" call browser on URL
"
"   call Utl_processUrl('mailto:stb@bf-consulting.de', 'vie')
"		" the local file may be the return receipt in this case
"
fu! Utl_processUrl(uriref, showAttr)

    let urirefpu = a:uriref	" uriref with newline whitespace sequences purged
    " check if newline contained. Collapse \s*\n\s
    if match(a:uriref, "\n") != -1
	let urirefpu = substitute(a:uriref, "\\s*\n\\s*", "", "g")
    endif


    let uri = UriRef_getUri(urirefpu)
    let fragment = UriRef_getFragment(urirefpu)


    "--- Handle Same Document Reference
    " processed as separate case, because:
    " 1. No additional 'retrieval' should happen (see
    "    <URL:http://www.ietf.org/rfc/rfc2396.txt#4.2. Same-document>).
    " 2. UtlUri_abs() does not lead to a valid absolute Url (since the base-path-
    "	 file-component will always be discarded).
    "
    if uri == ''
	call Utl_processFragmentText( fragment )
	return
    endif


    "--- Make absolute URL, if not already.
    let scheme = UtlUri_scheme(uri)
    if scheme != '<undef>'
	let absuri = uri
    else	" `uri' is formally no absolute URI but look for some
		" heuristic, e.g. prepend 'http://' to 'www.vim.org'
	let absuri = Utl_checkHeuristicAbsUrl(uri)
	if absuri != ''
	    let scheme = UtlUri_scheme(absuri)
	endif
    endif
    if scheme == '<undef>'	" uri is a relative URI. get the base URI
	let base = Utl_getCurResource()
	if base == ''
	    " No corresponding resource to curPath known.   (id=nobase)
	    " i.e. curPath was not retrieved through Utl.
	    " Now just make the usual heuristic of `file://localhost/'-Url;
	    " assume, that the curPath is the Resource itsself.
	    "   If then the retrieve with the so generated Url is not possible,
	    " nothing severe happens.
	    "   When, say, curPath is a HTML-File from the web, you could
	    " in principle set the correct Resource manually:
	    " :call UtlArr_set(Utl_utilSlash_ExpandFullPath(),
	    "			'http://www.bf-consulting.de/index.html')
	    let curPath = Utl_utilSlash_ExpandFullPath()
	    if curPath == ''
		let v:errmsg = "Cannot make a base URL from [No File]. Edit a file and try again"
		echohl ErrorMsg | echo v:errmsg | echohl None
		return
	    endif
	    let base = 'file://' . curPath
	endif

	let scheme = UtlUri_scheme(base)

	let absuri = UtlUri_abs(uri,base)
    endif


    "--- Assertion : have absolute URL (absuri, scheme)


    "--- Call the appropriate retriever (see <URL:utl_scm.vim>)
    
    let cbfunc = 'Utl_AddressScheme_' . scheme
    if !exists('*'.cbfunc)
	let v:errmsg = "Sorry, scheme `".scheme.":' not implemented"
	echohl ErrorMsg | echo v:errmsg | echohl None
	return
    endif
    exe 'let localPath = ' cbfunc . "('". absuri . "')"


    "---

    if !strlen(localPath)
	return
    endif


    " Assertion :
    " there now is a buffer corresponding to the requested Resource.
    " Record this fact in the cache map (resource map). This is 
    " for possible subsequent Utl_processUrl() calls with relative
    " Urls.


    call UtlArr_set(localPath, absuri)


    " See if media type is defined for localPath, and if yes, whether a
    " handler is defined for this media type (if not the Setup is called to
    " define one). Everything else handle with the default handler
    " Utl_processLocalPath(), which displays the document in a Vim window.
    " The pseudo handler named 'VIM' is supported: Allows bypassing the media
    " type handling and call default vim handling (Utl_processLocalPath)
    " although there is a media type defined.

    let contentType = Utl_checkMediaType(localPath)

    if contentType != ''
	let slashPos = stridx(contentType, '/')
	let var = 'g:utl_mt_' . strpart(contentType, 0, slashPos) . '_' . strpart(contentType,slashPos+1)

	if ! exists(var)    " Entering setup
	    echohl WarningMsg
	    call input('no handler for media type '.contentType.' defined yet. Entering Setup now. <RETURN>')
	    echohl None
	    call Utl_processUrl('config:#r=mediaTypeHandlers', 'split') " (recursion, setup)
	    return
	else
	    exe 'let varVal =' . var
	    if varVal ==? 'VIM'
		call Utl_processLocalPath(localPath, fragment, a:showAttr)	" ([)
	    else
		exe 'call Utl_mthstringCmd(' . var . ', localPath, fragment)'
	    endif
	    return
	endif
    endif

    call Utl_processLocalPath(localPath, fragment, a:showAttr) " (])

endfu


"id=Utl_checkHeuristicAbsUrl--------------------------------------------------
"
" This function is called for every URL which is not an absolute URL.
" It should check if the URL is meant to be an absolute URL and return
" the absolute URL. E.g. www.host.domain -> http://www.host.domain.
"
" You might want to extend this function for your own special URLs
" and schemes, see #r=heur_example below
"
fu! Utl_checkHeuristicAbsUrl(uri)

    " TODO:
    " Should we also support this?
    " xxx.{org,com,de...} -> http://xxx.{org,com.de}

    "--- www.host.domain -> http://www.host.domain
    if match(a:uri, '^www\.') != -1
	return 'http://' . a:uri

    "--- user@host.domain -> mailto:user@host.domain
    elseif match(a:uri, '@') != -1
	return 'mailto:' . a:uri

    " BT12084 -> BT:12084			    #id=heur_example
    " This is an example of a custom heuristics which I use myself. I have a
    " text file which contains entries like 'BT12084' which refer to that id
    " 12084 in a bug tracking database. See <URL:utl_scm.vim#addressScheme_bt>.
    " BT stands for `Bug Tracker'.
    elseif match(a:uri, '^[PB]T\d\{4,}') != -1
     	return substitute(a:uri, '^\([PB]T\)\(\d\+\)', 'BT:\2', '')

    endif

    return ''
endfu


"id=utl_mthstringcmd ---------------------------------------------------------
"
"   Intended for g:utl_mt_xxx strings defined in utl_rc.vim by the user as
"   specific media type handlers. Special conversion chararcters like %p are
"   substituted and then the string is executed as an ex command. Characters
"   wich can occur in an URL and which have special meaning when executing as
"   ex command are escaped.
"
" - arg `mthstring' is a string that can contain the following conversion
"   specifiers which get substituted. The following specifiers are supported:
"
"	%P - will get replaced by the full path, with backslash separated path
"	     components (typically used on Windows).
"	%p - will get replaced by the full path, forward slashes
"
"	TODO
"	The following are not yet supported:
"	%f - will get replaced by the fragment (may be empty)
"	
fu! Utl_mthstringCmd(mthstring, localPath, fragment)

    let cmd = a:mthstring
    let percentPos = stridx(cmd, '%')
    let percentChar = strpart(cmd, percentPos+1, 1)

    if	   percentChar ==# 'P'
	" (Can there be a % in the substitute?)
	let path = substitute( a:localPath , '/', '\', 'g')
    elseif percentChar ==# 'p'
	let path = a:localPath
    else
	call input("`%".percentChar."' not allowed in handler string `".mthstring."' <RETURN>")
	return
    endif

    "echo "DBG path=`".path"'"

    let cmd = strpart(cmd, 0, percentPos) . path . strpart(cmd, percentPos+2)

    " Prepare string to be executed as a ex command (i.e. escape some
    " characters from special treatment <URL:vimhelp:cmdline-special>).
    let cmd = escape( cmd, g:utl_esccmdspecial)	" id=esccmd

    exe cmd

endfu


"-------------------------------------------------------------------------------
" Display file `localPath' in a Vim window (see
" <URL:vimhelp:utl-internals#LocalPath> " for specification of " `localPath').
"
" Do processing of fragment (e.g. tell vim to display the buffer
" at that position) if any (`fragment' may equal to '<undef>' or '')
"
" This function is the default handler for localPath files which are not
" handled by another handler like Acrobat Reader for pdf files (see
" <URL:#utl_mthstringcmd>
"
" - `localPath' _can_ already be identical to the current buffer (happens
"   for example with vimhelp resources).
" - `localPath' _can_ already be in the buffer list (:ls)
"
" - arg `showAttr' (id=showAttr)
"   influences, when applicable, the way the document is presented (by vim)
"   (resembles XML-XLink's `show' attribut). Possible values are
"	'view' = :view
"	'edit'   = :edit
"	'sview'  = :sview
"	'split'  = :split
"	'vsplit' = :vsplit
"	'read'   = :read
"
" Examples :
"   :call Utl_processLocalPath('t.txt', 'tn=myString', 'split')
"   :call Utl_processLocalPath('hello.c', '', '')
"
fu! Utl_processLocalPath(localPath, fragment, showAttr)

    let v:errmsg = ""
    if a:localPath != Utl_utilSlash_ExpandFullPath()	" avoid to redisplay

	" - Escape spaces in a:localPath with a backslash when on unix (CR033)
	"   in order to support file names with spaces in URLs under unix. Note
	"   that this is not necessary under Windows because this works
	"   automatically there. This support is important in order to ensure
	"   Utl's goal of portable links.
	"   Also escape '$': Will otherwise tried to be	expanded by Vim (CR030)
	if has("win32")
	    let localPath = escape(a:localPath, '$')
	elseif has("unix")
	    let localPath = escape(a:localPath, ' $')
	endif

	" If buffer cannot be <URL:vimhelp:abandon>ned, for given showAttr,
	" silently change the showAttr to a corresponding split-showAttr. Want
	" to avoid annoying E37 message when executing URL on modified buffer (CR024)
	let showAttr = a:showAttr
	if getbufvar(winbufnr(0),"&mod") && ! getbufvar(winbufnr(0),"&awa") && ! getbufvar(winbufnr(0),"&hid")
	    if showAttr == 'edit'
		let showAttr = 'split'
	    elseif showAttr == 'view'
		let showAttr = 'sview'
	    endif
	endif

	" Note: 1 to 1 mapping between a:showAttr and vim command (e.g. showAttr
	" = 'vie' -> exe 'vie'). That may change.

	exe  showAttr . ' ' . localPath

	if a:localPath == Utl_utilSlash_ExpandFullPath()
	    " Set cursor to begin of file if changed buffer   (id=_gg)
	    " When revisiting a file, Vim normally positions to the
	    " last known position <URL:vimhelp:edit#last known>. But the
	    " fragment addressing has to begin at the start of the file (or end,
	    " see <URL:#r=fragwrapscan>).
	    " Note:
	    " - Cursor set only done in the localPath != curPath case (at top):
	    "   So is not for cases like vimhelp: scheme
	    " - Cursor set only when buffer actually has changed: So it is not
	    "   for error case, for example E325 with subsequent Quit.
	    " - See also CR017#scmhandspez.
	    if v:version >= 601
		call cursor(1,1)

	    " Vim6.0 doesn't have the cursor() function.  (CR016)
	    " Workaround with 1gg which does the same but with the side-
	    " effect of setting jumplist, disturbing ctrl-o/i usage
	    else
		normal 1gg 
	    endif

	endif

    endif

    " Process fragment. To be done after the retrieval.
    " (n.b. this is for text. For images etc. no processing (yet).
    " Depends on the sub media type (i.e. &ft in vim) of the document.
    if v:errmsg == ""
	call Utl_processFragmentText( a:fragment )
    endif

endfu

"----------------------------------------------------------id=thl_checkmtype----
" Eventually determines the media type (= mime type) for arg `path', e.g. 
" pic.jpeg -> 'image/jpeg' and returns it. Returns an empty string when media
" type cannot be determined or is uninteresting to be determined. Uninteresting
" means: Only those media types are defined here which are of potential
" interest for being handled by some external helper program (e.g. MS Word for
" application/msword or xnview for application/jpeg).
"
" Typical usage: When this function returns a non empty string Utl checks
" if a handler is defined, and if not Utl's setup utility is called.
"
" - You may add other mediatypes. See
"   <URL:ftp://ftp.iana.org/assignments/media-types/> or
"   <URL:http://www.iana.org/assignments/media-types/> for the registry of
"   media types. On Linux try <URL:/etc/mime.types> In general this makes only
"   sense when you also supply a handler for every media type you define, see
"   <URL:./utl_rc.vim#r=mediaTypeHandlers>.
"
fu! Utl_checkMediaType(path)

    if isdirectory(a:path)
	return "text/directory"
    endif
  
    let ext = fnamemodify(a:path, ":e")

    let mt = ''

    " MS windows oriented
    if ext==?'doc' || ext==?'dot' || ext==?'wrd'
        let mt = 'application/msword'
    elseif ext==?'xls'
        let mt = 'application/excel'
    elseif ext==?'ppt'
        let mt = 'application/powerpoint'
    elseif ext==?'wav'
        let mt = 'audio/wav'

    " universal
    elseif ext==?'dvi'
	let mt = 'application/x-dvi'
    elseif ext==?'pdf'
        let mt = 'application/pdf'
    elseif ext==?'rtf'
        let mt = 'application/rtf'
    elseif ext==?'ai' || ext==?'eps' || ext==?'ps'
	let mt = 'application/postscript'
    elseif ext==?'rtf'
        let mt = 'application/rtf'
    elseif ext==?'zip'
        let mt = 'application/zip'
    elseif ext==?'mp3' || ext==?'mp2' || ext==?'mpga'
	let mt = 'audio/mpeg'
    elseif ext==?'png'
	let mt = 'image/png'
    elseif ext==?'jpeg' || ext==?'jpg' || ext==?'jpe'  || ext==?'jfif' 
	let mt = 'image/jpeg'
    elseif ext==?'tiff' || ext==?'tif'
	let mt = 'image/tiff'
    elseif ext==?'gif' || ext==?'gif'
	let mt = 'image/gif'
    elseif ext==?'mp2' || ext==?'mpe' || ext==?'mpeg' || ext==?'mpg'
	let mt = 'video/mpeg'

    " id=texthtml
    elseif ext==?'html' || ext==?'htm'
     	let mt = 'text/html'

    " unix/linux oriented
    elseif ext==?'fig'
	let mt = 'image/x-fig'

    endif
    return mt 

endfu

"-------------------------------------------------------------------------------
" Process Fragment. E.g. make a cursor motion to the position as
" defined by `fragment'.
"
" - operates on the current buffer
" - the interpretation of `fragment' depends on the ft <URL:#r=fragft>
" - `fragment' can be '<undef>' or '' (noop then)
" - the fragment will be URI-Unescaped before processing (because
"   Vim won't find the text 'A:B' when you give '#tn=A%3aB')
" - starts from the current cursor position, i.e. all fragment operation
"   is done relative to the current cursor position
"
" Usage:
"
"   " motion forward from current position to the first occurence of
"   " the text 'foo bar'
"   call Utl_processFragmentText('tn=foo%20bar')
"
"
" Internal:
" When there will be spans (XML/XPointer lingo) implemented, then
" ``processing'' will not only mean ``Positioning'' but for example
" ``extract'' the denoted fragment.
" But that won't be confined to this function.
" 
fu! Utl_processFragmentText(fragment)

    if a:fragment == '<undef>' || a:fragment == ''
	return
    endif


    let ufrag = UtlUri_unescape(a:fragment)

    if ufrag =~ '^line=[-+]\=[0-9]*$'

	let sign = substitute(ufrag, '^line=\([-+]\)\=\([0-9]*\)$', '\1', '')
	let num =  substitute(ufrag, '^line=\([-+]\)\=\([0-9]*\)$', '\2', '')

	" feature:
	" If the cursor is on the first line of the buffer, then the line
	" offset is interpreted as the absolute line number. So the line=i
	" fragment is smarter (but inconsistent of course). I wanted to keep
	" it simple and avoid something like lineRel(ioff) vs lineAbs(i).

	if line('.') == 1
	    let num = num-1
	endif

	if sign == '' || sign == '+'
	    let cmd = num.'j'
	else
	    let cmd = num.'k'
	endif
	exe 'normal ' . cmd

	return
    endif


    " (the rest is positioning by search)

    if ufrag =~ '^r='	    " fragment is an id reference  (id=fragft)
	" ( \w\@! is normally the same as \> , i.e. match end of word,
	"   but is not the same in help windows, where 'iskeyword' is
	"   set to include non word characters. \w\@! is independent of
	"   settings )
	let val = substitute(ufrag, '^r=\(.*\)$', '\1', '')
	if &ft == 'html'
	    let cmd = '/NAME=\.\=' . val . '\w\@!' . "\r"
	else
	    let cmd = '/id=' . val . '\w\@!' . "\r"
	endif
	" Like #r=move:
	if s:lup_lbeg != 0
	    call cursor(s:lup_lend, s:lup_cend) 
	endif

    elseif ufrag =~ '^tp='  " text previous
	let cmd = substitute(ufrag, '^tp=\(.*\)$', '?\1\r', '')
	" Like #r=move, but move to first character before the URL in a #tp=
	" fragment.
	if s:lup_lbeg != 0
	    call cursor(s:lup_lbeg, s:lup_cbeg) 
	endif

			    " ^tn= or naked. text next
			    "
    elseif ufrag =~ '^tn=' " text next
	let cmd = substitute(ufrag, '^tn=\(.*\)$', '/\1\r', '')
	" id=Move the cursor to the last character of URL to avoid finding the
	" search string in the URL itself. But do not move cursor when it is
	" not a buffer URL (e.g. URL executed by :Gu)
	if s:lup_lbeg != 0
	    call cursor(s:lup_lend, s:lup_cend) 
	endif
    else
	let cmd = '/' . ufrag . "\r"
	if s:lup_lbeg != 0
	    call cursor(s:lup_lend, s:lup_cend) 
	endif
    endif

    " Do text search (in a fuzzy way)			(id=fuzzy)
    " --------------
    " The search is a bit like <URL:vimhelp:tag-search>es, i.e.
    " nomagic...
    "
    " But we have the difference that the search ist relative to
    " the current position, i.e. line('.') (e.g. is != 1 for
    " vimhelp-scheme)
    "
    " Search with 'wrapscan' set. For two reasons:  (id=fragwrapscan)
    " 1. #tp searches also start from line 1, see <URL:#r=_gg>, as that
    "    function does like to deal with fragments (redesign needed?)
    " 2. We have the same problem as vi, see <URL:vimhelp:tag-search#does use>
    "
    " Possible enhancement:
    " - do it more fuzzy: search Whitespace like \s\+ . Can we treat
    "	\n also as Whitespace?  I think, its the best when we
    "	could specify a text semantically, i.e. find a sequence
    "	of words as you have them in mind!
    " - should use \M instead of set nomagic (see <URL:vimhelp:\M> )

    let saveMagic = &magic  |  set nomagic
    let saveIgnorecase = &ignorecase |  set ignorecase
    let saveSmartcase = &smartcase |  set nosmartcase
    let saveWrapscan = &wrapscan |  set wrapscan

    let v:errmsg = ""
    silent! exe "normal " . cmd
    if v:errmsg != ""
	let v:errmsg = "fragment address #" . a:fragment . " not found in target"
	echohl ErrorMsg | echo v:errmsg | echohl None
    endif

    let &magic = saveMagic
    let &ignorecase = saveIgnorecase
    let &smartcase = saveSmartcase
    let &wrapscan = saveWrapscan



endfu

"-------------------------------------------------------------------------------
" Display the localPath -> Resource-Mapping in a :new-Buffer
" (no file corresponds to this Buffer)
"
fu! Utl_viewResourceMap()

    new	    " (without a name, so the buffer disappears from buffer list
	    "  although a name like '-- ResourceMap --' would be nice. Didn't
	    "  want to have autocommand (to :bdel) in this Utl version )
    "	(keep header consistent to <URL:utl_arr.vim#VALCOL>
    insert
" LocalPath                            Resource
" ------------------------------------------------------------------------------
.
    call UtlArr_dump()
    let &modified=0	" (because no file corresponds)
endfu

"--- [

"-------------------------------------------------------------------------------
" Wrapper for expand("%:p"), but always forward slashed
"
" All pathnames in utl should be fwd-slashed (like URIs).
" Remark : Perhaps this should be generalized to an URI to filename mapping
" like Perl's URI/URI::file module, see
" <URL:http://www.cpan.org/modules/by-category/15_World_Wide_Web_HTML_HTTP_CGI/URI/URI-1.11.tar.gz#URI::file - URI that map to local file names>
"
fu! Utl_utilSlash_ExpandFullPath()
    return substitute( expand("%:p") , '\', '/', 'g')
endfu

"-------------------------------------------------------------------------------
" Wrapper for tempname, but always forward slashed
"
fu! Utl_utilSlash_Tempname()
    return substitute( tempname() , '\', '/', 'g')
endfu

"--- ]

" Define the :Utl command just because its a good convention to
" have a command name corresponding to the plugin name
if !exists(":Utl")
    command Utl :help utl
endif
" Likewise define a dummy :call Utl() function
fu! Utl()
    :help utl
endfu

let &cpo = s:save_cpo
