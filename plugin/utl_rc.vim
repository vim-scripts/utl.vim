" id=utl_rc	    SETUP OF UTL PLUGIN	{
" $Revision: 1.9 $
let utl_rc_vim =    expand("<sfile>")	    " Do not remove this line

" Hints							    id=hints
" 
" - Choose a template variable and uncomment it or create a new one.
"   Then issue the command  :so %  to activate it. You can check whether
"   a variable is defined with the command  :echo g:utl_rc_<name>
"
" - You can change the variables in this file whenever you want, not just when
"   Utl.vim automatically presented you this file.
"
" - You might want to take any variables defined here into your vimrc file.
"   The vimrc is always loaded before any plugin files. That means you can
"   leave this file in whatever state it is (no need to comment settings or
"   so). This rc file is only relevant in case Utl.vim wants to access a
"   variable which is not yet defined.



" id=app_browser----SEE #r=hints AT TOP----------------------------------------
" Setup section `Browser Application' --- typically for executing http:// URLs
"
" Details :
"
" - %u will be replaced with the URL (normalized to an absolute URL plus
"   fragment)
"
" - Surrounding with "" or '' is a bit tricky because of interpretation of \
"   in string variables. So better start from one of the examples.
"
" - You can supply any valid ex command here.
"   For instance you could write a vim function that indirectly calls a browser
"   in case the call gets too complicated. Example:
"	let g:utl_rc_app_browser = "call MyBrowserLaucher('%u')"
"	fu! MyBrowserLaucher(url)
"	    echo "MyBrowserLaucher a:url=" . a:url
"	    exe "!firefox '" . a:url . "' &"
"	endfu
"
"
if has("win32")

    "	Internet Explorer IE
    "	    Windows XP (German)
    " let g:utl_rc_app_browser = 'silent !start C:\Programme\Internet Explorer\iexplore.exe %u' 
    "	    Windows XP
    " let g:utl_rc_app_browser = 'silent !start C:\Program Files\Internet Explorer\iexplore.exe %u' 
    "
    "	Samples for other browsers are welcome!

elseif has("unix")

    "	Konqueror
    "let g:utl_rc_app_browser = "silent !konqueror '%u' &"
    "
    "	Netscape
    "let g:utl_rc_app_browser = "!netscape -remote 'openURL( %u )'"
    "
    "	Lynx Browser.
    "let g:utl_rc_app_browser = "!xterm -e lynx '%u'"
    "
    "	Firefox.
    "	Check if an instance is already running, and if yes use it, else start firefox.
    "	See <URL:http://www.mozilla.org/unix/remote.html> for mozilla/firefox -remote control
    "let g:utl_rc_app_browser = "silent !firefox -remote 'ping()' && firefox -remote 'openURL( %u )' || firefox '%u' &"
    "	Samples for other browsers are welcome!

endif



" id=app_mailclient---------------------------------------------------------------------
" Setup section `Mail Client Application' --- typically for executing name@host.xy URLs
"
" Details :
" - %u will be replaced with the mailto URL
"
if has("win32")

    " Outlook
    "let g:utl_rc_app_mailer = 'silent !start C:\Programme\Microsoft Office\Office11\OUTLOOK.EXE /c ipm.note /m %u'
    "let g:utl_rc_app_mailer = 'silent !start C:\Program Files\Microsoft Office\Office10\OUTLOOK.exe /c ipm.note /m %u' 

elseif has('unix')

    "let g:utl_rc_app_mailer = "!xterm -e mutt '%u'" 
    "let g:utl_rc_app_mailer = "silent !kmail '%u' &"

endif


" id=mediaTypeHandlers---------------------------------------------------------- 
" Setup of handlers for media types which you don't want to be displayed by Vim.
"
" Allowed conversion specifiers:
"
" %p - Replaced by full path to file or directory
"
" %P - Replaced by full path to file or directory, where the path components
"      are separated with backslashes (most Windows programs need this).
"      Note that full path might also contain a drive letter.
"
" Details :
" - The "" around the %P is needed to support file names containing blanks
" - Remove the :silent when you are testing with a new string to see what's
"   going on (see <URL:vimhelp::silent> for infos on the :silent command).
"   Perhaps you like :silent also for production (I don't).
" - NOTE: You can supply any command here, i.e. does not need to be a shell
"   command that calls an external program (some cmdline special treatment
"   though, see <URL:utl.vim#r=esccmd>)
" - You can introduce new media types to not handle a certain media type
"   by Vim (e.g. display it as text in Vim window). Just make sure that the
"   new media type is also supported here: <URL:utl.vim#r=thl_checkmtype>
" - Use the pseudo handler 'VIM' if you like the media type be displayed by
"   by Vim. This yields the same result as if the media type is not defined,
"   see last item.
" - I introduced the has(win32/unix) distinction to enable a plattform
"   independant utl_rc.vim file. You may delete these lines if / elseif /
"   endif - only the definition of the g:utl_mt_xxx variables is important.

if has("win32")

    "let g:utl_mt_audio_mpeg	  = -> media player
    "let g:utl_mt_application_excel = ':silent !start C:\Program Files\Microsoft Office\Office10\EXCEL.EXE "%P"'
    "let g:utl_mt_application_msword = ':silent !start C:\Program Files\Microsoft Office\Office10\WINWORD.EXE "%P"'
    "let g:utl_mt_application_powerpoint = ':silent !start C:\Program Files\Microsoft Office\Office10\POWERPNT.EXE "%P"'
    "let g:utl_mt_application_pdf	  = ':silent !start C:\Program Files\Adobe\Acrobat 5.0\Reader\AcroRd32.exe "%P"'
    "let g:utl_mt_application_rtf	  = ':silent !start C:\Program Files\Windows NT\Accessories\wordpad.exe "%P"'
    "   g:utl_mt_text_html =      'VIM'
    "let g:utl_mt_text_html = 'silent !start C:\Program Files\Internet Explorer\iexplore.exe %P' 
    "let g:utl_mt_application_zip	  = ':!start C:\winnt\explorer.exe "%P"'
    "
    "--- Quite some alternatives for displaying directories (id=mt_dir):
    "let g:utl_mt_text_directory = 'VIM'   " Vim's file explorer (id=mt_dir_vim)
    "let g:utl_mt_text_directory = ':!start C:\winnt\explorer.exe "%P"'  " Windows Explorer (id=mt_dir_win)
    "let g:utl_mt_text_directory = ':!start cmd /K cd /D "%P"'	" Dos box

elseif has("unix")

    " Linux/KDE
    "let g:utl_mt_application_pdf =  ':silent !acroread %p &'
    "
    "	Seem to need indirect call via xterm, otherwise no way to
    "	stop at every page
    "let g:utl_mt_application_postscript = ':!xterm -e gs %p &'
    "
    "let g:utl_mt_audio_mpeg =	    ':silent !xmms %p &'
    "
    "let g:utl_mt_application_msword = ... Open Office
    "
    "let g:utl_mt_text_directory = ':silent !konqueror %p &'
    "let g:utl_mt_text_directory = 'VIM'

    "let g:utl_mt_text_html = ':silent !konqueror %p &'

    "let g:utl_mt_image_jpeg = ':!xnview %p &'

endif

" end of Utl setup }
