" ------------------------------------------------------------------------------
" File:		thlnkuri.vim -- module for parsing URIs
"			        Part of the Thlnk plugin, see ./thlnk.vim
" Author:	Stefan Bittner <stb@bf-consulting.de>
" Licence:	This program is free software; you can redistribute it and/or
"		modify it under the terms of the GNU General Public License.
"		See http://www.gnu.org/copyleft/gpl.txt
" Last Change:	13-Jun-2002/STB
" Version:	thlnk-1.2
" ------------------------------------------------------------------------------

" Parses URI-References.
" (Can be used independantly from Thlnk.)
" (An URI-Reference is an URI + fragment: myUri#myFragment.
" See also <URL:vim_h:thlnk-uri-refs>.
" Aims to be compliant with <URL:http://www.ietf.org/rfc/rfc2396.txt>
"
" NOTE: The distinction between URI and URI-Reference won't be hold out
"   (is that correct english? %-\ ). It should be clear from the context.
"   The fragment goes sometimes with the URI, sometimes not.
" 
" Usage:
"
"   " Parse an URI
"   let uri = 'http://www.google.com/search?q=vim#tn=ubiquitous'
"
"   let scheme = ThlnkUri_scheme(uri)
"   let authority = ThlnkUri_authority(uri)
"   let path = ThlnkUri_path(uri)
"   let query = ThlnkUri_query(uri)
"   let fragment = ThlnkUri_fragment(uri)
"
"   " Rebuild the URI
"   let uriRebuilt = ThlnkUri_build(scheme, authority, path, query, fragment)
"
"   " ThlnkUri_build a new URI
"   let uriNew = ThlnkUri_build('file', 'localhost', 'path/to/file', '<undef>', 'myFrag')
"
"   let unesc = ThlnkUri_unescape('a%20b%3f')    " -> unesc==`a b?'
"   
" Details:
"   Authority, query and fragment can have the <undef> value (literally!)
"   (similar to undef-value in Perl). That's distinguished from
"   _empty_ values!  Example: http:/// yields ThlnkUri_authority=='' where as
"   http:/path/to/file yields ThlnkUri_authority=='<undef>'.
"   See also
"   <URL:http://www.ietf.org/rfc/rfc2396.txt#tn=Note that we must be careful>
"
" Internal Note:
"   Ist not very performant in typical usage (but clear).
"   s:ThlnkUri_parse executed n times for getting n components of same uri

if exists("loaded_thlnkuri")
    finish
endif
let loaded_thlnkuri = 1
let s:save_cpo = &cpo
set cpo&vim

let thlnkuri_vim = expand("<sfile>")

"------------------------------------------------------------------------------
" Parses `uri'. Used by ``public'' functions like ThlnkUri_path().
" - idx selects the component (see below)
fu! s:ThlnkUri_parse(uri, idx)

    " See <URL:http://www.ietf.org/rfc/rfc2396.txt#tn=^B. Parsing a URI Reference>
    "
    " ^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?
    "  12            3  4          5       6  7        8 9
    " 
    " scheme    = \2
    " authority = \4
    " path      = \5
    " query     = \7
    " fragment  = \9

    " (don't touch! ;-)				id=_regexparse
    return substitute(a:uri, '^\(\([^:/?#]\+\):\)\=\(//\([^/?#]*\)\)\=\([^?#]*\)\(?\([^#]*\)\)\=\(#\(.*\)\)\=', '\'.a:idx, '')

endfu

"-------------------------------------------------------------------------------
fu! ThlnkUri_scheme(uri)
    let scheme = s:ThlnkUri_parse(a:uri, 2)
    " empty scheme impossible (an uri like `://a/b' is interpreted as path = `://a/b').
    if( scheme == '' )
	return '<undef>'
    endif
    " make lowercase, see
    " <URL:http://www.ietf.org/rfc/rfc2396.txt#tn=resiliency>
    return tolower( scheme )
endfu

"-------------------------------------------------------------------------------
fu! ThlnkUri_opaque(uri)
"    echo 'DBG opaque=`' . s:ThlnkUri_parse(a:uri, 3) . s:ThlnkUri_parse(a:uri, 5) . s:ThlnkUri_parse(a:uri, 6) . "'"
    return s:ThlnkUri_parse(a:uri, 3) . s:ThlnkUri_parse(a:uri, 5) . s:ThlnkUri_parse(a:uri, 6)
endfu

"-------------------------------------------------------------------------------
fu! ThlnkUri_authority(uri)
    if  s:ThlnkUri_parse(a:uri, 3) == s:ThlnkUri_parse(a:uri, 4)
	return '<undef>'
    else 
	return s:ThlnkUri_parse(a:uri, 4)
    endif
endfu

"-------------------------------------------------------------------------------
fu! ThlnkUri_path(uri)
    return s:ThlnkUri_parse(a:uri, 5)
endfu

"-------------------------------------------------------------------------------
fu! ThlnkUri_query(uri)
    if  s:ThlnkUri_parse(a:uri, 6) == s:ThlnkUri_parse(a:uri, 7)
	return '<undef>'
    else 
	return s:ThlnkUri_parse(a:uri, 7)
    endif
endfu

"-------------------------------------------------------------------------------
fu! ThlnkUri_fragment(uri)
    if  s:ThlnkUri_parse(a:uri, 8) == s:ThlnkUri_parse(a:uri, 9)
	return '<undef>'
    else 
	return s:ThlnkUri_parse(a:uri, 9)
    endif
endfu


"------------------------------------------------------------------------------
" Concatenate uri components into an uri -- opposite of s:ThlnkUri_parse
" see <URL:http://www.ietf.org/rfc/rfc2396.txt#tn=are recombined>
"
" - it should hold: s:ThlnkUri_parse + ThlnkUri_build = exactly the original Uri
"
fu! ThlnkUri_build(scheme, authority, path, query, fragment)


    let result = ""
    if a:scheme != '<undef>'
	let result = result . a:scheme . ':'
    endif

    if a:authority != '<undef>'
	let result = result . '//' . a:authority
    endif

    let result = result . a:path 

    if a:query != '<undef>'
	let result = result . '?' . a:query
    endif

    if a:fragment != '<undef>'
	let result = result . '#' . a:fragment
    endif

    return result
endfu


"------------------------------------------------------------------------------
" Constructs an absolute URI from a relative URI `uri' by the help of given
" `base' uri and returns it.
"
" See
" <URL:http://www.ietf.org/rfc/rfc2396.txt#tn=^5.2. Resolving Relative References>
" - `uri' may already be absolute (i.e. has scheme), is then returned
"   unchanged
" - `base' should really be absolute! Otherwise the returned Uri will not be
"   absolute (scheme <undef>). Furthermore `base' should be reasonable (e.g.
"   have an absolute Path in the case of hierarchical Uri)
"
fu! ThlnkUri_abs(uri, base)

    " see <URL:http://www.ietf.org/rfc/rfc2396.txt#tn=If the scheme component>
    if ThlnkUri_scheme(a:uri) != '<undef>'
"	echo 'DBG ThlnkUri_abs: scheme defined, uri already absolute' 
	return a:uri
    endif

    let scheme = ThlnkUri_scheme(a:base)

    " query, fragment never inherited from base, wether defined or not,
    " see <URL:http://www.ietf.org/rfc/rfc2396.txt#tn=not inherited from the base URI>
    let query = ThlnkUri_query(a:uri)
    let fragment = ThlnkUri_fragment(a:uri)

    " see <URL:http://www.ietf.org/rfc/rfc2396.txt#tn=If the authority component is defined>
    let authority = ThlnkUri_authority(a:uri)
    if authority != '<undef>'
"	echo 'DBG ThlnkUri_abs: authority defined. quit' 
	return ThlnkUri_build(scheme, authority, ThlnkUri_path(a:uri), query, fragment)
    endif

    let authority = ThlnkUri_authority(a:base)

    " see <URL:http://www.ietf.org/rfc/rfc2396.txt#tn=If the path component begins>
    let path = ThlnkUri_path(a:uri)
    if path[0] == '/'
"	echo 'DBG ThlnkUri_abs: absolute path. quit' 
	return ThlnkUri_build(scheme, authority, path, query, fragment)
    endif
	
    " see <URL:http://www.ietf.org/rfc/rfc2396.txt#tn=needs to be merged>
"    echo 'DBG ThlnkUri_abs: path to be merged'

    "	    step a)
    let new_path = substitute( ThlnkUri_path(a:base), '[^/]*$', '', '')
"    echo 'DBG ThlnkUri_abs: new_path=|' . new_path . '|'
    "	    step b)
    let new_path = new_path . path
"    echo 'DBG ThlnkUri_abs: new_path=|' . new_path . '|'

    "upd implement the missing steps (purge a/b/../c/ into a/c/ etc)

    return ThlnkUri_build(scheme, authority, new_path, query, fragment)


endfu

"------------------------------------------------------------------------------
" strip eventual #myfrag.
" return uri. can be empty
"
fu! UriRef_getUri(uriref)
    let idx = match(a:uriref, '#')
    if idx==-1
	return a:uriref
    endif
    return strpart(a:uriref, 0, idx)
endfu

"------------------------------------------------------------------------------
" strip eventual #myfrag.
" return uri. can be empty or <undef>
"
fu! UriRef_getFragment(uriref)
    let idx = match(a:uriref, '#')
    if idx==-1
	return '<undef>'
    endif
    return strpart(a:uriref, idx+1, 9999)
endfu


"------------------------------------------------------------------------------
" Unescape unsafe characters in given string, 
" e.g. transform `10%25%20is%20enough' to `10% is enough'.
" 
" - typically string is an uri component (path or fragment)
"
" (see <URL:http://www.ietf.org/rfc/rfc2396.txt#tn=2. URI Characters and Escape Sequences>)
"
fu! ThlnkUri_unescape(esc)
    " perl: $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg
    let esc = a:esc
    let unesc = ''
    while 1
	let ibeg = match(esc, '%[0-9A-Fa-f]\{2}')
	if ibeg == -1
"	    echo "DBG unescaped=`". unesc . esc . "'"
	    return unesc . esc
	endif
	let chr = nr2char( "0x". esc[ibeg+1] . esc[ibeg+2] )
	let unesc = unesc . strpart(esc, 0, ibeg) . chr 
	let esc = strpart(esc, ibeg+3, 9999)

    endwhile
endfu

let &cpo = s:save_cpo
