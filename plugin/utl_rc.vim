" BEGIN OF UTL PLUGIN CONFIGURATION 				     id=utl_rc [
"   vim: fdm=marker

let utl__file_rc =    expand("<sfile>")	    " Do not remove this line

" Hints							    id=hints
" 
" - Choose a template variable and uncomment it or create a new one.
"   Then issue the command  :so %  to activate it. You can check whether
"   a variable is defined with the command   :let utl_cfg_<name>
"
" - You can change the variables in this file whenever you want, not just when
"   Utl.vim automatically presented you this file.
"
" - You might want to take any variables defined here into your vimrc file.
"   Since vimrc is always loaded before any plugin files you should comment
"   all variables to avoid overwriting of your vimrc settings.
"   (Deletion of utl_rc.vim is also possible. In this case you should
"   preserve the Utl link targets id=xxx plus line :let utl__file_rc
"   above (i.e. also take over into you vimrc file).)


" id=schemeHandlers------------------------------------------------------------[


" id=schemeHandlerHttp---------------------------------------------------------[
"
" Allowed conversion specifiers are: 
" %u - URL	    (without fragment, e.g. 'http://www.vim.org/download.php'
" %f - fragment	    (what comes after the '#', if any)
" %d - display mode (e.g. 'edit', 'tabedit', 'split' etc. Probably only relevant
"		    if downloaded document handled in Vim)


    " [id=utl_cfg_hdl_scm_http]
    "
    " Hints:
    " 1. If  g:utl_cfg_hdl_mt_generic  is defined then you can probably
    "   construct utl_cfg_hdl_scm_http by just replacing %u -> %p (Unix) or %u
    "   -> %P (Windows).
    " 2. Instead of directly defining  g:utl_cfg_hdl_scm_http  it is recommended
    "   to define  g:utl_cfg_hdl_scm_http_system . Doing so enables the dynamic
    "   handler switching:
    " 3. Suggestion for mapping for dynamic switch between handlers [id=map_http]
    "   :map <Leader>uhs :let g:utl_cfg_hdl_scm_http=g:utl_cfg_hdl_scm_http_system<cr>
    "   :map <Leader>uhw :let g:utl_cfg_hdl_scm_http=g:utl_cfg_hdl_scm_http__wget<cr>


    " [id=utl_cfg_hdl_scm_http_system] {
    "	    Definition of your system's standard web handler, e.g. Firefox.
    "	    Either directly (e.g. Firefox), or indirectly ("start" command
    "	    in Windows).
    "	    Note: Needs not necessarily be the system's standard handler.
    "	    Can be anything but should be seen in contrast to
    "	    utl_cfg_hdl_scm_http__wget below
    "
    if !exists("g:utl_cfg_hdl_scm_http_system")

	if has("win32")
	    let g:utl_cfg_hdl_scm_http_system = 'silent !cmd /q /c start "dummy title" "%u"'
	    "let g:utl_cfg_hdl_scm_http_system = 'silent !start C:\Program Files\Internet Explorer\iexplore.exe %u#%f' 
	    "let g:utl_cfg_hdl_scm_http_system = 'silent !start C:\Program Files\Mozilla Firefox\firefox.exe %u#%f'

	elseif has("unix")

	    " TODO: Standard Handler for Unixes that can be shipped
	    "	    preconfigured with next utl.vim release
	    "	    Probably to distinguish different Unix/Linux flavors.
	    "
	    "	    Proposed for Ubuntu/Debian by Jeremy Cantrell
	    "	    to use xdg-open program
	    "	    'silent !xdg-open %u'  <- does this work?
	    "
	    " 2nd best solution: explicitly configured browser:
	    "
	    "	Konqueror
	    "let g:utl_cfg_hdl_scm_http_system = "silent !konqueror '%u#%f' &"
	    "
	    "	Lynx Browser.
	    "let g:utl_cfg_hdl_scm_http_system = "!xterm -e lynx '%u#%f'"
	    "
	    "	Firefox
	    "	Check if an instance is already running, and if yes use it, else start firefox.
	    "	See <URL:http://www.mozilla.org/unix/remote.html> for mozilla/firefox -remote control
	    "let g:utl_cfg_hdl_scm_http_system = "silent !firefox -remote 'ping()' && firefox -remote 'openURL( %u )' || firefox '%u#%f' &"

	endif
	" else if MacOS
	" ??
	"let g:utl_cfg_hdl_scm_http_system = "silent !open -a Safari '%u#%f'"
	"
	"}

    endif

    if !exists("g:utl_cfg_hdl_scm_http")
	if exists("g:utl_cfg_hdl_scm_http_system")
	    let g:utl_cfg_hdl_scm_http=g:utl_cfg_hdl_scm_http_system
	endif
    endif


    " [id=utl_cfg_hdl_scm_http__wget]
    let g:utl_cfg_hdl_scm_http__wget="call Utl_if_hdl_scm_http__wget('%u')"

    " Platform independent
    "	Delegate to netrw.vim	    [id=http_netrw]
    "let g:utl_cfg_hdl_scm_http="silent %d %u"
    "

"]

" id=schemeHandlerScp--------------------------------------------------------------[
" Allowed conversion specifiers are: 
" %u - URL	    (without fragment, e.g. 'scp://www.someServer.de/someFile.txt'
" %f - fragment	    (what comes after the '#', if any)
" %d - display mode (e.g. 'edit', 'tabedit', 'split' etc. Probably only relevant
"		    if downloaded document handled in Vim)

    " [id=utl_cfg_hdl_scm_scp]
    " Delegate to netrw.vim.  TODO: Should set utl__hdl_scm_ret_list to buffer name
    " NOTE: On Windows I have set  g:netrw_scp_cmd="pscp -q" (pscp comes with
    "	    the  putty  tool), see also <url:vimscript:NetrwSettings>
    if !exists("g:utl_cfg_hdl_scm_scp")
	    let g:utl_cfg_hdl_scm_scp = "silent %d %u"
    endif

"]

" id=schemeHandlerMailto-----------------------------------------------------------[
" Allowed conversion specifiers are: 
" %u - will be replaced with the mailto URL
"
    if !exists("g:utl_cfg_hdl_scm_mailto")

	" [id=utl_cfg_hdl_scm_mailto] {
	if has("win32")
	    let g:utl_cfg_hdl_scm_mailto = 'silent !cmd /q /c start "dummy title" "%u"'
	endif
	" Samples:
	" Windows
	"	 Outlook
	"let g:utl_cfg_hdl_scm_mailto = 'silent !start C:\Programme\Microsoft Office\Office11\OUTLOOK.EXE /c ipm.note /m %u'
	"let g:utl_cfg_hdl_scm_mailto = 'silent !start C:\Program Files\Microsoft Office\Office10\OUTLOOK.exe /c ipm.note /m %u' 
	"
	" Unix
	"let g:utl_cfg_hdl_scm_mailto = "!xterm -e mutt '%u'" 
	"let g:utl_cfg_hdl_scm_mailto = "silent !kmail '%u' &"
	"}

    endif


" id=schemeHandlerMail---------------------------------------------------------[
" Allowed conversion specifiers are: 
" %a - main folder	    Example:
" %p - folder path	    Given the URL
" %d - date		      <url:mail://myfolder/Inbox?date=12.04.2008 15:04&from=foo&subject=bar>
" %f - from		    the specifiers will be converted as 
" %s - subject		      %a=myfolder, %p=Inbox, %d=12.04.2008 15:04, %f=foo, %s=bar

    " Windows
    "	Outlook						[id=utl_cfg_hdl_scm_mail__outlook]
    if has("win32")
	let g:utl_cfg_hdl_scm_mail__outlook = "call Utl_if_hdl_scm_mail__outlook('%a','%p','%d','%f','%s')"
    endif

    " [id=utl_cfg_hdl_scm_mail] {
    if !exists("g:utl_cfg_hdl_scm_mail")
	"let g:utl_cfg_hdl_scm_mail=g:utl_cfg_hdl_scm_mail__outlook
    endif
    "}

"]

" id=mediaTypeHandlers---------------------------------------------------------[
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
" %f - Replaced by fragment if given in URL, else replaced by empty string.
"
" Details :
" - The variable name is g:utl_cfg_hdl_mt_<media type>, where the characters / . + -
"   which can appear in media types are mapped to _ to make a valid variable
"   name, e.g. Vim variable for media type 'video/x-msvideo' is
"   'g:utl_cfg_hdl_mt_video_x_msvideo'
" - The "" around the %P is needed to support file names containing blanks
" - Remove the :silent when you are testing with a new string to see what's
"   going on (see <URL:vimhelp::silent> for infos on the :silent command).
"   Perhaps you like :silent also for production (I don't).
" - NOTE: You can supply any command here, i.e. does not need to be a shell
"   command that calls an external program (some cmdline special treatment
"   though, see <URL:utl.vim#r=esccmd>)
" - You can introduce new media types to not handle a certain media type
"   by Vim (e.g. display it as text in Vim window). Just make sure that the
"   new media type is also supported at this place:
"   <URL:utl.vim#r=utl_checkmtype>
" - Use the pseudo handler 'VIM' if you like the media type be displayed by
"   by Vim. This yields the same result as if the media type is not defined,
"   see last item.


    " [id=utl_cfg_hdl_mt_generic] {
    "	    You can either define the generic variable or a variable
    "	    for the specific media type, see #r=mediaTypeHandlersSpecific
    if !exists("g:utl_cfg_hdl_mt_generic")
	if has("win32")
	    let g:utl_cfg_hdl_mt_generic = 'silent !cmd /q /c start "dummy title" "%P"'
	elseif has("unix")
	    if $WINDOWMANAGER =~? 'kde'
		let g:utl_cfg_hdl_mt_generic = 'silent !konqueror "%p" &'
	    endif
	    " ? Candidate for Debian/Ubuntu: 'silent !xdg-open %u'
	endif
    endif
    "}
    

    " [id=mediaTypeHandlersSpecific] {

    "if !exists("g:utl_cfg_hdl_mt_application_excel")
    "	     let g:utl_cfg_hdl_mt_application_excel = ':silent !start C:\Program Files\Microsoft Office\Office10\EXCEL.EXE "%P"'
    "endif

    "if !exists("g:utl_cfg_hdl_mt_application_msmsg")
    "	     let g:utl_cfg_hdl_mt_application_msmsg = ':silent !start C:\Program Files\Microsoft Office\Office10\OUTLOOK.EXE -f "%P"'
    "endif

    "if !exists("g:utl_cfg_hdl_mt_application_powerpoint")
    "        let g:utl_cfg_hdl_mt_application_powerpoint = ':silent !start C:\Program Files\Microsoft Office\Office10\POWERPNT.EXE "%P"'
    "endif

    "if !exists("g:utl_cfg_hdl_mt_application_rtf")
    "	     let g:utl_cfg_hdl_mt_application_rtf = ':silent !start C:\Program Files\Windows NT\Accessories\wordpad.exe "%P"'
    "endif
    
    "if !exists("g:utl_cfg_hdl_mt_text_html")
    "	     let g:utl_cfg_hdl_mt_text_html = 'VIM'
    "		Windows
    "	     let g:utl_cfg_hdl_mt_text_html = 'silent !start C:\Program Files\Internet Explorer\iexplore.exe %P' 
    "		KDE
    "	     let g:utl_cfg_hdl_mt_text_html = ':silent !konqueror %p#%f &'
    "endif


    "if !exists("g:utl_cfg_hdl_mt_application_zip")
    "	     let g:utl_cfg_hdl_mt_application_zip = ':!start C:\winnt\explorer.exe "%P"'
    "endif

    "if !exists("g:utl_cfg_hdl_mt_video_x_msvideo")
    "	     let g:utl_cfg_hdl_mt_video_x_msvideo = ':silent !start C:\Program Files\VideoLAN\VLC\vlc.exe "%P"'
    "endif


    "--- Some alternatives for displaying directories	[id=utl_cfg_hdl_mt_text_directory] {
    if has("win32")
	let g:utl_cfg_hdl_mt_text_directory__cmd = ':!start cmd /K cd /D "%P"'   " Dos box
    endif
    let g:utl_cfg_hdl_mt_text_directory__vim = 'VIM'   " Vim builtin file explorer

    if !exists("g:utl_cfg_hdl_mt_text_directory")
	    let g:utl_cfg_hdl_mt_text_directory=utl_cfg_hdl_mt_text_directory__vim
	    "
	    "	KDE
	    "let g:utl_cfg_hdl_mt_text_directory = ':silent !konqueror %p &'
    endif
    " Suggestion for mappings for dynamic switch between handlers [id=map_directory]
    ":map <Leader>udg :let g:utl_cfg_hdl_mt_text_directory=g:utl_cfg_hdl_mt_generic<cr>
    ":map <Leader>udv :let g:utl_cfg_hdl_mt_text_directory=g:utl_cfg_hdl_mt_text_directory__vim<cr>
    ":map <Leader>udc :let g:utl_cfg_hdl_mt_text_directory=g:utl_cfg_hdl_mt_text_directory__cmd<cr>
    "
    "}


    "						[id=utl_cfg_hdl_mt_application_pdf__acrobat] {
    "let g:utl_cfg_hdl_mt_application_pdf__acrobat="call Utl_if_hdl_mt_application_pdf_acrobat('%P', '%f')"
    "if !exists("g:utl_cfg_hdl_mt_application_pdf")
    "	     let g:utl_cfg_hdl_mt_application_pdf = g:utl_cfg_hdl_mt_application_pdf__acrobat
    "
    "		Linux/KDE
    "	     let g:utl_cfg_hdl_mt_application_pdf = ':silent !acroread %p &'
    "endif
    "}


    "						[id=utl_cfg_hdl_mt_application_msword__word] {
    "let g:utl_cfg_hdl_mt_application_msword__word = "call Utl_if_hdl_mt_application_msword__word('%P','%f')"
    "if !exists("g:utl_cfg_hdl_mt_application_msword")
    "        let g:utl_cfg_hdl_mt_application_msword = g:utl_cfg_hdl_mt_application_msword__word
    "		Linux/Unix
    "	     let g:utl_cfg_hdl_mt_application_msword = ... Open Office
    "endif
    "}


    "if !exists("g:utl_cfg_hdl_mt_application_postscript")
    "		Seem to need indirect call via xterm, otherwise no way to
    "		stop at each page
    "	     let g:utl_cfg_hdl_mt_application_postscript = ':!xterm -e gs %p &'
    "endif

    "if !exists("g:utl_cfg_hdl_mt_audio_mpeg")
    "	     let g:utl_cfg_hdl_mt_audio_mpeg =	    ':silent !xmms %p &'
    "endif

    "if !exists("g:utl_cfg_hdl_mt_image_jpeg")
    "	     let g:utl_cfg_hdl_mt_image_jpeg = ':!xnview %p &'
    "endif

    "}

"]

" Utl interface variables				      " id=utl_drivers [

" id=utl_if_hdl_scm_http_wget_setup--------------------------------------------[
"
" To make Wget work you need a wget executable in the PATH.
" Windows : Wget not standard. Download for example from
" <url:http://users.ugent.be/~bpuype/wget/#download>
" and put it into to c:\windows\system32
" Unix : Should work under Unix out of the box since wget standard!?
"
" ]


" id=utl_if_hdl_scm_mail__outlook_setup----------------------------------------[
"
" To make Outlook work you for the mail:// schemes you need the VBS OLE
" Automation file:
"
" 1. Adapt the VBS source code to your locale by editing the file utl.vim at
"    the position: <url:./utl.vim#r=received> and then  :write  the file (utl.vim).
"
" 2. Execute the following link to (re-)create the VBS file by cutting it
"    out from utl.vim:
"
"    <url:vimscript:call Utl_utilCopyExtract(g:utl__file, g:utl__file_if_hdl_scm__outlook, '=== FILE_OUTLOOK_VBS' )>
"
" ]


" id=Utl_if_hdl_mt_application_pdf_acrobat_setup-------------------------------[
"
" To make acrobat work with fragments you need to provide the variable
" g:utl_cfg_hdl_mt_application_pdf_acrobat_exe_path. 
"
" Modify and uncomment one of the samples below, then do  :so %
" Windows:
" Normally you should get the path by executing in a dos box:
" cmd> ftype acroexch.document
" Here are two samples:
"     let g:utl_cfg_hdl_mt_application_pdf_acrobat_exe_path = "C:\Program Files\Adobe\Reader 8.0\Reader\AcroRd32.exe"
"     let g:utl_cfg_hdl_mt_application_pdf_acrobat_exe_path = 'C:\Programme\Adobe\Reader 8.0\Reader\AcroRd32.exe'
" Full path not needed if Acrobat Reader in path
" Unix: 
" Probably Acrobat Reader is in the path, with program's name `acroread'.
" But most certainly the command line options used below will not fit,
" see <url:#r=ar_switches>, and have to be fixed. Please send me proper
" setup for Linux, Solaris etc. I'm also interested in xpdf instead 
" of Acrobat Reader (function Utl_if_hdl_mt_application_pdf_xpdf).
"   ?? let g:utl_cfg_hdl_mt_application_pdf_acrobat_exe_path = "acroread - ?? "
"
" ]


" id=Utl_if_hdl_mt_application_msword__word_setup------------------------------[
"
" To make MSWord support fragments you need:
"
" 1. Create the VBS OLE Automation file by executing this link:
"    <url:vimscript:call Utl_utilCopyExtract(g:utl__file, g:utl__file_if_hdl_mt_application_msword__word, '=== FILE_WORD_VBS' )>
"    (This will (re-)create that file by cutting it out from the bottom of this file.)
"
" 2. Provide the variable g:utl_cfg_hdl_mt_application_msword__word_exe_path. 
"    Modify and uncomment one of the samples below, then do  :so %
"    Windows:
"    Normally you should get the path by executing in a dos box:
"    cmd> ftype Word.Document.8
"    Here are two samples:
"    let g:utl_cfg_hdl_mt_application_msword__word_exe_path = 'C:\Program Files\Microsoft Office\OFFICE11\WINWORD.EXE'
"    let g:utl_cfg_hdl_mt_application_msword__word_exe_path = 'C:\Programme\Microsoft Office\OFFICE11\WINWORD.EXE'

" ]
" ]


" Utl Options		id=_utl_options [

"id=utl_opt_verbose------------------------------------------------------------[
"   Option utl_opt_verbose switches on tracing. This is useful to figure out
"   what's going on, to learn about Utl or to see why things don't work as
"   expected.
"   
"let utl_opt_verbose=0	    " Tracing off (default)
"let utl_opt_verbose=1	    " Tracing on 

" ]

"id=utl_opt_highlight_urls-----------------------------------------------------[
"   Option utl_opt_highlight_urls controls if URLs are highlighted or not.
"   Note that only embedded URLs like <url:http://www.vim.org> are highlighted.
"   
"   Note: Change of the value will only take effect a) after you restart your
"   Vim session or b) by :call Utl_setHighl() and subsequent reedit (:e) of the
"   current file. Perform the latter by simply executing this URL:
"   <url:vimscript:call Utl_setHighl()|:e>

"let utl_opt_highlight_urls='yes'   " Highlighting on (default)
"let utl_opt_highlight_urls='no'    " Highlighting off

"]
"]

" END OF UTL PLUGIN CONFIGURATION FILE ]

