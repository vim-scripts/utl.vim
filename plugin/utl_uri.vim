" ------------------------------------------------------------------------------
" File:		plugin/utl_uri.vim -- module for parsing URIs
"			        Part of the Utl plugin, see ./utl.vim
" Author:	Stefan Bittner <stb@bf-consulting.de>
" Licence:	This program is free software; you can redistribute it and/or
"		modify it under the terms of the GNU General Public License.
"		See http://www.gnu.org/copyleft/gpl.txt
" Version:	utl 3.0a
" ------------------------------------------------------------------------------

" Parses URI-References.
" (Can be used independantly from Utl.)
" (An URI-Reference is an URI + fragment: myUri#myFragment.
" See also <URL:vimhelp:utl-uri-refs>.
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
"   let scheme = UtlUri_scheme(uri)
"   let authority = UtlUri_authority(uri)
"   let path = UtlUri_path(uri)
"   let query = UtlUri_query(uri)
"   let fragment = UtlUri_fragment(uri)
"
"   " Rebuild the URI
"   let uriRebuilt = UtlUri_build(scheme, authority, path, query, fragment)
"
"   " UtlUri_build a new URI
"   let uriNew = UtlUri_build('file', 'localhost', 'path/to/file', '<undef>', 'myFrag')
"
"   " Recombine an uri-without-fragment with fragment to an uri
"   let uriRebuilt = UtlUri_build_2(absUriRef, fragment)
"
"   let unesc = UtlUri_unescape('a%20b%3f')    " -> unesc==`a b?'
"   
" Details:
"   Authority, query and fragment can have the <undef> value (literally!)
"   (similar to undef-value in Perl). That's distinguished from
"   _empty_ values!  Example: http:/// yields UtlUri_authority=='' where as
"   http:/path/to/file yields UtlUri_authority=='<undef>'.
"   See also
"   <URL:http://www.ietf.org/rfc/rfc2396.txt#Note that we must be careful>
"
" Internal Note:
"   Ist not very performant in typical usage (but clear).
"   s:UtlUri_parse executed n times for getting n components of same uri

if exists("loaded_utl_uri") || &cp || v:version < 700
    finish
endif
let loaded_utl_uri = 1
let s:save_cpo = &cpo
set cpo&vim
let g:utl__file_uri = expand("<sfile>")


"------------------------------------------------------------------------------
" Parses `uri'. Used by ``public'' functions like UtlUri_path().
" - idx selects the component (see below)
fu! s:UtlUri_parse(uri, idx)

    " See <URL:http://www.ietf.org/rfc/rfc2396.txt#^B. Parsing a URI Reference>
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
fu! UtlUri_scheme(uri)
    let scheme = s:UtlUri_parse(a:uri, 2)
    " empty scheme impossible (an uri like `://a/b' is interpreted as path = `://a/b').
    if( scheme == '' )
	return '<undef>'
    endif
    " make lowercase, see
    " <URL:http://www.ietf.org/rfc/rfc2396.txt#resiliency>
    return tolower( scheme )
endfu

"-------------------------------------------------------------------------------
fu! UtlUri_opaque(uri)
    return s:UtlUri_parse(a:uri, 3) . s:UtlUri_parse(a:uri, 5) . s:UtlUri_parse(a:uri, 6)
endfu

"-------------------------------------------------------------------------------
fu! UtlUri_authority(uri)
    if  s:UtlUri_parse(a:uri, 3) == s:UtlUri_parse(a:uri, 4)
	return '<undef>'
    else 
	return s:UtlUri_parse(a:uri, 4)
    endif
endfu

"-------------------------------------------------------------------------------
fu! UtlUri_path(uri)
    return s:UtlUri_parse(a:uri, 5)
endfu

"-------------------------------------------------------------------------------
fu! UtlUri_query(uri)
    if  s:UtlUri_parse(a:uri, 6) == s:UtlUri_parse(a:uri, 7)
	return '<undef>'
    else 
	return s:UtlUri_parse(a:uri, 7)
    endif
endfu

"-------------------------------------------------------------------------------
fu! UtlUri_fragment(uri)
    if  s:UtlUri_parse(a:uri, 8) == s:UtlUri_parse(a:uri, 9)
	return '<undef>'
    else 
	return s:UtlUri_parse(a:uri, 9)
    endif
endfu


"------------------------------------------------------------------------------
" Concatenate uri components into an uri -- opposite of s:UtlUri_parse
" see <URL:http://www.ietf.org/rfc/rfc2396.txt#are recombined>
"
" - it should hold: s:UtlUri_parse + UtlUri_build = exactly the original Uri
"
fu! UtlUri_build(scheme, authority, path, query, fragment)


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
" Build uri from uri without fragment and fragment
"
fu! UtlUri_build_2(absUriRef, fragment)

    let result = ""
    if a:absUriRef != '<undef>'
	let result = result . a:absUriRef
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
" <URL:http://www.ietf.org/rfc/rfc2396.txt#^5.2. Resolving Relative References>
" - `uri' may already be absolute (i.e. has scheme), is then returned
"   unchanged
" - `base' should really be absolute! Otherwise the returned Uri will not be
"   absolute (scheme <undef>). Furthermore `base' should be reasonable (e.g.
"   have an absolute Path in the case of hierarchical Uri)
"
fu! UtlUri_abs(uri, base)

    " see <URL:http://www.ietf.org/rfc/rfc2396.txt#If the scheme component>
    if UtlUri_scheme(a:uri) != '<undef>'
	return a:uri
    endif

    let scheme = UtlUri_scheme(a:base)

    " query, fragment never inherited from base, wether defined or not,
    " see <URL:http://www.ietf.org/rfc/rfc2396.txt#not inherited from the base URI>
    let query = UtlUri_query(a:uri)
    let fragment = UtlUri_fragment(a:uri)

    " see <URL:http://www.ietf.org/rfc/rfc2396.txt#If the authority component is defined>
    let authority = UtlUri_authority(a:uri)
    if authority != '<undef>'
	return UtlUri_build(scheme, authority, UtlUri_path(a:uri), query, fragment)
    endif

    let authority = UtlUri_authority(a:base)

    " see <URL:http://www.ietf.org/rfc/rfc2396.txt#If the path component begins>
    let path = UtlUri_path(a:uri)
    if path[0] == '/'
	return UtlUri_build(scheme, authority, path, query, fragment)
    endif
	
    " see <URL:http://www.ietf.org/rfc/rfc2396.txt#needs to be merged>

    "	    step a)
    let new_path = substitute( UtlUri_path(a:base), '[^/]*$', '', '')
    "	    step b)
    let new_path = new_path . path

    " TODO: implement the missing steps (purge a/b/../c/ into a/c/ etc),
    " CR048#r=_diffbuffs: Implement one special case though: Remove ./ segments
    " since these can trigger a Vim-Bug where two path which specify the same
    " file lead to different buffers, which in turn is a problem for Utl.
    " Have to substitute twice since adjacent ./ segments, e.g. a/././b
    " not substituted else (despite 'g' flag). Another Vim-Bug?
    let new_path = substitute( new_path, '/\./', '/', 'g') 
    let new_path = substitute( new_path, '/\./', '/', 'g') 

    return UtlUri_build(scheme, authority, new_path, query, fragment)


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
" (see <URL:http://www.ietf.org/rfc/rfc2396.txt#2. URI Characters and Escape Sequences>)
"
fu! UtlUri_unescape(esc)
    " perl: $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg
    let esc = a:esc
    let unesc = ''
    while 1
	let ibeg = match(esc, '%[0-9A-Fa-f]\{2}')
	if ibeg == -1
	    return unesc . esc
	endif
	let chr = nr2char( "0x". esc[ibeg+1] . esc[ibeg+2] )
	let unesc = unesc . strpart(esc, 0, ibeg) . chr 
	let esc = strpart(esc, ibeg+3, 9999)

    endwhile
endfu

let &cpo = s:save_cpo
