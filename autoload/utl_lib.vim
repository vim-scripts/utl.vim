" ------------------------------------------------------------------------------
" File:		autoload/utl_lib.vim -- Finish installation and
"		data migration support
"			        Part of the Utl plugin, see ../plugin/utl.vim
" Author:	Stefan Bittner <stb@bf-consulting.de>
" Licence:	This program is free software; you can redistribute it and/or
"		modify it under the terms of the GNU General Public License.
"		See http://www.gnu.org/copyleft/gpl.txt
" Version:	utl 3.0a
" ------------------------------------------------------------------------------



"-------------------------------------------------------------------------------
" Intended to finish installation after Utl 3.0a files have been installed
" by UseVimball. Will automatically be called after UseVimball in
" utl_3_0a.vba. But can be called at any later time or can be called multiple
" times. As an autoload function it can be called directly from within
" :so utl_3_0a.vba without starting a new Vim instance.
"
" - Deletes any existing obsolete files: plugin/utl_arr.vim, doc/utl_ref.txt
" - Data migration: Checks for utl_2.0 configuration variables and print
"   instructions to user how to migrate them.
"
" Note: Utl 3.0a installation saved file plugin/utl_rc.vim to
" plugin/utl_old_rc.vim prior to Utl 3.0a installation (Preinstall). So the
" old variables remain and will be visible in new Vim instance.
"
function! utl_lib#Postinstall()

    echo "----------------------------------------------------------------------"
    echo "Info: Start of Utl 3.0a post installation."
    echo "      This will handle relicts of any previously installed Utl version"
    echo "\n"

    if ! exists("g:utl_vim")
	echo "Info: No previously installed Utl version found (variable g:utl_vim)"
	echo "      does not exist). Nothing to do at all."
	if exists("g:utl_rc_vim") 
	    echo "\n"
	    echo "Warning: But file  ".g:utl_rc_vim." still exists"
	    echo "         You should remove it from the plugin directory"
	endif
	echo "\n"
	echo "      To start with Utl open a new  Vim, type:"
	echo "        :help utl"
	echo "      and follow the live examples"
	echo "\n"
	echo "      End of Utl 3.0a post installation"
	echo "----------------------------------------------------------------------\n"
	
	return
    endif

    "--- 2. Delete obsolete Utl 2.0 files
    if exists("g:utl_arr_vim") 
        if filereadable(g:utl_arr_vim)
	    if delete(g:utl_arr_vim)==0
		echo "Info: obsolete Utl 2.0 file ".g:utl_arr_vim." deleted successfully"
	    else
		echohl WarningMsg
		echo "Warning: Could not delete obsolete Utl 2.0 file".g:utl_arr_vim."."
		echo "         This does not affect proper function but you might want to"
		echo "         delete it manually in order to cleanup your plugin directory"
		echohl None
	    endif
	else
	    echo "Warning: no obsolete Utl 2.0 file ".g:utl_arr_vim." found"
	endif
    else
	echo "Warning: variable g:utl_arr_vim not found. Inconsistent installation"
    endif

    if exists("g:utl_vim")   " no variable for utl_ref, so start from utl.vim
	let utl_ref_txt = fnamemodify(g:utl_vim, ":p:h:h") . "/doc/utl_ref.txt"
	if filereadable(utl_ref_txt)
	    if delete(utl_ref_txt)==0
		echo "Info: obsolete Utl 2.0 file ".utl_ref_txt." deleted successfully"
	    else
		echohl WarningMsg
		echo "Warning: Could not delete obsolete Utl 2.0 file ".utl_ref_txt
		echo "         but you might want to delete it manually to avoid garbage"
		echo "         docs / help tags"
		echohl None
	    endif
	else
	    echo "Warning: no obsolete Utl 2.0 file ".utl_ref_txt." found"
	endif
    endif

    "--- 3. Check for Utl V2.0 variables
    "	 The user might want to migrate these to Utl 2.1 variable names
    "	 g:utl_rc_xxx -> g:utl_cfg_xxx
    "	 g:utl_config_highl_urls -> g:utl_opt_highlight_urls
    "	 g:utl_mt_xxx -> utl_cfg_mth__xxx
    let varMap = {}

    if exists("g:utl_rc_app_mailer")
	let varMap['g:utl_rc_app_mailer'] = 'g:utl_cfg_hdl_scm_mailto'
    endif

    if exists("g:utl_rc_app_browser")
	let varMap['g:utl_rc_app_browser'] = 'g:utl_cfg_hdl_scm_http'
    endif

    if exists("g:utl_config_highl")
	let varMap['g:utl_config_highl'] = 'g:utl_opt_highlight_urls'
    endif

    " All utl_mt_ variables. Get them by capturing the ':let' output
    redir => redirBuf
    silent let
    redir END

    let line=split(redirBuf)
    let prefix='utl_mt_'
    for item in line
	if item=~ '^'.prefix
	    let suffix = strpart(item, strlen(prefix))
	    let newName = 'utl_cfg_hdl_mt_'.suffix

	    let varMap['utl_mt_'.suffix] = newName

	endif
    endfor

    if ! empty(varMap)
	echo "\n"
	echohl WarningMsg
	echo "Warning: The following Vim variable(s) from a previously installed"
	echo "         Utl version have been detected. You might  a) want to rename"
	echo "         them to the new Utl version 3.0a names as given in the table below."
	echo "         Or you might  b) want just delete the old variables."
	echo "\n"
	echo "         If you don't care, then choose b), i.e. just remove those variables"
	echo "         from your vimrc or delete utl_rc_old.vim (which possibly has been"
	echo "         created during preinstall (see second line in utl_3_0a.vba)). This is"
	echo "         not a bad choice since Utl 3.0 provides a generic handler variable"
	echo "         which discharges you from maintaining specific handler variables for"
	echo "         each file type."
	echohl None
    else
	echo "Info: No variables of a previous Utl installation detected."
	echo "      So nothing no further instructions for moving them away needed."
    endif
    for key in sort(keys(varMap))
	echo printf("    %-40s -> %s", key, varMap[key])
    endfor
    if ! empty(varMap)
	echo "\n"
    endif

    echo "\n"
    echo "Info: You can perform post installation again anytime with the command:"
    echo "        :call utl_lib#Postinstall()\n"
    echo "      You can also just install again by :source'ing Utl_3_0a.vba"
    echo "\n"
    echo "      You should move the possibly created file plugin/utl_old_rc.vim out of"
    echo "      the way when done with data migration. I.e. delete it or rename it to"
    echo "      other file name extension than .vim or move it away from the plugin"
    echo "      directory."
    echo "\n"
    echo "      To start with Utl open a new Vim and type:"
    echo "        :help utl"
    echo "\n"
    echo "Info: End of Utl 3.0a post installation"
    echo "----------------------------------------------------------------------\n"
    

endfunction
