" ------------------------------------------------------------------------------
" File:		plugin/utl.vim - Universal Text Linking - 
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
" Version:	3.0a ALPHA
"
" Docs:		for online help type:	:help utl-plugin
"
" Files:	The Utl plugin consists of the following files:
"		plugin/{utl.vim,utl_scm.vim,utl_uri.vim,utl_rc.vim}
"		doc/utl_usr.txt
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
" 3.0a  ALPHA 2008-07-31
"		New :  Generic media type handler, Mail protocol, Copy Link/
"		Filename support, Foot-References [], Transparent editing of
"		share files, Tracing, Enhanced scheme handler interface,  
"		Changed : User Interface with command :Utl, variable naming.
"		Bug fixes.
" ------------------------------------------------------------------------------

if exists("loaded_utl") || &cp
    finish
endif
let loaded_utl = "3.0a"
if v:version < 700
    echohl ErrorMsg
    echo "Error: You need Vim version 7.0 or later for  utl.vim  version ".g:loaded_utl
    echohl None
finish
endif
let s:save_cpo = &cpo
set cpo&vim
let g:utl__file = expand("<sfile>")

"--- Utl User Interface [

"   (:Utl not as "command! to not override a possible user command of this name.
"     Fails with an error in this case.)
command -complete=custom,s:completeArgs -range -nargs=* Utl call Utl(<f-args>)

"-------------------------------------------------------------------------------
" Intended as command line completion function called back by command :Utl.
" See vimhelp:command-completion-custom.
" Based on the command line provided by user input so far it returns a \n
" separated line of items, which Vim then uses for presenting completion
" suggestions to the user.
" Also works if abbreviations ( see #r=cmd_abbreviations ) appear in cmdLine 
fu! s:completeArgs(dummy_argLead, cmdLine, dummy_cursorPos)

    " Split cmdLine to figure out how many arguments have been provided by user
    " so far. If Using argument keepempty=1 for split will provide empty last
    " arg in case of a new arg is about to begin or an non empty last argument
    " in case of an incomplete last argument. So can just remove the last arg.
    let utlArgs=split(a:cmdLine, '\s\+', 1)
    call remove(utlArgs, -1)

    " 1st arg to complete
    if len(utlArgs)==1
	return "openLink\ncopyFileName\ncopyLink\nhelp"
    endif

    let utlArgs[1] = s:abbr2longArg(utlArgs[1])

    " 2nd arg to complete
    if len(utlArgs)==2
	if utlArgs[1]=='openLink' || utlArgs[1]=='copyFileName' || utlArgs[1]=='copyLink'
	    if len(utlArgs)==2
		return "underCursor\nvisual\ncurrentFile\n_your_URL_here"   
	    endif
	elseif utlArgs[1]=='help'
	    if len(utlArgs)==2
		return "manual\ncommands" 
	    endif
	endif
	" config
	return ''
    endif

    " 3rd argument to complete
    if len(utlArgs)==3
	if utlArgs[1]=='openLink'
	    return "edit\nsplit\nvsplit\ntabedit\nview\nread"
	elseif utlArgs[1]=='copyFileName'
	    return "native\nslash\nbackSlash"
	endif
	return ''
    endif

    return ''

endfun

							" [id=cmd_reference]
"-------------------------------------------------------------------------------
" Table of  :Utl  commands/arguments. The [xxx] are default values and can
" be omitted. ( The table is implemented at #r=Utl )
"
"    arg# 1		2		3
"
"    :Utl [openLink]    [underCursor]	[edit]
"    :Utl	        visual		split
"    :Utl	        currentFile	vsplit
"    :Utl	        <my_url>	tabedit
"    :Utl				view
"    :Utl				read	
"
"    :Utl copyLink	[underCursor]
"    :Utl               visual
"    :Utl               currentFile
"    :Utl               <my_url>
"
"    :Utl copyFileName	[underCursor]	[native]
"    :Utl	        currentFile	backSlash
"    :Utl		Visual		slash
"    :Utl		<my_url>
"
"    :Utl help		[manual]
"    :Utl		commands

							" [id=cmd_abbreviations]
"-------------------------------------------------------------------------------
" Supported abbreviations of arguments to :Utl command.
" Abbreviation conventions are:
" - More than one abbreviation per argument is possible
" - All uppercase letter of a camel word as lower letters (copyFileName -> cfn)
" - Fewer and fewer uppercase letters as long as still unique
"   (cfn -> cf. But not c since else clash with copyLink)
" - The shortest (camel sub-)word beginning until unique
"   (view and vsplit -> vi and vs resp.)
"
" (More keys (=abbreviations) can be added to the dictionaries without further
" change as long as the values are valid long arguments.)
"
let s:d1= { 'o': 'openLink', 'ol': 'openLink', 'cl': 'copyLink', 'cf': 'copyFileName', 'cfn': 'copyFileName', 'h': 'help' }
let s:d21={ 'u': 'underCursor', 'uc': 'underCursor', 'v': 'visual', 'c': 'currentFile', 'cf': 'currentFile' }
let s:d22={ 'm': 'manual', 'c': 'commands' }
let s:d31={ 'e': 'edit', 's': 'split', 'vs': 'vsplit', 't': 'tabedit', 'te': 'tabedit', 'vi': 'view',  'r': 'read' }
let s:d32={ 'n': 'native', 'b': 'backSlash', 'bs': 'backSlash', 's': 'slash' }
"-------------------------------------------------------------------------------
" Convert possible :Utl arg abbreviation for last arg into long arg. The args
" before are the :Utl args provided so far in long form.
"
" Args: Utl command arguments according #r=cmd_reference, where the last
"	can be abbreviated.
" Returns: Last arg converted into long arg
"
" Collaboration: 
"
" Example: s:abbr2longArg('copyFileName', 'underCursor', 's')
"	returns 'slash'
"
fu! s:abbr2longArg(...)
    if ! exists('a:2')
	return s:utilLookup(s:d1, a:1)
    elseif ! exists('a:3')
	if a:1=='openLink'|| a:1=='copyLink'|| a:1=='copyFileName'
	    return s:utilLookup(s:d21, a:2)
	elseif a:1=='help'
	    return s:utilLookup(s:d22, a:2)
	endif
    else
	if a:1=='openLink'
	    return s:utilLookup(s:d31, a:3)
	elseif a:1 == 'copyFileName'
	    return s:utilLookup(s:d32, a:3)
	endif
    endif
endfu

"-------------------------------------------------------------------------------
" Lookup 'key' in 'dict'. If defined return its value else return the 'key'
" itself
fu! s:utilLookup(dict,key)
    if has_key(a:dict, a:key)
	return a:dict[a:key] 
    endif
    return a:key
endfu

"----------------------------------------------------------id=Utl---------------
" Central Utl.vim function. Normally invoked by :Utl command
" args: Same as command :Utl (but quoted), see #r=cmd_reference
"
" Example:  call Utl('openLink','http://www.vim.org','split')
"
fu! Utl(...)
    call Utl_trace("- start function Utl()",1,1)
    if exists('a:1') | let cmd=s:abbr2longArg(a:1) | else | let cmd='openLink' | endif
    call Utl_trace("- arg1 (cmd)      provided or by default = `".cmd."'")

    if cmd == 'openLink'
	if exists('a:2') | let operand=s:abbr2longArg(cmd,a:2) | else | let operand='underCursor' | endif
	call Utl_trace("- arg2 (operand)  provided or by default = `".operand."'")
	if exists('a:3') | let dispMode=s:abbr2longArg(cmd,operand,a:3) | else | let dispMode='edit' | endif
	call Utl_trace("- arg3 (dispMode) provided or by default = `".dispMode."'")
	if operand=='underCursor'
	    call s:Utl_goUrl(dispMode)
	elseif operand=='visual'
	    let url = @*
	    call s:Utl_processUrl(url, dispMode)
	elseif operand=='currentFile'
	    let url = 'file://'.Utl_utilBack2FwdSlashes( expand("%:p") )
	    call s:Utl_processUrl(url, dispMode)
        else	" the operand is the URL
	    call s:Utl_processUrl(operand, dispMode)
	endif

    elseif cmd=='copyFileName' || cmd=='copyLink'
	if exists('a:2') | let operand=s:abbr2longArg(cmd,a:2) | else | let operand='underCursor' | endif
	call Utl_trace("- arg2 (operand)  provided or by default = `".operand."'")

	let suffix=''
	if cmd == 'copyFileName'
	    if exists('a:3') | let modifier=s:abbr2longArg(cmd,operand,a:3) | else | let modifier='native' | endif
	    call Utl_trace("- arg3 (modifier) provided or by default = `".modifier."'")
	    let suffix='_'.modifier
	endif

	if operand=='underCursor'
	    call s:Utl_goUrl(cmd.suffix)
	elseif operand=='visual'
	    let url = @*
	    call s:Utl_processUrl(url, cmd.suffix)
	elseif operand=='currentFile'
	    let url = 'file://'.Utl_utilBack2FwdSlashes( expand("%:p") )
	    call s:Utl_processUrl(url, cmd.suffix)
        else	" the operand is the URL
	    call Utl_trace("- `".operand."' (arg2) is not a keyword. So is directly taken as an URL")
	    call s:Utl_processUrl(operand, cmd.suffix)
	endif

    elseif cmd == 'help'
	if exists('a:2') | let operand=s:abbr2longArg(cmd,a:2) | else | let operand='manual' | endif
	call Utl_trace("- arg2 (operand)  provided or by default = `".operand."'\n")   " CR054_extra_nl

	if operand=='manual'
	    help utl_usr.txt
	elseif operand=='commands'
	    call Utl('openLink', 'file://'.Utl_utilBack2FwdSlashes(expand(g:utl__file)).'#r=cmd_reference', 'sview')
	else
	    echohl ErrorMsg | echo "invalid argument: `".operand."'" | echohl None
	endif

    else
	echohl ErrorMsg | echo "invalid argument: `".cmd."'" | echohl None
    endif
    call Utl_trace("- end function Utl()",1,-1)
endfu

"]

"--- Set unset Utl options to defaults (id=options) [

if ! exists("utl_opt_verbose")
    let utl_opt_verbose=0
endif
if ! exists("utl_opt_highlight_urls")
    let utl_opt_highlight_urls='yes'
endif
"]


"--- Suggested mappings for most frequent commands  [id=suggested_mappings] [
"
" nmap <unique> <Leader>ge :Utl openLink underCursor edit<CR>
" nmap <unique> <Leader>gu :Utl openLink underCursor edit<CR>
" nmap <unique> <Leader>gE :Utl openLink underCursor split<CR>
" nmap <unique> <Leader>gS :Utl openLink underCursor vsplit<CR>
" nmap <unique> <Leader>gt :Utl openLink underCursor tabedit<CR>
" nmap <unique> <Leader>gv :Utl openLink underCursor view<CR>
" nmap <unique> <Leader>gr :Utl openLink underCursor read<CR>
"
"					[id=suggested_mappings_visual]
" vmap <unique> <Leader>ge "*y:Utl openLink visual edit<CR>
" vmap <unique> <Leader>gu "*y:Utl openLink visual edit<CR>
" vmap <unique> <Leader>gE "*y:Utl openLink visual split<CR>
" vmap <unique> <Leader>gS "*y:Utl openLink visual vsplit<CR>
" vmap <unique> <Leader>gt "*y:Utl openLink visual tabedit<CR>
" vmap <unique> <Leader>gv "*y:Utl openLink visual view<CR>
" vmap <unique> <Leader>gr "*y:Utl openLink visual read<CR>
"
"
" nmap <unique> <Leader>cfn :Utl copyFileName underCursor native<CR>
" nmap <unique> <Leader>cfs :Utl copyFileName underCursor slash<CR>
" nmap <unique> <Leader>cfb :Utl copyFileName underCursor backSlash<CR>
"
" vmap <unique> <Leader>cfn "*y:Utl copyFileName visual native<CR>
" vmap <unique> <Leader>cfs "*y:Utl copyFileName visual slash<CR>
" vmap <unique> <Leader>cfb "*y:Utl copyFileName visual backSlash<CR>
"
"
" nmap <unique> <Leader>cl :Utl copyLink underCursor<CR>
"
" vmap <unique> <Leader>cl "*y:Utl copyLink visual<CR>
"
"]

let s:utl_esccmdspecial = '%#'	" keep equal to utl_scm.vim#__esc

" isfname adapted to URI Reference characters
let s:isuriref="@,48-57,#,;,/,?,:,@-@,&,=,+,$,,,-,_,.,!,~,*,',(,),%"

"----------------------------------------------------------id=thl_gourl---------
" Process URL (or read: URI, if you like---Utl isn't exact there) under
" cursor: searches for something like <URL:myUrl> or <A HREF="myUrl"> (depending
" on the context), extracts myUrl, an processes that Url (e.g. retrieves the
" document and displays it).
"
" - Arg dispMode -> see <URL:#r=dispMode>
"
fu! s:Utl_goUrl(dispMode)
    call Utl_trace("- start processing (dispMode=".a:dispMode.")",1,1)
    let url =  Utl_getUrlUnderCursor()
    if url == ''
	let v:errmsg = "No URL under Cursor"
	echohl ErrorMsg | echo v:errmsg | echohl None
    else 
	call s:Utl_processUrl(url, a:dispMode)
    endif
    call Utl_trace("- end processing.",1,-1) 
endfu

"-------------------------------------------------------------------------------
" Tries to extract an URL in current buffer at current cursor position.
"
" Returns: URL under cursor if any, else ''
"
fu! Utl_getUrlUnderCursor()
    call Utl_trace("- start getting URL under cursor",1,1) 

    let line = getline('.')
    let icurs = col('.') - 1	" `Index-Cursor'

    call Utl_trace("- first try: checking for URL with embedding like <url:xxx> in current line...",1,1) 
    let url = s:Utl_extractUrlByPattern(line, icurs, '')

    if url=='<undef>'
	call Utl_trace("- ...no",1,-1)
	call Utl_trace("- retry: checking for embedded URL spanning over range of max 5 lines...",1,1) 
	let lineno = line('.')
	" (lineno-1/2 can be negative -> getline gives empty string -> ok)
	let line = getline(lineno-2) . "\n" . getline(lineno-1) . "\n" .
		 \ getline(lineno) . "\n" .
		 \ getline(lineno+1) . "\n" . getline(lineno+2)
	" `Index of Cursor'
	" (icurs off by +2 because of 2 \n's, plus -1 because col() starts at 1 =    +1)
	let icurs = strlen(getline(lineno-2)) + strlen(getline(lineno-1)) + col('.') +1

	let url = s:Utl_extractUrlByPattern(line, icurs, '')
    endif

    if url=='<undef>'
	call Utl_trace("- ...no", 1, -1)
	call Utl_trace("- retry: checking if [ ] style reference...", 1, 1) 
	if stridx(line, '[') != -1
	    let isfname_save = &isfname | let &isfname = s:isuriref " ([)
	    let pat = '\(\(\[[A-Z0-9_]\{-}\]\)\(#\f*\)*\)'	    " &isfname here in \f
	    let url = s:Utl_extractUrlByPattern(line, icurs, pat)
	    let &isfname = isfname_save				    " (]) 
	    " remove trailing punctuation characters if any
	    if url!='<undef>'
		call Utl_trace("- removing trailing punctuation chars from URL if any")
		let url = substitute(url, '[.,:;!?]$', '', '')
	    endif
	endif
    endif

    if url=='<undef>'
	call Utl_trace("- ...no", 1,-1)
	call Utl_trace("- retry: checking for unembedded URL under cursor...", 1,1) 
	" Take <cfile> as URL. But adapt isfname to match all allowed URI Reference characters
	let isfname_save = &isfname | let &isfname = s:isuriref " ([)
	let url = expand("<cfile>")
	let &isfname = isfname_save				" (]) 
    endif


    if url!=''
	call Utl_trace("- ...yes, URL found: `".url."'", 1,-1) 
    else
	call Utl_trace("- ...no", 1,-1)
    endif

    call Utl_trace("- end getting URL under cursor.",1,-1) 
    return url
endfu

"--------------------------------------------------------id=thl_curl------------
" `Utl_extractUrlByPattern' - Extracts embedded URLs from 'linestr':
" Extracts URL from given string 'linestr' (if any) at position 'icurs' (first
" character in linestr is 0). When there is no URL or icurs does not hit the
" URL (i.e. 'URL is not under cursor') returns '<undef>'. Note, that there can
" be more than one URL in linestr. Linestr may contain newlines (i.e. supports
" multiline URLs).
"
" 'pat' argument:
" Embedded URL means, that the URL is surrounded by some tag or characters
" to allow for safe parsing, for instance '<url:'...'>'. This regexp pattern
" has to specify a group \(...\) by which defines the URL.
" Example : '<url:\([^<]\{-}\)>'. If an empty pattern '' is given, default
" patterns apply (see code below).
"
" Examples:
"   :echo s:Utl_extractUrlByPattern('Two Urls <URL:/foo/bar> in this <URL:/f/b> line', 35, '')
"   returns `/f/b'
"
"   :echo s:Utl_extractUrlByPattern('Two Urls <URL:/foo/bar> in this <URL:/f/b> line', 28, '')
"   returns `<undef>'
"
"   :echo s:Utl_extractUrlByPattern('Another embedding here <foo bar>', 27, '')
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
fu! s:Utl_extractUrlByPattern(linestr, icurs, pat)
    let pat = a:pat
    call Utl_trace("- start extracting URL by pattern `".pat."'",1,1) 

    if pat == ''
	call Utl_trace("- pattern is <undef>, determine based on file type") 

	if &ft == 'html'
	    let embedType = 'html'
	else
	    let embedType = 'txt'
	endif

	" (pat has to have the Url in first \(...\) because ({) )
	if  embedType == 'html'
	    call Utl_trace("- file type is 'html'")
	    " Html-Pattern: 
	    " - can have other attributes in <A>, like
	    "   <A TITLE="foo" HREF="#bar">  (before and/or behind HREF)
	    " - can have Whitespace embedding the `=' like
	    "   <A HREF = "#bar">
	    "   Note: Url must be surrounded by `"'. But that should not be mandatory...
	    "   Regexp-Guru please help!
	    let pat = '<A.\{-}HREF\s*=\s*"\(.\{-}\)".\{-}>'

	else
	    call Utl_trace("- file type is not 'html', so use generic pattern")
	    " Allow different embeddings: <URL:myUrl>, <myUrl>.
	    " Plus <LNK:myUrl> for backward compatibility utl-1.0 and future
	    " extension.
	    " ( % in pattern means that this group doesn't count as \1 )
	    let pat = '<\%(URL:\|LNK:\|\)\([^<]\{-}\)>'

	endif
	call Utl_trace("- will use pattern `".pat."'") 

    endif

    let linestr = a:linestr
    let icurs = a:icurs

    " do match() and matchend() ic (i.e. allow url: urL: Url: lnk: lnk: LnK:
    " <a href= <A HREF= ...)
    let saveIgnorecase = &ignorecase |  set ignorecase	    " ([)

    call Utl_trace("- now try to extract URL from given string using this pattern") 
    while 1
	" (A so called literal \n here (and elsewhere), see
	" <URL:vimhelp:expr-==#^since a string>.
	" \_s* can't be used because a string is considered a single line.)
	let ibeg = match(linestr, "[ \\t \n]*".pat)

	if ibeg == -1 || ibeg > icurs
	    let curl = '<undef>'
	    break
	else
	    " matchstart before cursor or same col as cursor,
	    " look if matchend is ok (i.e. after or equal cursor)
	    let iend = matchend(linestr, "[ \\t \n]*".pat) -1
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
    call Utl_trace("- end extracting URL by pattern, returning URL=`".curl."'",1,-1) 
    return curl
endfu


"-------------------------------------------------------------------------------
" Switch syntax highlighting for URLs on or off. Depending on the config
" variable g:utl_opt_highlight_urls
fu! s:Utl_setHighl()

    if g:utl_opt_highlight_urls ==? 'yes'
	augroup utl_highl
	  au!
	  au BufWinEnter * syn case ignore

	  " [id=highl_custom]
	  " Highlighting of URL surrounding `<url' and `>'		" [id=highl_surround]
	  "au BufWinEnter * hi link UtlTag Identifier	" as of Utl v2.0
	  "au BufWinEnter * hi link UtlTag Ignore	" `<url:' and '>' invisible like | | in Vim help
	  "au BufWinEnter * hi link UtlTag PreProc

	  " Highlighting of URL itself (what is inside `<url' and '>'	" [id=highl_inside]
	  "	    Some fixed colors ( not changing with :colorscheme, but all underlined )
	  "au BufWinEnter * hi UtlUrl ctermfg=LightBlue guifg=LightBlue cterm=underline gui=underline term=reverse
	  "au BufWinEnter * hi UtlUrl ctermfg=Blue guifg=Blue cterm=underline gui=underline term=reverse
	  "au BufWinEnter * hi UtlUrl ctermfg=Cyan guifg=Cyan cterm=underline gui=underline term=reverse
	  "	    Some Standard group names (see <url:vimhelp:group-name>)
	  "au BufWinEnter * hi link UtlUrl Tag
	  "au BufWinEnter * hi link UtlUrl Constant
	  au BufWinEnter * hi link UtlUrl Underlined


	  au BufWinEnter * syn region UtlUrl matchgroup=UtlTag start="<URL:" end=">" containedin=ALL
	  au BufWinEnter * syn region UtlUrl matchgroup=UtlTag start="<LNK:" end=">" containedin=ALL

	  au BufWinEnter utl*.vim hi link UtlTrace Comment
	  au BufWinEnter utl*.vim syn region UtlTrace matchgroup=UtlTrace start="call Utl_trace" end=")" containedin=ALL
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
	if hlexists('UtlTrace')
	    syntax clear UtlTrace
	endif

    endif

endfu

call s:Utl_setHighl()

"-------------------------------------------------------------------------------
" Process given Url.
"
" Processing means: retrieve or address or load or switch-to or query or
" whatever the resource given by `url'.
" When succesful, then a local file will (not necessarly) exist, and
" is displayed by vim.  Or is displayed by a helper application (e.g.
" when the Url identifies an image).  Often the local file is cache
" file created ad hoc (e.g. in case of network retrieve).
"
" - The uriref argument can contain line breaks. \s*\n\s* Sequences are
"   collapsed. Other Whitespace is left as is (CR019, CR052).
"   See also <URL:http://www.ietf.org/rfc/rfc2396.txt> under
"   chapter E, Recommendations.
" 
" Examples:
"   call s:Utl_processUrl('file:///path/to/file.txt', 'edit')
"
"   call s:Utl_processUrl('file:///usr/local/share/vim/', 'vie')
"		" may call Vim's explorer
"
"   call s:Utl_processUrl('http://www.vim.org', 'edit')
"		" call browser on URL
"
"   call s:Utl_processUrl('mailto:stb@bf-consulting.de', 'vie')
"		" the local file may be the return receipt in this case
"
fu! s:Utl_processUrl(uriref, dispMode)
    call Utl_trace("- start processing URL `".a:uriref."' in processing mode `".a:dispMode."'",1,1) 

    let urirefpu = a:uriref	" uriref with newline whitespace sequences purged
    " check if newline contained. Collapse \s*\n\s
    if match(a:uriref, "\n") != -1
	let urirefpu = substitute(a:uriref, "\\s*\n\\s*", "", "g")
	call Utl_trace("- URL contains new line characters. Remove them.")
	call Utl_trace("  now URL= `".urirefpu."'") 
    endif

    let uri = UriRef_getUri(urirefpu)
    let fragment = UriRef_getFragment(urirefpu)

    call Utl_trace("- fragment `".fragment."' stripped from URL")

    "--- Handle Same Document Reference (sdreference)
    " processed as separate case, because:
    " 1. No additional 'retrieval' should happen (see
    "    <URL:http://www.ietf.org/rfc/rfc2396.txt#4.2. Same-document>).
    " 2. UtlUri_abs() does not lead to a valid absolute Url (since the base-path-
    "	 file-component will always be discarded).
    "
    if uri == ''
	call Utl_trace("- is a same document reference. Go directly to fragment processing (in mode 'rel')") 
	    " m=go
	normal m'
	call s:Utl_processFragmentText( fragment, 'rel' )
	call Utl_trace("- end processing URL",1,-1)
	return
    endif


    call Utl_trace("- start normalize URL to an absolute URL",1,1)
    let scheme = UtlUri_scheme(uri)
    if scheme != '<undef>'
	call Utl_trace("- scheme defined (".scheme.") - so is an absolute URL")
	let absuri = uri
    else	" `uri' is formally no absolute URI but look for some
		" heuristic, e.g. prepend 'http://' to 'www.vim.org'
	call Utl_trace("- scheme undefined - so is a relative URL or a heuristic URL")
	call Utl_trace("- check for some heuristics like www.foo.com -> http://www.foo.com... ",0)
	let absuri = s:Utl_checkHeuristicAbsUrl(uri)
	if absuri != ''
	    let scheme = UtlUri_scheme(absuri)
	    call Utl_trace("yes,") | call Utl_trace("  absolute URL constructed by heuristic is `".absuri."'") 
	else
	    call Utl_trace("no") 
	endif
    endif
    if scheme == '<undef>'
	let curPath = Utl_utilBack2FwdSlashes( expand("%:p") )
	if stridx(curPath, '://') != -1	    " id=url_buffer (e.g. by netrw)
	    call Utl_trace("- buffer's name looks like an absolute URL (has substring ://)")
	    call Utl_trace("  so take it as base URL.") 
	    let base = curPath
	else
	    call Utl_trace("- try to construct a `file://' base URL from current buffer... ",0) 
	    " No corresponding resource to curPath known.   (id=nobase)
	    " i.e. curPath was not retrieved through Utl.
	    " Now just make the usual heuristic of `file://localhost/'-Url;
	    " assume, that the curPath is the resource itsself. If then the 
	    " retrieve with the so generated Url is not possible, nothing
	    " severe happens.
	    if curPath == ''
		call Utl_trace("not possible, give up")
		let v:errmsg = "Cannot make a base URL from unnamed buffer. Edit a file and try again"
		echohl ErrorMsg | echo v:errmsg | echohl None
		call Utl_trace("- end normalize URL to an absolute URL",1,-1)
		call Utl_trace("- end processing URL",1,-1)
		return
	    endif
	    let base = 'file://' . curPath
	    call Utl_trace("done,")
	endif
	call Utl_trace("  base URL is `".base."'") 
	let scheme = UtlUri_scheme(base)
	call Utl_trace("- construct absolute URL from combining base URL and relative URL")
	let absuri = UtlUri_abs(uri,base)
    endif
    call Utl_trace("- assertion: now have absolute URL `".absuri."' with scheme `".scheme."'")
    call Utl_trace("- end normalize URL to an absolute URL",1,-1)

    if a:dispMode==? 'copyLink'
	call Utl_trace("processing mode is `copyLink'. Copy link to clipboard")
	call setreg('*', absuri)
	echo "Copied `".@*."' to clipboard"
	call Utl_trace("- end processing URL",1,-1)
	return
    endif


    "--- Call the appropriate retriever (see <URL:utl_scm.vim>)
    call Utl_trace("- start scheme handler processing",1,1)

    " Always set a jump mark to allow get back to cursor position before
    " jump (see also CR051).
	" m=go	id=_setj
    normal m'

    let cbfunc = 'Utl_AddressScheme_' . scheme
    call Utl_trace("- constructing call back function name from scheme: `".cbfunc."'") 
    if !exists('*'.cbfunc)
	let v:errmsg = "Sorry, scheme `".scheme.":' not implemented"
	echohl ErrorMsg | echo v:errmsg | echohl None
        call Utl_trace("- end scheme handler processing",1,-1)
	call Utl_trace("- end processing URL",1,-1)
	return
    endif
    call Utl_trace("- calling call back function with arguments:")
    call Utl_trace("  arg 1 - absolute URL=`".absuri."'") 
    call Utl_trace("  arg 2 - fragment    =`".fragment."'") 
    call Utl_trace("  arg 3 - display Mode=`".a:dispMode."'") 
    exe 'let ret  = ' cbfunc . '("'.absuri.'", "'.fragment.'", "'.a:dispMode.'")'
    call Utl_trace("- call back function `".cbfunc."' returned list:`". join(ret,',') ."'")
    exe "normal \<C-L>"	| " Redraw seems necessary for non GUI Vim under Unix'es

    if !len(ret)
	call Utl_trace("- empty list -> no further processing")
        call Utl_trace("- end scheme handler processing",1,-1)
	call Utl_trace("- end processing URL",1,-1)
	return
    endif

    let localPath = ret[0]
    let fragMode = get(ret, 1, 'abs')
    call Utl_trace("- first list element (local path): `".localPath."'")
    call Utl_trace("- second list element (fragment mode) or default: `".fragMode."'") 

    " Assertion
    if stridx(localPath, '\') != -1 
	echohl ErrorMsg
	call input("Internal Error: localPath `".localPath."' contains backslashes <RETURN>") 
	echohl None
    endif

    call Utl_trace("- assertion: a local path corresponds to URL") 
    call Utl_trace("- end scheme handler processing",1,-1)

    let dispMode = a:dispMode
    if a:dispMode == 'copyFileName_native'
	if has("win32") || has("win16") || has("win64") || has("dos32") || has("dos16")
	    call Utl_trace("- changing dispMode `copyFileName_native' to 'copyFileName_backSlash' since under Windows")
	    let dispMode = 'copyFileName_backSlash'
	else
	    call Utl_trace("- changing dispMode `copyFileName_native' to 'copyFileName_slash' since not under Windows")
	    let dispMode = 'copyFileName_slash'
	endif
    endif

    if dispMode == 'copyFileName_slash'
	call Utl_trace("- processing mode is `copyFileName_slash': copy file name, which corresponds to link")
	call Utl_trace("  (with forward slashes) to clipboard")
	call setreg('*', localPath )
	echo "Copied `".@*."' to clipboard"
	call Utl_trace("- end processing URL",1,-1)
	return
    elseif dispMode == 'copyFileName_backSlash'
	call Utl_trace("- processing mode is `copyFileName_backSlash': copy file name, which corresponds to link")
	call Utl_trace("  (with backslashes) to clipboard")
	call setreg('*', Utl_utilFwd2BackSlashes(localPath) )
	echo "Copied `".@*."' to clipboard"
	call Utl_trace("- end processing URL",1,-1)
	return
    endif

    " See if media type is defined for localPath, and if yes, whether a
    " handler is defined for this media type (if not the Setup is called to
    " define one). Everything else handle with the default handler
    " Utl_displayFile(), which displays the document in a Vim window.
    " The pseudo handler named 'VIM' is supported: Allows bypassing the media
    " type handling and call default vim handling (Utl_displayFile)
    " although there is a media type defined.
    call Utl_trace("- start media type handler processing",1,1)

    call Utl_trace("- check if there is a file-name to media-type mapping for local path")
    call Utl_trace("  (hardcoded in Utl)... ",0)

    let contentType = s:Utl_checkMediaType(localPath)

    if contentType == ''
        call Utl_trace("no. Display local path in this Vim.")
    else
	call Utl_trace("yes, media type is `".contentType."'.")
	let slashPos = stridx(contentType, '/')

	let var_s = 'g:utl_cfg_hdl_mt_' . substitute(contentType, '[-/+.]', '_', 'g')
	call Utl_trace("- constructing Vim variable for specific media type handler:")
	call Utl_trace("  `".var_s."'. Now check if it exists...")
	if exists(var_s)
	    call Utl_trace("  ...exists, and will be used")
	    let var = var_s
	else
	    call Utl_trace("  ...does not exist. Now check generic media type handler variable")
	    let var_g = 'g:utl_cfg_hdl_mt_generic'
	    if exists(var_g)
		call Utl_trace("- Vim variable `".var_g."' does exist and will be used")
	    else
		call Utl_trace("  Vim variable `".var_g."' does not exist either")
	    endif
	    let var = var_g
	endif

	if ! exists(var)    " Entering setup
	    echohl WarningMsg
	    call input('No handler for media type '.contentType.' defined yet. Entering Setup now. <RETURN>')
	    echohl None
	    call s:Utl_processUrl('config:#r=utl_cfg_hdl_mt_generic', 'split') " (recursion, setup)
	    call Utl_trace("- end media type handler processing",1,-1)
	    call Utl_trace("- end processing URL",1,-1)
	    return
	endif
	exe 'let varVal =' . var
	call Utl_trace("- Variable has value `".varVal."'")
	if varVal ==? 'VIM'
	    call Utl_trace("- value of variable is 'VIM': display in this Vim")
	else
	    call Utl_trace("- construct command by expanding any % conversion specifiers.")
	    let convSpecDict= { 'p': localPath, 'P': Utl_utilFwd2BackSlashes(localPath),
		    \ 'f': (fragment=="<undef>" ? "" : fragment) }	" '<undef>' -> '' for external handler
	    exe 'let [errmsg,cmd] = Utl_utilExpandConvSpec('.var.', convSpecDict)'
	    if errmsg != ""
		echohl ErrorMsg
		echo "The content of the Utl-setup variable `".var."' is invalid and has to be fixed! Reason: `".errmsg."'"
		echohl None
		call Utl_trace("- end media type handler processing",1,-1)
		call Utl_trace("- end processing URL",1,-1)
		return
	    endif
	    call Utl_trace("- constructed command is: `".cmd."'")
	    " Escape string to be executed as a ex command (i.e. escape some
	    " characters from special treatment <URL:vimhelp:cmdline-special>)
	    " and execute the command
	    let escCmd = escape(cmd, s:utl_esccmdspecial)
	    if escCmd != cmd
		call Utl_trace("- escape characters, command changes to: `".escCmd."'")
	    endif
	    call Utl_trace("- execute command with :exe") 
	    exe escCmd
	    call Utl_trace("- end media type handler processing",1,-1)
	    call Utl_trace("- end processing URL",1,-1)
	    return
	endif
    endif
    call Utl_trace("- end media type handler processing",1,-1)

    if s:Utl_displayFile(localPath, dispMode)
	call s:Utl_processFragmentText(fragment, fragMode)
    endif
    call Utl_trace("- end processing URL",1,-1)
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
fu! s:Utl_checkHeuristicAbsUrl(uri)

    "--- [1] -> foot:1
    if match(a:uri, '^\[.\{-}\]') != -1
	return substitute(a:uri, '^\[\(.\{-}\)\]', 'foot:\1', '')

    "--- www.host.domain -> http://www.host.domain
    elseif match(a:uri, '^www\.') != -1
	return 'http://' . a:uri

    "--- user@host.domain -> mailto:user@host.domain
    elseif match(a:uri, '@') != -1
	return 'mailto:' . a:uri

    "--- :xxx  -> vimscript::xxx
    elseif match(a:uri, '^:') != -1
	return 'vimscript:' . a:uri

    " BT12084 -> BT:12084			    #id=heur_example
    " This is an example of a custom heuristics which I use myself. I have a
    " text file which contains entries like 'BT12084' which refer to that id
    " 12084 in a bug tracking database.
    elseif match(a:uri, '^[PB]T\d\{4,}') != -1
     	return substitute(a:uri, '^\([PB]T\)\(\d\+\)', 'BT:\2', '')

    endif

    return ''
endfu


"------------------------------------------------------------------------------
" Escape some special characters in  fileName  which have special meaning
" in Vim's command line but what is not desired in URLs.
" Example: In file 'a%b.txt' the % must not be expanded to the current file.
"
" - returns: Escaped fileName
"
fu! s:Utl_escapeCmdLineSpecialChars(fileName)

    " - Escape characters '#' and '%' with special meaning for Vim
    "   cmd-line (see <URL:vimhelp:cmdline-special> because they must have no special
    "   meaning in URLs.
    let escFileName = escape(a:fileName, s:utl_esccmdspecial)

    " - Also escape '$': Will otherwise tried to be expanded by Vim as Envvar (CR030).
    "   But only escape if there is an identifier character after the $ (CR053).
    let escFileName = substitute(escFileName, '\$\(\I\)', '\\$\1', 'g')

    " - Also escape blanks because single word needed, e.g. `:e foo bar'.
    "   Escape spaces only if on unix (no problem on Windows) (CR033)
    if has("unix")
	let escFileName = escape(escFileName, ' ')
    endif

    return escFileName
endfu

"-------------------------------------------------------------------------------
" Description: 
" Display file `localPath' in a Vim window as determined by `dispMode'
" There is special treatment if `localPath' already loaded in a buffer and
" there is special treatment if current buffer cannot be abandoned.
" Escapes characters in localPath which have special meaning for Vim but
" which must not have special meaning in URL paths.
"
" - `dispMode' specification:	    (id=dispMode)
"    Resembles XML-XLink's `show' attribut. Value is taken directly as Vim
"    command. Examples: 'view', 'edit', 'sview', 'split', 'read', 'tabe'
"
" - localPath specification: 
"   . May contain any characters that the OS allows (# % $ ' ')
"     Note: No percent escaping here, localPath is a file name not an URL.
"     For instance %20.txt is taken as literal file name.
"
" - returns: 1 on success (a:localPath loaded), else 0
"
" - collaboration:
"   . Does not explicitly set the cursor
"   . Does not explicitly set the ' mark
"
" Example:	:call s:Utl_displayFile('t.txt', 'split')
"
fu! s:Utl_displayFile(localPath, dispMode)
    call Utl_trace("- start display file `".a:localPath."' in mode `".a:dispMode."'",1,1)

    let bwnrlp = bufwinnr(a:localPath)
    if bwnrlp != -1 && winnr() == bwnrlp
	call Utl_trace("- file already displayed in current window")
	call Utl_trace("- end display file",1,-1)
	return 1
    endif

    if bwnrlp != -1
	" localPath already displayed, but not in current window
	" Just make this buffer the current window.
	call Utl_trace("- file already displayed, but not in other window. Move to that window")
	exe bwnrlp . "wincmd w"
    else    " Open file
	call Utl_trace("- file not yet displayed in any window")

	" Possibly alter dispMode to avoid E37 error	(id=_altersa)
	" If buffer cannot be <URL:vimhelp:abandon>ned, for given dispMode,
	" silently change the dispMode to a corresponding split-dispMode. Want
	" to avoid annoying E37 message when executing URL on modified buffer (CR024)
	let dispMode = a:dispMode
	if getbufvar(winbufnr(0),"&mod") && ! getbufvar(winbufnr(0),"&awa") && ! getbufvar(winbufnr(0),"&hid")
	    if dispMode == 'edit'
		let dispMode = 'split'
		call Utl_trace("- current window can probably not be quit, so silently change mode to `split'")
	    elseif dispMode == 'view'
		let dispMode = 'sview'
		call Utl_trace("- current window can probably not be quit, so silently change mode to `sview'")
	    endif
	endif

	let escLocalPath = s:Utl_escapeCmdLineSpecialChars(a:localPath)
	if escLocalPath != a:localPath
	    call Utl_trace("- Escaped one or more characters out of #,%,$ (under Unix also blank)")
	    call Utl_trace("  because these would else be expanded in Vim's command line")
	    call Utl_trace("  File name changed to: `".escLocalPath."'")
	endif


	"--- Try load file or create new buffer. Then check if buffer actually
	"   loaded - might fail for if E325 (swap file exists) and user abort
	" 
	let cmd = dispMode.' '.escLocalPath
	call Utl_trace("- trying to load/display file with command: `".cmd."'\n")   " CR054_extra_nl
	exe cmd
	exe "normal \<C-L>"	| " Redraw seems necessary for non GUI Vim under Unix'es

	if bufwinnr(escLocalPath) != winnr()	" not loaded
	    call Utl_trace("- not loaded.")
	    call Utl_trace("- end display file (not successful)",1,-1)
	    return 0
	endif

    endif

    call Utl_trace("- end display file (successful)",1,-1)
    return 1
endfu

"----------------------------------------------------------id=utl_checkmtype----
" Possibly determines the media type (= mime type) for arg `path', e.g. 
" pic.jpeg -> 'image/jpeg' and returns it. Returns an empty string if media
" type cannot be determined or is uninteresting to be determined. Uninteresting
" means: Only those media types are defined here which are of potential
" interest for being handled by some external helper program (e.g. MS Word for
" application/msword or xnview for application/jpeg).
"
" When this function returns a non empty string Utl checks if a specific media
" type handler is defined. If not Utl's setup utility is called to define one.
"
" - You may add other mediatypes. See
"   <URL:ftp://ftp.iana.org/assignments/media-types/> or
"   <URL:http://www.iana.org/assignments/media-types/> for the registry of
"   media types. On Linux try <URL:/etc/mime.types> In general this makes only
"   sense when you also supply a handler for every media type you define, see
"   <URL:./utl_rc.vim#r=mediaTypeHandlers>.
"
fu! s:Utl_checkMediaType(path)

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
    elseif ext==?'msg'
        let mt = 'application/msmsg'
    elseif ext==?'avi'
	let mt = 'video/x-msvideo'

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

"id=Utl_processFragmentText-----------------------------------------------------
" Description:
" Position cursor in current buffer according `fragment', modified by
" `fragMode' which can have values 'abs' or 'rel'.
"
" - arg `fragment' can be:
"   tn=string	    - searches  string  beginning at start position forward.
"		      The naked fragment (without a `xx=' as prefix defaults
"		      to tn=).
"   tp=string	    - searches  string  beginning at start position backward.
"   line=number	    - move cursor  number  lines from start position. Number
"		      can be positive or negative. If `fragMode' is 'abs'
"		      -1 denotes the last line, -2 the before last line etc.
"   r=identifier    - (IdReference) search for  id=identifier\>  starting from
"		      begin of buffer. `fragMode' is ignored.
"
" - arg `fragMode' modifies the start position. Can have the values:
"   'abs' = absolute: Cursor is set to begin or end of document, depending on
"	    fragment, then position starting from there.
"	    Start position for tn=, line=nnn, line=+nnn r= is begin of buffer.
"	    Start position for tp=, line=-nnn is end of buffer.
"   'rel' = relative: Start positioning the cursor from current position.
"
" Details: 
" - `fragment' will be URI-Unescaped before processing (e.g. 'tn=A%3aB' ->
"   'tn=A:B')
" - Interpretation of `fragment' depends on the filetype. But currently,
"   the only non generic treatment is for HTML references.
" - `Fragment' can be '<undef>' or '' (empty).
" - If `rel' position the cursor to begin or end of line prior to actual
"   search: a target string in the same line will not be found.
"   (Remark: Intent is to support Same-Document references: avoid that
"   the search finds the fragment definition itself. Should not be a
"   problem in other cases, e.g. vimhelp scheme)
"
" Known Bugs:
" - For 'abs' search does not find pattern starting at begin of file
"
fu! s:Utl_processFragmentText(fragment, fragMode)
    call Utl_trace("- start processing fragment `".a:fragment."' in mode `".a:fragMode."'",1,1) 

    if a:fragment == '<undef>' || a:fragment == ''
	call Utl_trace("- have no or empty fragment") 
	if a:fragMode=='abs'
	    call Utl_trace("- since mode is `abs' position cursor to begin of buffer") 
	    call cursor(1,1)
	else
	    call Utl_trace("- since mode is `rel' do nothing") 
	endif
	call Utl_trace("- end processing fragment",1,-1) 
	return
    endif

    let ufrag = UtlUri_unescape(a:fragment)
    if ufrag != a:fragment
        call Utl_trace("- unescaped URL to: `".ufrag."'") 
    endif

    if ufrag =~ '^line=[-+]\=[0-9]*$'
	call Utl_trace("- is a `line=' fragment") 

	let sign = substitute(ufrag, '^line=\([-+]\)\=\([0-9]*\)$', '\1', '')
	let num =  substitute(ufrag, '^line=\([-+]\)\=\([0-9]*\)$', '\2', '')

	if a:fragMode=='abs'
	    if sign == '-'
		call Utl_trace("- negative sign in mode 'abs': position cursor up ".num." lines from end of buffer") 
		call cursor( line('$') - num + 1, 1 )
	    else
		call Utl_trace("- positive sign in mode 'abs': position cursor to line ".num) 
		call cursor(num,1)
	    endif

	else
	    if sign == '-'
		call Utl_trace("- negative sign in mode 'rel': position cursor up ".num." lines from current position") 
		call cursor( line('.') - num , 1 )
	    else
		call Utl_trace("- positive sign in mode 'rel': position cursor down ".num." lines from current position") 
		call cursor( line('.') + num , 1 )
	    endif

	endif
	call Utl_trace("- end processing fragment",1,-1) 
	return
    endif

    " (the rest is positioning by search)
    " Note: \r is necessary for executing cmd with :normal.
    " Note: \M is used in patterns to do search nomagic (e.g. pattern a.c to find a.c
    " and not abc).

    let fragMode = a:fragMode
    let sfwd=1
    if ufrag =~ '^r='
	call Utl_trace("- is an ID reference. Construct file type dependent search pattern") 
	" ( \w\@! is normally the same as \> , i.e. match end of word,
	"   but is not the same in help windows, where 'iskeyword' is
	"   set to include non word characters. \w\@! is independent of
	"   settings )
	let val = substitute(ufrag, '^r=\(.*\)$', '\1', '')
	if &ft == 'html'
	    call Utl_trace("- file type is 'html' - search for NAME=") 
	    let cmd = '/\c\MNAME=\.\=' . val . '\w\@!' . "\r"
	else
	    call Utl_trace("- file type is not 'html' - search for id=") 
	    let cmd = '/\c\Mid=' . val . '\w\@!' . "\r"
	endif
	if fragMode=='rel'
	    call Utl_trace("- search will be with 'wrapscan' (since ID reference anywhere in text)") 
	    let opt_wrapscan='wrapscan'
	endif

    elseif ufrag =~ '^tp='  " text previous
	call Utl_trace("- is a `tp=' (Text Previous) fragment: search backwards") 
	let cmd = substitute(ufrag, '^tp=\(.*\)$', '?\\c\\M\1\r', '')
	let sfwd=0

    elseif ufrag =~ '^tn='  " tn= or naked. text next
	call Utl_trace("- is a `tn=' (Text Next) fragment: search forward") 
	let cmd = substitute(ufrag, '^tn=\(.*\)$', '/\\c\\M\1\r', '')

    else
	call Utl_trace("- is a naked fragment. Is treated like `tn=' (Text Next) fragment: search forward") 
	let cmd = '/\c\M' . ufrag . "\r"	" Note: \c\M vs \\c\\M at <#tp=substitute>
    endif


    " Initialize Cursor before actual search (CR051)
    if fragMode=='abs'
	if sfwd==1
	    call Utl_trace("- forward search in mode 'abs': starting search at begin of buffer") 
	    call cursor(1,1)
	else
	    call Utl_trace("- backward search in mode 'abs': starting search at end of buffer") 
	    call cursor( line('$'), col('$') )
	endif
    else
	if sfwd==1
	    call Utl_trace("- forward search in mode 'rel': starting search at end of current line") 
	    call cursor( line('.'), col('$') )
	else
	    call Utl_trace("- forward search in mode 'rel': starting search at begin of current line") 
	    call cursor( line('.'), 1)
	endif
    endif

    if ! exists('opt_wrapscan') 
	let opt_wrapscan = 'nowrapscan'
	call Utl_trace("- search will be with 'nowrapscan' (avoid false hit if mode='rel')") 
    endif

    " Do text search (id=fragTextSearch)

    "   (Should better use search() instead normal / - there is also a w flag)
    let saveWrapscan = &wrapscan | exe 'set '.opt_wrapscan  | "---[
    " (keepjumps because before jump mark is set before link execution (s. #r=_setj ).
    "  Call cursor() for line= fragments do not change jumps either.)
    call Utl_trace("- execute search command: `".cmd."'") 
    let v:errmsg = ""
    silent! exe "keepjumps normal " . cmd
    if v:errmsg != ""
	let v:errmsg = "fragment address  #" . a:fragment . "  not found in target"
	echohl ErrorMsg | echo v:errmsg | echohl None
    endif

    let &wrapscan = saveWrapscan		    "---]
    call Utl_trace("- restored previous value for 'wrapscan'") 

    call Utl_trace("- end processing fragment",1,-1) 
endfu

" Utility functions [

"id=Utl_utilExpandConvSpec--------------------------------------------------------
" Expands conversion specifiers like %p in  a:str  by replacing
" them by there replacement value. Conversion specifier - replacement pairs
" as provided in  convSpecDict  dictionary.
" Details :
" All occurrences of conversion specifier in a:str will be replaced.
" Specifiers not defined in convSpecDict lead to an error.
" The case of conversion specifier matters, e.g. %p and '%P' are different.
"
" Args:
" str		- string to be expanded
" convSpecDict	- dictionary containing specifier - replacement entries,
"		  e.g. 'p' - 'c:/path/to/file'
"
" Returns: List [errormessage, converted string],
"	   where either or the other is an empty string
"
fu! Utl_utilExpandConvSpec(str, convSpecDict)

    let rest = a:str
    let out = ''
    while 1

	let percentPos = stridx(rest, '%')
	if percentPos != -1
	    let left = strpart(rest, 0, percentPos)
	    let specifier = strpart(rest, percentPos+1, 1)
	    let rest = strpart(rest, percentPos+2)
	else
	    let out = out . rest
	    break
	endif
	if strpart(left, percentPos-1, 1) == '\'    " escaped \%
	    let left = strpart(left, 0, percentPos-1)
	    let repl = '%' . specifier
	else	    " not escaped
	    if specifier == ''
		return ["Unescaped % character at end of string >".a:str."<", ""]
	    elseif has_key(a:convSpecDict, specifier)
		let repl = a:convSpecDict[specifier]
	    else
		return ["Invalid conversion specifier `%".specifier."' in `".a:str.
		    \ "'. Valid specifiers are: `". join(map(keys(a:convSpecDict), '"%".v:val')), ""]
	    endif
	endif
	let out = out . left . repl

    endwhile
    return ["",out]

endfu

"-------------------------------------------------------------------------------
" Print tracing messages (with :echo) to see what's going on. 
" Only prints if global variable utl_opt_verbose is not 0. 
" Currently works only in on/off-manner. Might be extended to distinguish
" trace levels (as Vim's 'verbose' option does, see <url:vimhelp:'verbose'>)
"
" - args
"     msg,
"     [flush,]	    boolean, default=1 -> print msg directly
"     [incrLevel]   number, values= -1 (reduce indent), 0 (unchanged), +1 (augment indent)
"		    default ist 0 (unchanged)
"
let s:utl_trace_buffer = ''
let s:utl_trace_level = 0
fu! Utl_trace(msg, ...)

    if g:utl_opt_verbose == 0
	return
    endif
    "echo "                                DBG msg=`".a:msg."'"

    let flush=1
    if exists('a:1')
	let flush = a:1
    endif

    let incrLevel = 0
    if exists('a:2')
	let incrLevel = a:2
    endif

    " If negative, do it before printing
    if incrLevel < 0  
	let s:utl_trace_level += incrLevel
	" Assertion
	if s:utl_trace_level < 0
	    echohl ErrorMsg
	    call input("Internal Error: Utl_trace: negative indent. Setting to zero <RETURN>")
	    echohl None
	    let s:utl_trace_level = 0
	endif
	"echo "                                DBG (changed,before) utl_trace_level=`".s:utl_trace_level."'"
    endif 

    " echohl ErrorMsg
    " echo "Error: internal error: s:utl_trace_level < 0: `".s:utl_trace_level."'"
    " echohl None


    let s:utl_trace_buffer = s:utl_trace_buffer . a:msg
    if flush=='1'

	" construct indenting corresponding to level
	let indentNum = s:utl_trace_level
	let indent = ''
	while indentNum
	    "echo "                                DBG indentNum=`".indentNum."'"
	    let indent = indent . '  '  " indent depth is two blanks
	    let indentNum -= 1
	endwhile
	"echo "                                DBG indent=`".indent."'"

	echo indent . s:utl_trace_buffer
	let s:utl_trace_buffer = ''

    endif

    " If positive, do it after printing
    if incrLevel > 0  
	let s:utl_trace_level += incrLevel
	"echo "                                DBG (changed,after) utl_trace_level=`".s:utl_trace_level."'"
    endif 

endfu

"-------------------------------------------------------------------------------
" Descr: Creates a file named  a:outFile  as a copy of file  a:srcFile, where
" only the lines between the first and the second occurrence of  a:mark are kept.
" Details :
" - a:outFile  gets some additional header lines.
" - a:mark  is anchored at the beginning of the line (^ search)
" - a:mark  is taken literally (search with \M - nomagic for it) 
"
" Collaboration: 
" - Shows result to user by prompting hit-any-key
" - Except for use of utl_trace function pure utility function.
"
" Ret:	    -
"
"
fu! Utl_utilCopyExtract(srcFile, outFile, mark)
    call Utl_trace("- start Utl_utilCopyExtract(".a:srcFile.",".a:outFile.",".a:mark.")",1,1)

    let go_back = 'b ' . bufnr("%")
    enew!
    exe 'read '.a:srcFile
    setl noswapfile modifiable
    norm gg

    let buf = bufnr("%")

    " Delete from first line to the first line that starts with a:mark
    let delCmd='1,/\M^'.a:mark.'/d'
    call Utl_trace("- command to delete from top to begin mark= `".delCmd."'")
    exe delCmd

    " Delete from the now first line that starts with a:mark to the end of the text
    let delCmd='/\M^'.a:mark.'/,$d'
    call Utl_trace("- command to delete from end mark to bottom= `".delCmd."'")
    exe delCmd

    0insert
' *****
' CREATED BY VIM PLUGIN UTL.VIM BY FUNCTION Utl_utilCopyExtract()
' *****
.

    exe 'w! '.a:outFile
    exe go_back
    exe 'bwipeout ' . buf

    echohl MoreMsg
    call input("Success: Created file ".a:outFile." <RETURN>")
    echohl None
    call Utl_trace("- end Utl_utilCopyExtract()",1,-1)
endfu


"-------------------------------------------------------------------------------
" Substitute all slashes with forward slashes in copy of  a:str  and return it.
fu! Utl_utilFwd2BackSlashes(str)
    return substitute( a:str , '/', '\', 'g')
endfu
"-------------------------------------------------------------------------------
" Substitute all backslashes with slashes in copy of  a:str  and return it.
fu! Utl_utilBack2FwdSlashes(str)
    return substitute( a:str , '\', '/', 'g')
endfu

" ]

" BEGIN OF DEFINITION OF STANDARD UTL `DRIVERS'		      " id=utl_drivers [

"-------------------------------------------------------------------------------
" Retrieve a resource from the web using the wget network retriever.
" Function designed as g:utl_cfg_hdl_scm_http interface function, e.g. intended to
" be used via  :let g:utl_cfg_hdl_scm_http="call Utl_if_hdl_scm_http__wget('%u')".
" See also #r=utl_cfg_hdl_scm_http__wget
"
" Arg:	    url - URL to be downloaded
" Ret:	    global Vim var  g:utl__hdl_scm_ret_list  set, containing one element:
"	    the name of a temporary file where wget downloaded into.
"
" Setup:    See <url:config:#r=utl_if_hdl_scm_http_wget_setup>
"

fu! Utl_if_hdl_scm_http__wget(url)
    call Utl_trace("- start Utl_if_hdl_scm_http__wget(".a:url.")",1,1)

    " Possibly transfer suffix from URL to tempname for correct subsequent
    " media type handling If no suffix then assume 'html' (ok for
    " http://www.vim.org -> index.html). But is not generally ok
    " (example: http://www.vim.org/download.php).
    " TODO: 
    " Should determine media type from HTTP Header, e.g.
    " wget --save-headers -> Content-Type: text/html)
    let suffix = fnamemodify( UtlUri_path(a:url), ":e")
    if suffix == ''
	let suffix = 'html'
    endif

    let tmpFile = Utl_utilBack2FwdSlashes( tempname() ) .'.'.suffix
    call Utl_trace("- tmpFile name with best guess suffix: ".tmpFile)

    if ! executable('wget') 
	call Utl_trace("- Vim variable g:utl_cfg_hdl_scm_mail does not exist")
	echohl WarningMsg
	let v:errmsg="No executable `wget' found."
	call input( v:errmsg . " Entering Setup now. <RETURN>")
	echohl None
	Utl openLink config:#r=utl_if_hdl_scm_http_wget_setup split
	call Utl_trace("- end execution of Utl_AddressScheme_mail",1,-1) 
	return
    endif

    let cmd = '!wget '.a:url.' -O '.tmpFile
    call Utl_trace("- executing cmd: `".cmd."'")
    exe cmd
    call Utl_trace("- setting global list g:utl__hdl_scm_ret_list to `[".tmpFile."]'")
    let g:utl__hdl_scm_ret_list = [tmpFile]
    call Utl_trace("- end Utl_if_hdl_scm_http__wget()",1,-1)
endfu

"-------------------------------------------------------------------------------
" Display an email in Outlook
" Function designed as g:utl_cfg_hdl_scm_mail interface function, e.g. intended to
" be used via  :let g:utl_cfg_hdl_scm_mail="call Utl_if_hdl_scm_mail__outlook('%a',
" '%p','%d','%f','%s')". See also #r=utl_cfg_hdl_scm_mail__outlook
"
" Args:	    ...
" Ret:	    - 
"
" Setup:    See <url:config:#r=utl_if_hdl_scm_mail__outlook_setup>

fu! Utl_if_hdl_scm_mail__outlook(authority, path, date, from, subject)
    call Utl_trace("- start Utl_if_hdl_scm_mail__outlook(".a:authority.",".a:path.",".a:date.",".a:from.",".a:subject.")",1,1)
    if ! exists('g:utl__file_if_hdl_scm__outlook')
	let g:utl__file_if_hdl_scm__outlook = fnamemodify(g:utl__file, ":h") . '/../utl_if_hdl_scm__outlook.vbs'
	call Utl_trace("- configure interface handler variable for Outlook g:utl__file_if_hdl_scm__outlook=")
	call Utl_trace("  ".g:utl__file_if_hdl_scm__outlook)
    endif
    if ! filereadable(g:utl__file_if_hdl_scm__outlook)
	echohl WarningMsg
	let v:errmsg="No Outlook interface found."
	call input( v:errmsg . " Entering Setup now. <RETURN>")
	echohl None
	Utl openLink config:#r=Utl_if_hdl_scm_mail__outlook_setup split
	call Utl_trace("- end Utl_if_hdl_scm_mail__outlook()",1,-1)
	return
    endif
    let cmd='!start wscript "'.g:utl__file_if_hdl_scm__outlook .'" "'. a:authority.'" "'.a:path.'" "'.a:date.'" "'.a:from.'" "'.a:subject.'"'
    call Utl_trace("- executing cmd: `".cmd."'")
    exe cmd
    call Utl_trace("- end Utl_if_hdl_scm_mail__outlook()",1,-1)
endfu

"-------------------------------------------------------------------------------
" Display a file in Acrobat Reader. #page=123 Fragments are supported, i.e.
" display the file at this given page.
" Function designed as  g:utl_cfg_hdl_mt_application_pdf  interface function,
" e.g. intended to be used via  :let g:utl_cfg_hdl_mt_application_pdf="call
" Utl_if_hdl_mt_application_pdf_acrobat('%P', '%f')".
" See also #r=utl_cfg_hdl_mt_application_pdf_acrobat.
"
" Arg:	    path     - file to be displayed in Acrobat (full path)
"	    fragment - fragment (without #) or empty string if no fragment
"
" Ret:	    -
"
" Setup:    See <config:#r=Utl_if_hdl_mt_application_pdf_acrobat_setup>
"

fu! Utl_if_hdl_mt_application_pdf_acrobat(path,fragment)
    call Utl_trace("- start Utl_if_hdl_mt_application_pdf_acrobat(".a:path.",".a:fragment.")",1,1)
    let switches = ''
    if a:fragment != ''
	let ufrag = UtlUri_unescape(a:fragment)
	if ufrag =~ '^page='
	    let fval = substitute(ufrag, '^page=', '', '')
	    let switches = '/a page='.fval
	else 
	    echohl ErrorMsg
	    echo "Unsupported fragment `#".ufrag."' Valid only `#page='"
	    echohl None
	    return
	endif
    endif

    if ! exists('g:utl_cfg_hdl_mt_application_pdf_acrobat_exe_path')    " Entering setup
	call Utl_trace("- Vim variable `g:utl_cfg_hdl_mt_application_pdf_acrobat_exe_path.' does not exist")
	echohl WarningMsg
	call input('variable  g:utl_cfg_hdl_mt_application_pdf_acrobat_exe_path  not defined. Entering Setup now. <RETURN>')
	echohl None
	Utl openLink config:#r=Utl_if_hdl_mt_application_pdf_acrobat_setup split
	call Utl_trace("- end Utl_if_hdl_mt_application_pdf_acrobat() (not successful)",1,-1)
	return
    endif
										" id=ar_switches
    let cmd = ':silent !start '.g:utl_cfg_hdl_mt_application_pdf_acrobat_exe_path.' /a page='.ufrag.' "'.a:path.'"'
    call Utl_trace("- executing cmd: `".cmd."'")
    exe cmd

    call Utl_trace("- end Utl_if_hdl_mt_application_pdf_acrobat()",1,-1)
endfu

"-------------------------------------------------------------------------------
" Display a file in MS-Word. #tn=text  Fragments are supported, i.e.
" display the file at position of first occurrence of  text.
" Function designed as  g:utl_cfg_hdl_mt_application_msword  interface function,
" e.g. intended to be used via  :let g:utl_cfg_hdl_mt_application_msword="call
" Utl_if_hdl_mt_application_msword__word('%P', '%f')".
" See also #r=utl_cfg_hdl_mt_application_msword__word.
"
" Arg:	    path     - file to be displayed in Acrobat (full path)
"	    fragment - fragment (without #) or empty string if no fragment
"
" Ret:	    - 
"
" Setup:    See <config:#r=Utl_if_hdl_mt_application_msword__word_setup>
"

fu! Utl_if_hdl_mt_application_msword__word(path,fragment)
    call Utl_trace("- start Utl_if_hdl_mt_application_msword__word(".a:path.",".a:fragment.")",1,1)

    if ! exists('g:utl__file_if_hdl_mt_application_msword__word')
	let g:utl__file_if_hdl_mt_application_msword__word = fnamemodify(g:utl__file, ":h") . '/../utl_if_hdl_mt_application_msword__word.vbs'
	call Utl_trace("- configure interface handler variable for MS-Word g:utl__file_if_hdl_mt_application_msword__word=")
	call Utl_trace("  ".g:utl__file_if_hdl_mt_application_msword__word)
    endif
    if ! filereadable(g:utl__file_if_hdl_mt_application_msword__word)
	echohl WarningMsg
	let v:errmsg="No Word interface found."
	call input( v:errmsg . " Entering Setup now. <RETURN>")
	echohl None
	Utl openLink config:#r=Utl_if_hdl_mt_application_msword__word_setup split
	call Utl_trace("- end Utl_if_hdl_mt_application_msword__word() (not successful)",1,-1)
	return
    endif

    if ! exists('g:utl_cfg_hdl_mt_application_msword__word_exe_path')    " Entering setup
	call Utl_trace("- Vim variable `g:utl_cfg_hdl_mt_application_pdf_acrobat_exe_path.' does not exist")
	echohl WarningMsg
	call input('variable  g:utl_cfg_hdl_mt_application_msword__word_exe_path  not defined. Entering Setup now. <RETURN>')
	echohl None
	Utl openLink config:#r=Utl_if_hdl_mt_application_msword__word_setup split
	call Utl_trace("- end Utl_if_hdl_mt_application_msword__word() (not successful)",1,-1)
	return
    endif

    let cmd = 'silent !start '.g:utl_cfg_hdl_mt_application_msword__word_exe_path.' "'.a:path.'"'
    call Utl_trace("- cmd to open document: `".cmd."'")
    exe cmd
    if a:fragment == ''
	call Utl_trace("- end Utl_if_hdl_mt_application_msword__word() (successful, no fragment)",1,-1)
	return
    endif
    " (CR044:frag)
    let ufrag = UtlUri_unescape(a:fragment)
    if ufrag =~ '^tn=' " text next / text previous
	let fval = substitute(ufrag, '^tn=', '', '')
    elseif ufrag =~ '[a-z]\+='
	echohl ErrorMsg
	echo 'Unsupported fragment key `'.substitute(ufrag, '\c^\([a-z]\+\).*', '\1=', '')."'. Valid only: `tn='"
	echohl None
	call Utl_trace("- end Utl_if_hdl_mt_application_msword__word() (not successful)",1,-1)
	return
    else
	let fval=ufrag	    " naked fragment same as tn=
    endif
    let cmd='silent !start wscript "'.g:utl__file_if_hdl_mt_application_msword__word .'" "'. a:path.'" "'.fval.'"'
    call Utl_trace("- cmd to address fragment: `".cmd."'")
    exe cmd
    call Utl_trace("- end Utl_if_hdl_mt_application_msword__word()",1,-1)
endfu

let &cpo = s:save_cpo

finish

=== FILE_OUTLOOK_VBS {{{
' file: utl_if_hdl_scm__outlook.vbs
' synopsis: utl_if_hdl_scm__outlook.vbs "" "Inbox" "08.02.2008 13:31" "" ""
' collaboration: - Used by utl.vim when accessing "mail:" URLs using MS-Outlook.
'		 - Outlook must be running
' hist:
' 2008-02-29/Stb: Version for Utl.vim v3.0a
Option Explicit

Dim ol, olns, folder, entryId, item, myNewFolder
Dim a_authority, a_path, a_from, a_subject, a_date

a_authority = WScript.Arguments(0)
a_path = WScript.Arguments(1)
a_date = WScript.Arguments(2)
a_from = WScript.Arguments(3)
a_subject = WScript.Arguments(4)

if a_from <> "" Then
    MsgBox "utl_if_hdl_scm__outlook.vbs: Sorry:  from=  query not supported. Will be ignored"
end if
if a_from <> "" Then
    MsgBox "utl_if_hdl_scm__outlook.vbs: Sorry:  subject=  query not supported. Will be ignored"
end if

Set ol = GetObject(, "Outlook.Application")
Set olns = ol.GetNameSpace("MAPI")

'-----
' Get root folder
if a_authority = "" Then
    ' No a_authority defaults to folder which contains the default folders
    Set folder = olns.GetDefaultFolder(6)
    Set folder = folder.Parent
else
    Set folder = olns.Folders.item( a_authority )
end if

'-----
' Trailing slash possible even with no path defined.
' So remove it independently of path treatment
if a_path <> "" Then
    ' Remove leading "/"
    a_path = Right( a_path, Len(a_path)-1 )
end if

'-----
' If a_path given search a_path recursively to get corresponding
' folder object (currently no hierarchies, only one subfolder)
if a_path <> "" Then
    Set folder = folder.Folders.item( a_path )
end if


Dim sFilter

'-----
' Four minute time range turned out to work fairly well finally...
Dim dateMin, dateMax
dateMin = CStr( DateAdd("n", -2, a_date) )
dateMax = CStr( DateAdd("n", 2, a_date) )
'	cut seconds added by DateAdd
dateMin = Left(dateMin, Len(dateMin) -3 )
dateMax = Left(dateMax, Len(dateMax) -3 )

'id=adapt_column_name
' Unless you have a german Outlook adapt the following line to match you language.
' The Word "Erhalten" probably something like "Received" in english.
' Have a look in you Outlook; its the name of the column which shows and sorts
' by date.
'
'   
' [id=received]	Change to actual column name in your Outlook
'               +---------------------------------+
'	        v                                 v
sFilter = "[Erhalten] > '" + dateMin + "' AND [Erhalten] < '" + dateMax + "'"

Set item = folder.Items.find(sFilter)

item.Display
=== FILE_OUTLOOK_VBS }}}
=== FILE_WORD_VBS {{{
' usage: utl_if_hdl_mt_application_msword__word.vbs <.doc file> <string_to_search>
' description: Position cursor in Word document <.doc file> at string
'	<string_to_search> 
' Collaboration: Word being started or running. Document subject to fragment
'	addressing active or being opened and activated.
' hist:
' 2008-03-20/Stb: Version for Utl.vim v3.0a

' TODO: "Option Explicit" ( Can't get it running with...  %-/ )

const wdGoToPage = 1
const wdGoToAbsolute = 1
const wdFindContinue = 1

docPath = WScript.Arguments(0)
fragment = WScript.Arguments(1)

' Wait for WORD in case it just starts up
countTries = 0
maxTries = 50
Do While countTries < maxTries 
    countTries = countTries+1
    On Error Resume Next
	Set o = GetObject(, "Word.Application")
    If Err Then
	WScript.Sleep 200
	Err.Clear
    Else
        Exit Do
    End If
Loop

' TODO: Exit if still not loaded

' Wait until document loaded
countTries = 0
maxTries = 20
docFound = FALSE
Do While countTries < maxTries 

    countTries = countTries+1

    ' schauen ob ActiveDocument.Name (schon) gleich
    ' dem docPath ist.


    pos = InStr(1, docPath, o.ActiveDocument.Name, 1)

    If pos <> 0 then
        docFound = TRUE
        Exit Do
    End If

    WScript.Sleep 200

Loop

If docFound=FALSE then
    WScript.Echo("Document not found")
End If 

' TODO: Exit If docFound=FALSE
' assertion: document active

' process fragment
' TODO: support also page= fragment:
' 'o.Selection.GoTo wdGotoPage, wdGoToAbsolute, 20

o.Selection.Find.ClearFormatting
With o.Selection.Find
    .Text = fragment
    .Replacement.Text = ""
    .Forward = True
    .Wrap = wdFindContinue
    .Format = False
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
End With
o.Selection.Find.Execute

=== FILE_WORD_VBS }}}

" END OF DEFINITION OF STANDARD UTL `DRIVERS' ]

" vim: set foldmethod=marker:

" -----id=foot1
" Thanks for trying out Utl.vim :-)
