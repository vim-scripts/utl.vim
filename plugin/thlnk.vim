" ------------------------------------------------------------------------------
" File:		thlnk.vim - Enabling URL based Hyperlinking for plain text
" Author:	Stefan Bittner <stb@bf-consulting.de>
" Maintainer:	Stefan Bittner <stb@bf-consulting.de>
" Licence:	This program is free software; you can redistribute it and/or
"		modify it under the terms of the GNU General Public License.
"		See http://www.gnu.org/copyleft/gpl.txt
" Last Change:	13-Jun-2002/STB
" Version:	thlnk-1.2
"
" Docs:		for online help type:	:help thlnk
"		thlnk.vim homepage:	http://www.bf-consulting.de/thlnk/vim
"
" Files:	The Thlnk plugin consists of the following files:
"		plugin/{thlnk.vim,thlnkscm.vim,thlnkarr.vim,thlnkuri.vim}
"		doc/{thlnkusr.txt,thlnkref.txt}
"
" History:
"     See section `CHANGES' in the accompanying thlnk_README.txt for details.
"     1.2  : 14.06.02 released. 2 bug fixes, better error messages, largely
"	     enhanced documentation
"     1.1  : 07.05.02 released as a plugin for vim6 with heavily revised
"	     documentation and homepage
"     1.0  : 26.04.01 first release for vim5
" ------------------------------------------------------------------------------

if exists("loaded_thlnk")
    finish
endif
let loaded_thlnk = 1
let s:save_cpo = &cpo
set cpo&vim

" (This is to allow installation of thlnk.vim with just :runtime plugin/thlnk.vim
"  without leaving vim after having thrown all files into a plugin directory :)
runtime! plugin/thlnkuri.vim
runtime! plugin/thlnkarr.vim
runtime! plugin/thlnkscm.vim


"--- Mappings (id=mappings)
"
" ... for executing the URL under the cursor
if ! hasmapto(":call Thlnk_goUrl('view')<CR>","n")
nmap <unique> <Leader>gv :call Thlnk_goUrl('view')<CR>
endif
if ! hasmapto(":call Thlnk_goUrl('edit')<CR>","n")
nmap <unique> <Leader>ge :call Thlnk_goUrl('edit')<CR>
" make a default hot key: gu = Go Url
nmap <unique> <Leader>gu :call Thlnk_goUrl('edit')<CR>
endif
if ! hasmapto(":call Thlnk_goUrl('sview')<CR>","n")
nmap <unique> <Leader>gV :call Thlnk_goUrl('sview')<CR>
endif
if ! hasmapto(":call Thlnk_goUrl('split')<CR>","n")
nmap <unique> <Leader>gE :call Thlnk_goUrl('split')<CR>
endif
if ! hasmapto(":call Thlnk_goUrl('read')<CR>","n")
nmap <unique> <Leader>gr :call Thlnk_goUrl('read')<CR>
endif
"
" ... for executing the visual marked URL
if ! hasmapto(":call Thlnk_goUrlVis('view')<CR>","v")
vmap <unique> <Leader>gv :call Thlnk_goUrlVis('view')<CR>
endif
if ! hasmapto(":call Thlnk_goUrlVis('edit')<CR>","v")
vmap <unique> <Leader>ge :call Thlnk_goUrlVis('edit')<CR>
" make a default hot key: gu = Go Url (Visual Mode)
vmap <unique> <Leader>gu :call Thlnk_goUrlVis('edit')<CR>
endif
if ! hasmapto(":call Thlnk_goUrlVis('sview')<CR>","v")
vmap <unique> <Leader>gV :call Thlnk_goUrlVis('sview')<CR>
endif
if ! hasmapto(":call Thlnk_goUrlVis('split')<CR>","v")
vmap <unique> <Leader>gE :call Thlnk_goUrlVis('split')<CR>
endif
if ! hasmapto(":call Thlnk_goUrlVis('read')<CR>","v")
vmap <unique> <Leader>gr :call Thlnk_goUrlVis('read')<CR>
endif
"
" ... for displaying the cache
if ! hasmapto(":call Thlnk_goUrlVis('read')<CR>","n")
nmap <unique> <Leader>gc :call Thlnk_viewResourceMap()<CR>
endif
"
" ... for showing the associated URL (if any) for the active buffer
if ! hasmapto(":echo 'URL=' Thlnk_getCurResource()<CR>","n")
nmap <unique> <Leader>gs :echo 'URL=' Thlnk_getCurResource()<CR>
endif
"

" Debugging:
" If you'd like to try the built-in debugging commands...
" (idea taken from Charles E. Campbell's script, see
" <URL:http://www.erols.com/astronaut/vim/vimscript/netrw.vim#tn=Debugging>)
""   :g/DBG/s/^"//      to activate    debugging
""   :g/DBG/s/^/"/      to de-activate debugging
"

let thlnk_vim = expand("<sfile>")

"--- Frontends [

"----------------------------------------------------------id=thl_gourl---------
" Process URL (or read: URI, if you like---Thlnk isn't exact there) under
" cursor: searches for something like < URL:myUrl> or <A HREF="myUrl"> (depending
" on the context), extracts myUrl, an processes that Url (e.g. retrieves the
" document and displays it).
"
" - Arg showAttr -> see <URL:#showAttr>
"
fu! Thlnk_goUrl(showAttr)
"    echo 'DBG ---beg------Thlnk_goUrl'

    let url = Thlnk_curl()
"    echo "DBG url under cursor=`". url . "'"

    if url=='<undef>'
	let v:errmsg = "No Link under Cursor"
	echohl ErrorMsg | echo v:errmsg | echohl None
"	echo 'DBG ------end---Thlnk_goUrl (no link)'
	return
    else
	call Thlnk_processUrl(url, a:showAttr)
    endif
"    echo 'DBG ------end---Thlnk_goUrl'
endfu


"--------------------------------------------------------id=thl_curl------------
" `Thlnk_curl' = Returns Url under Cursor (like <cword> etc. in vim)
"
" Example:	   Cursor is about here --+
"					  V
"   Two Urls <URL:/foo/bar> in this <URL:/f/b> line'
"   echo Thlnk_curl()	" gives `/f/b'
"	
" - How an URL has to be embedded (or if it has to be embedded depends
"   on the context
" - Returns `<undef>' if `no link under cursor' (ok like this because `<'
"   is not a valid URI character)
" - Empty Urls are legal, e.g. <URL:>
" - `Under cursor' is like with vim's gf-command: on Whitespace before
"   or on it
" - Multiline-Urls not supported :-(
"
fu! Thlnk_curl()
"    echo 'DBG ---beg------Thlnk_curl'

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
	"upd Url must be surrounded by `"'. But that should not be mandatory...
	"   Regexp-Guru please help!
	let pat = '<A.\{-}HREF\s*=\s*"\(.\{-}\)".\{-}>'
    else
	" Allow not only <URL: but also <LNK: , to be backward compatible to
	" thlnk.vim-1.0 and also for future extensions.
	" ( % in pattern means that this group doesn't count as \1 below -
	"   Thanks to vim6 :-)
	let pat = '<\%(URL\|LNK\):\(.\{-}\)>'
    endif
"    echo "DBG pat=`". pat . "'"

    let line = getline('.')
    let icurs = col('.') - 1	" `Index-Cursor'

    " do match() and matchend() ic (i.e. allow <url: <urL: <Url: <lnk: <lnk:
    " <Lnk: <a href= <A HREF= ...)
    let saveIgnorecase = &ignorecase |  set ignorecase	    " ([)

    while 1
"	echo "DBG line=`". line . "'"
"	echo "DBG icurs=`". icurs . "'"

	let ibeg = match(line, '\s*'.pat)
"	echo 'DBG ibeg=`'.ibeg."'"

	if ibeg == -1 || ibeg > icurs
"	    echo 'DBG no match at all in line or match behind (i.e. not under cursor)'
	    let curl = '<undef>'
	    break
	else
	    " match below cursor or same col as cursor,
	    " look if matchend is ok
	    let iend = matchend(line, '\s*'.pat) -1
	    if iend >= icurs
"		echo 'DBG match found'
		" extract the URL itself from embedding
		let curl = substitute(line, '^.\{-}'.pat.'.*', '\1', '')   " (})
		break
	    else
		" match was before cursor.
		" Redo with line = `subline' behind the match
"		echo 'DBG match before cursor, cut'
		let line = strpart(line, iend+1, 9999)
		let icurs = icurs-iend-1
		continue
	    endif
	endif
    endwhile

    let &ignorecase = saveIgnorecase	    " (])

"    echo 'DBG ------end---Thlnk_curl'
    return curl
endfu

"-------------------------------------------------------------id=thl_gourlvis---
" Alternative to Thlnk_goUrl(). Call Thlnk_processUrl on a visual area.
" Useful, when Url not recognized by Thlnk_goUrl() because of an
" unknown embedding
"
" Example: On a line like:
"   `Visite our homepage at http://www.foo.de and win a price'
"   you visual this         -----------------   and `:call Thlnk_goUrlVis('view')
"   (hey, it works, host foo.de is known and even yields the correct result :-)
"
" - Arg showAttr -> <URL:#showAttr>
"
fu! Thlnk_goUrlVis(showAttr)
    " highlighted text into variable `url' ; seems to complicated, but
    " just let url=@* doesn't work on windows GUI without guioptions+=a
    " Using @* register isn't perfectly nice.
    normal `<"*y`>
    let url = @*
    normal `>"*yl
    let url = url . @*
    call Thlnk_processUrl(url, a:showAttr)
endfu

"---]

"-------------------------------------------------------------------------------
" Get the absolute URI corresponding to the actual buffer - if any.
" (Does this by looking up Thlnk's cache map.)
"
" - Returns '' if not mapped (meaning that the current buffer
"   was not loaded by means of thlnk, e.g. -noUrl-)
" 
fu! Thlnk_getCurResource()
    if ThlnkArr_find( Thlnk_utilSlash_ExpandFullPath(), 'thlnk_globalVal')
	return g:thlnk_globalVal
    endif
    return ''
endfu

"-------------------------------------------------------------------------------
" Process given Url. This is the central function of thlnk.
"
" Processing means: retrieve or address or load or switch-to or query or
" whatever the resource given by `url'.
" When succesful, then a local file will (not necessarly) exist, and
" is displayed by vim.  Or is displayed by a helper application (e.g.
" when the Url identifies an image).  Often the local file is cache
" file created ad hoc (e.g. in case of network retrieve).
" 
" 
" Examples:
"   call Thlnk_processUrl('file:///path/to/file.txt')
"
"   call Thlnk_processUrl('file:///usr/local/share/vim/')
"		" may call vim's explorer
"
"   call Thlnk_processUrl('http://www.moolenaar.net#tn=Miller')
		" classical retrieve and caching
"
"   call Thlnk_processUrl('mailto:stb@bf-consulting.de')
"		" the local file may be the return receipt in this case
"
"
" - Arg showAttr is optional. Defaults to `vie'. See <URL:#showAttr>
"
fu! Thlnk_processUrl(uriref, ...)
"    echo 'DBG ---beg------Thlnk_processUrl'

    if exists('a:1')
	let showAttr = a:1
    else
	let showAttr = 'vie'
    endif
"    echo 'DBG showAttr=`'. showAttr ."'"


    let uri = UriRef_getUri(a:uriref)
    let fragment = UriRef_getFragment(a:uriref)

    " Same document reference
    " processed as separate case, because:
    " 1. No additional 'retrieval' should happen (see
    "    <URL:http://www.ietf.org/rfc/rfc2396.txt#tn=4.2. Same-document>).
    " 2. ThlnkUri_abs() does not lead to a valid absolute Url (since the base-path-
    "	 file-component will always be discarded).
    "
    if uri == ''
	call Thlnk_processFragmentText( fragment )
"	echo 'DBG ------end---Thlnk_processUrl (uri emtpy)'
	return
    endif

    let scheme = ThlnkUri_scheme(uri)
    if scheme != '<undef>'
"	echo "DBG scheme defined, so it's an absolute URI"
	let absuri = uri

    else
"	echo 'DBG is a RELURI. get Base-URI'

	let base = Thlnk_getCurResource()
	if base == ''
"	    echo 'DBG no base'
	    " No corresponding resource to curPath known.   (id=nobase)
	    " i.e. curPath was not retrieved through Thlnk.
	    " Now just make the usual heuristic of `file://localhost/'-Url;
	    " assume, that the curPath is the Resource itsself.
	    "   If then the retrieve with the so generated Url is not possible,
	    " nothing severe happens.
	    "   When, say, curPath is a HTML-File from the web, you could
	    " in principle set the correct Resource manually:
	    " :call ThlnkArr_set(Thlnk_utilSlash_ExpandFullPath(),
	    "			'http://www.bf-consulting.de/index.html')
	    let base = 'file://' . Thlnk_utilSlash_ExpandFullPath()
	endif

	let scheme = ThlnkUri_scheme(base)

	let absuri = ThlnkUri_abs(uri,base)
"	echo 'DBG base=`'. base ."'"
    endif
"    echo 'DBG scheme=`'. scheme ."'"
"    echo 'DBG absuri=`'. absuri ."'"


    " call the appropriate retriever (see <URL:thlnkscm.vim>)
    let cbfunc = 'Thlnk_AddressScheme_' . scheme
    if !exists('*'.cbfunc)
	let v:errmsg = "Sorry, scheme `".scheme.":' not implemented"
	echohl ErrorMsg | echo v:errmsg | echohl None
	return
    endif
    exe 'let localPath = ' cbfunc . "('". absuri . "')"


    if !strlen(localPath)
"	echo 'DBG ------end---Thlnk_processUrl (no local path)'
	return
    endif


    " assertion:
    " there now is a buffer corresponding to the requested Resource.
    " Record this fact in the cache map (resource map). This is 
    " for possible subsequent Thlnk_processUrl() calls with relative
    " Urls.

    " heuristic support for scheme http.
    " If path component without an extension, then append a  '/' to it
    " (assuming that the path denotes a directory then).
    " Examples:
    " 'http://www.bf-consulting.de' -> append '/' to ''
    " 'http://www.ics.uci.edu/pub/ietf/uri' -> append '/' to '/pub/ietf/uri'
    " (It dosn't matter if there is an 'index.html' file in that directory.)
    " It's a conceptually ugly, but pragmatic solution. The problem is
    " related to <URL:thlnkscm.vim#tempsuff>; the info should be taken
    " from the HTTP session.
    if scheme == 'http'
	let path = ThlnkUri_path(absuri)
	if fnamemodify(path, ":e") == ''
"	    echo 'DBG empty path component. set / before ThlnkArr_set'
	    let authority = ThlnkUri_authority(absuri)
	    let query = ThlnkUri_query(absuri)
	    let absuri = ThlnkUri_build(scheme, authority, path.'/', query, '<undef>')
	endif
    endif


    call ThlnkArr_set(localPath, absuri)


    call Thlnk_processLocalPath(localPath, fragment, showAttr)


"    echo 'DBG ------end---Thlnk_processUrl'
endfu


"-------------------------------------------------------------------------------
" Process file `localPath' (see <URL:vim_h:thlnk-internals#tn=LocalPath>
" for specification of `localPath')
" E.g. display `localPath' in a vim window,  or shell escape to ask an
" external helper application to process the file named `localPath'.
" Also do processing of fragment (e.g. tell vim to display the buffer
" at that position) if any (`fragment' may equal to '<undef>' or '')
"
" This function is bit like double clicking on file in MS-Windows.
" 
" - `localPath' _can_ already be identical to the current buffer (happens
"   for example with vim_h resources).
" - `localPath' _can_ already be in the buffer list (:ls)
"
" - arg `showAttr' (id=showAttr)
"   influences, when applicable, the way the document is presented (by vim)
"   (resembles XML-XLink's `show' attribut). Possible values are
"	'view' = :view
"	'edit'   = :edit
"	'sview'  = :sview
"	'split'  = :split
"	'read'   = :read
"
" Examples:
"   :call Thlnk_processLocalPath('t.txt', 'tn=myString', 'split')
"   :call Thlnk_processLocalPath('pic.jpg', '', '')
"
fu! Thlnk_processLocalPath(localPath, fragment, showAttr)
"    echo 'DBG ---beg------Thlnk_processLocalPath'

    let contentType = Thlnk_GuessMediaType(a:localPath)
"    echo 'DBG: contentType=`' . contentType . "'"


    if contentType =~ '^image'
	let subType = fnamemodify(contentType, ":t") " (software reuse here :-)
	if has('unix') && subType == 'fig'
	    exe '!xfig ' . a:localPath
	    if v:shell_error
		let msg = 'Shell Error. External helper !xfig failed'
	    else
		let processed = 1
	    endif
	elseif has('unix')
	    " feed everything but xfig files to to xv. If xv doesn't	(id=_xv)
	    " know the format, it displays it as text
	    exe '!xv ' . a:localPath
	    if v:shell_error
		let msg = 'Shell Error. External helper !xv failed'
	    else
		let processed = 1
	    endif
	"upd elseif windows ... what here?
	else
	    let msg='No external helper defined'
	endif

	if exists('msg')
	    let v:errmsg = "Treating ".contentType." as text/plain (Reason: ".msg.')'
	    echohl ErrorMsg | echo v:errmsg | echohl None
	    let contentType = 'text/plain'
	endif

    endif   " (no elseif here because of <URL:#tp=let%20contentType>)
    if !exists('processed') && contentType =~ '^text'

	" Show File in (you guessed it) a vim window.
	let doFrag=1

	let curPath = Thlnk_utilSlash_ExpandFullPath() 
	if a:localPath != curPath		" avoid to redisplay

	    " 1 to 1 mapping between a:showAttr and vim command
	    " (e.g. showAttr = 'vie' -> exe 'vie'). That may change.
"	    echo 'DBG: cmd=`' . a:showAttr . "',  a:localPath=`" . a:localPath . "'"
"	    echo 'DBG'
	    exe  a:showAttr . ' ' . a:localPath
	    if a:localPath == curPath	" :edit not successful (can happen)
		let doFrag=0
	    else
		" Set cursor to beginning of file. When revisiting   id=_gg
		" a file, Vim normally positions to the last known position
		" <URL:vim_h:edit#tn=last known>. But the fragment addressing
		" has to begin at the start of the file (or end, see
		" <URL:#fragwrapscan>). N.B. this is only here in the
		" a:localPath != curPath case (e.g. not for cases like vim_h:)
		" <URL:develop:fixed#scmhandspez>
		" Cursor() better than gg command because no jumplist entry.
		call cursor(1,1)
	    endif

	endif

	" process fragment. To be done after the retrieval.
	" (n.b. this is for text. For images etc. no processing (yet).
	" Depends on the sub media type (i.e. &ft in vim) of the document.
"	echo 'DBG: a:fragment=`' . a:fragment . "'"
	if doFrag
	    call Thlnk_processFragmentText( a:fragment )
	endif

    elseif !exists('processed')
	echo 'content type '.contentType." not supported. Process file ".a:localPath." manually!"
    endif

"    echo 'DBG ------end---Thlnk_processLocalPath'
endfu

"-------------------------------------------------------------------------------
" Tries to determine the content type for `path', e.g. 'image/jpeg', and
" returns it. Caveats:
" - for text (i.e. media type 'text') always 'text/plain' is returned.
"   That is because for text Vim should be the MC. The subtype plain doesn't
"   matter, is just for the clean interface. The subtype is, so to speak,
"   superseeded by Vim's <URL:vim_h:ft>.
" - is rudimentary: only images handled, the rest yields text/plain.
"   You may add x-application, audio ...
" 
" Inspired from Gisle Aas' Perl modul LWP::MediaTypes, function
" guess_media_type, try
" <URL:file:?perldoc+LWP::MediaTypes%20%3e#tn=guess_media_type>
" 
" Internal:
" - Only looks at the (``meta data'') extension of the path (name).
"   Could be extended for looking at the content. Even in this case `path'
"   not necessarly needed to exist (well, I mean, the function then would
"   test for existence first).
" 
fu! Thlnk_GuessMediaType(path)

    let subtype = ''
    let ext = fnamemodify(a:path, ":e")
    if ext==?'png'
	let subtype = 'png'
    elseif ext==?'jpeg' || ext==?'jpg' || ext==?'jpe'  || ext==?'jfif' 
	let subtype = 'jpeg'
    elseif ext==?'tiff' || ext==?'tif'
	let subtype = 'tiff'
    elseif ext==?'gif' || ext==?'gif'
	let subtype = 'gif'
    elseif ext==?'fig'
	let subtype = 'x-fig'	" non standard
    endif

    if subtype != ''
	return 'image/' . subtype
    else
	return 'text/plain'
    endif
endfu

"-------------------------------------------------------------------------------
" Process Fragment. E.g. make a cursor motion to the position as
" defined by `fragment'.
"
" - operates on the current buffer
" - the interpretation of `fragment' depends on the ft <URL:#fragft>
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
"   call Thlnk_processFragmentText('tn=foo%20bar')
"
"
" Internal:
" When there will be spans (XML/XPointer lingo) implemented, then
" ``processing'' will not only mean ``Positioning'' but for example
" ``extract'' the denoted fragment.
" See <URL:vim_h:thlnk-possfutdev#tn=^Spans>
" But that won't be confined to this function.
" 
fu! Thlnk_processFragmentText(fragment)
"    echo 'DBG: Thlnk_processFragmentText: fragment=`' . a:fragment . "'"

    if a:fragment == '<undef>' || a:fragment == ''
	return
    endif


    let ufrag = ThlnkUri_unescape(a:fragment)
"    echo 'DBG: Thlnk_processFragmentText: fragment unescaped=`' . ufrag . "'"


    if ufrag =~ '^line=[-+]\=[0-9]*$'

	let sign = substitute(ufrag, '^line=\([-+]\)\=\([0-9]*\)$', '\1', '')
	let num =  substitute(ufrag, '^line=\([-+]\)\=\([0-9]*\)$', '\2', '')
"	echo 'DBG sign=`'. sign ."'"
"	echo 'DBG num=`'. num ."'"

	" feature:
	" Wenn the cursor is on the first line of the buffer, then
	" the line offset is interpreted as the absolute line number.
	" So the line=i fragment is smarter (but inconsistent of course).
	" I wanted to KISS and avoid something like lineRel(ioff) vs lineAbs(i).
	if line('.') == 1
	    let num = num-1
	endif

	"upd sollte j und k meckern nicht

	if sign == '' || sign == '+'
	    let cmd = num.'j'
	else
	    let cmd = num.'k'
	endif
"	echo 'DBG cmd=`'. cmd ."'"
	exe 'normal ' . cmd

	return
    endif


    " (the rest is positioning by search)

    if ufrag =~ '^tn=.*$'
	let cmd = substitute(ufrag, '^tn=\(.*\)$', '/\1\r', '')

    elseif ufrag =~ '^tp=.*$'
	let cmd = substitute(ufrag, '^tp=\(.*\)$', '?\1\r', '')

    else	" fragment is an id reference	    (id=fragft)
	" ( \w\@! is normally the same as \> , i.e. match end of word,
	"   but is not the same in help windows, where 'iskeyword' is
	"   set to include non word characters. \w\@! is independent of
	"   settings )
	if &ft == 'html'
	    let cmd = '/NAME=\.\=' . ufrag . '\w\@!' . "\r"
	else
	    let cmd = '/ID=' . ufrag . '\w\@!' . "\r"
	endif
    endif
"    echo 'DBG cmd=`'.cmd."'"


    " Do text search (in a fuzzy way)			(id=fuzzy)
    " --------------
    " The search is a bit like <URL:vim_h:tag-search>es, i.e.
    " nomagic...
    "
    " But we have the difference that the search ist relative to
    " the current position, i.e. line('.') (e.g. is != 1 for
    " vim_h-scheme)
    "
    " Search with 'wrapscan' set. For two reasons:  (id=fragwrapscan)
    " 1. #tp searches also start from line 1, see <URL:#_gg>, as that
    "    function does like to deal with fragments (redesign needed?)
    " 2. We have the same problem as vi, see <URL:vim_h:tag-search#tn=does use>
    "
    "upd:
    " - do it more fuzzy: search Whitespace like \s\+ . Can we treat
    "	\n also as Whitespace?  I think, its the best when we
    "	could specify a text semantically, i.e. find a sequence
    "	of words as you have them in mind!
    " - should use \M instead of set nomagic (see <URL:vim_h:\M> )


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
fu! Thlnk_viewResourceMap()

    new	    " (without a name, so the buffer disappears from buffer list
	    "  although a name like '-- ResourceMap --' would be nice. Didn't
	    "  want to have autocommand (to :bdel) in this Thlnk version )
    "	(keep header consistent to <URL:thlnkarr.vim#tn=VALCOL>
    insert
" LocalPath                            Resource
" ------------------------------------------------------------------------------
.
    call ThlnkArr_dump()
    let &modified=0	" (because no file corresponds)
endfu

"--- [

"-------------------------------------------------------------------------------
" Wrapper for expand("%:p"), but always forward slashed
"
" All pathnames in thlnk should be fwd-slashed (like URIs).
" Remark : Perhaps this should be generalized to an URI to filename mapping
" like Perl's URI/URI::file module, see
" <URL:http://www.cpan.org/modules/by-category/15_World_Wide_Web_HTML_HTTP_CGI/URI/URI-1.11.tar.gz#tn=URI::file - URI that map to local file names>
"
fu! Thlnk_utilSlash_ExpandFullPath()
    return substitute( expand("%:p") , '\', '/', 'g')
endfu

"-------------------------------------------------------------------------------
" Wrapper for tempname, but always forward slashed
"
fu! Thlnk_utilSlash_Tempname()
    return substitute( tempname() , '\', '/', 'g')
endfu

"--- ]


"---------
" Command `:Gu' - Go Url
" make a command for Thlnk_processUrl(). So this is besides
" Thlnk_goUrl() and Thlnk_goUrlVis() the third alternative to hand over
" a link to Thlnk-processing.
" 
" This is like in a web browser the free input of an URL;
" contrasted to the hypertext URL, which is embedded in a (given) document!
"
" Usage:
"   :Gu /path/to/file.txt
"   :Gu other_file_in_directory_where_current_file_is.txt
"

if !exists(":Gu")
    command -nargs=+ Gu call Thlnk_processUrl(<f-args>)
endif

" Define the :Thlnk command just because its a good convention to
" have a command name corresponding to the plugin name
if !exists(":Thlnk")
    command Thlnk :help thlnk
endif
" Likewise define a dummy :call Thlnk() function
fu! Thlnk()
    :help thlnk
endfu

let &cpo = s:save_cpo
