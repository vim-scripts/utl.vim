thlnk_README.txt --- URL based hyperlinking for plain text
		     Version thlnk-1.2

0. CONTENTS
===========
1. WHAT IS THLNK.VIM
2. INSTALLATION
3. CHANGES
4. LICENCE
5. THANKS
			
1. WHAT IS THLNK.VIM
====================
Thlnk.vim enables URL based hyperlinking for plain text.

- Thlnk stands for "plain text hyperlinking".
- Thlnk.vim is a plugin for the Vim text editor (see http://www.vim.org)
- It brings the benefits of URL-based hyperlinking to the realm of plain text.
- It is the implementation of a general approach for better and more
  powerful text editing and browsing. Its about text culture.
  That's why Thlnk also is a project.

It requires the Vim text editor as a prerequisite und runs where Vim runs.

Thlnk.vim is free software. See section LICENCE below.

For installation see section INSTALLATION below.

Thlnk.vim homepage: //www.bf-consulting.de/thlnk/vim


2. INSTALLATION
===============

2.1 Prerequisites
-----------------
For basic usage you just need the Vim editor, Version 6 (tested with 6.0, 6.1)

OPTIONAL:
  For internet usage the wget tool is recommended:
  ∞ It's really optional: ThlnkVim runs anyway, http/ftp hyperlinks just
    will not work at runtime
  ∞ GNU Wget is a free network utility to retrieve files from the Internet
    using HTTP and FTP, the two most widely used Internet protocols.
    It works non-interactively.
  ∞ It is available from http://www.gnu.org/software/wget/wget.html


2.2. Installation Instructions
------------------------------

1.  copy the thlnk-xxx.zip file to your 
    $HOME/.vim  (unix) 
    or 
    $HOME\vimfiles  (windows) 
    directory 

    (if something doesn't work or if you would like some explanations, 
     see :help add-global-plugin) 

2.  unzip thlnk-xxx.zip at that location. This should create the files: 

    thlnk_README.txt (this file)
    plugin/ 
	    thlnk.vim 
	    thlnkarr.vim 
	    thlnkscm.vim 
	    thlnkuri.vim 
    doc/ 
	    thlnkref.txt 
	    thlnkusr.txt 

3.  Restart vim and execute 

    :helptags $HOME/.vim/doc (unix) 
    or 
    :helptags $HOME\vimfiles\doc (windows) 

    (this step should rebuild the tags file in the doc/ directory. 
     If something doesn't work or if you would like some explanations, 
     see ":help add-local-help") 

4.  Type: 
	:help thlnk 
    to get started and run some live examples


3. CHANGES
==========
Changes and Bug fixes

14.06.02 thlnk.vim-1.2 released
    - Enhanced documentation: new sections "Tips and Common Pitfails",
      "mapping and commands" ...
    - Enhanced warning and error messages.
    - Bug fix. stb.
      {Visual}\gu didn't work on Windows gVim without guioptions+=a
    - Bug fix. Reported by "Klaus Horsten" <horsten@gmx.at>.
      With 'wrapscan' unset, fragment addressing could fail
    - Bug fix. Reported by "Patrik Nyman" <patrik.nyman@orient.su.se>.
      Non existing http: or rcp: URLs made thlnk list the current
      file instead of an error message

07.05.02 thlnk.vim-1.1 released
    Is a plugin for Vim6 now:
    - Mappings changed (\gu instead of ,x)
    - Filenames and function names changed.
    - Docs in Vim online help format now. Heavily revised.
    Other Changes:
    - `URL:' as preferred embedding. `LNK:' still works though:
      Text written for use with thlnk-1.0 works with thlnk-1.1.
    - The default mapping (\gu) now :edit's instead of :view

04.05.02 Bug fix (stb)
    idref search relayed on 'iskeyword' setting. End of word now
    detected with \w\@! instead \>

02.05.02 Bug fix (bug reported by Klaus Horsten <horsten@gmx.at>)
    Argument for wget has to masked only for Unix with '...'

20.03.02 Bug fix (stb)
    determination of subtype 'png' was wrong

20.02.02 Bug fix (bug reported by  Ward Fuller <wfuller@SeeBeyond.com>)
    Regexp in Uri_parse() was broken due to an incompatible change
    in Vim6

26.04.01 ThlnkVim 1.0 released


4. LICENCE
==========
LICENCE conditions and other legal aspects for thlnk.vim-1.1

Author: Stefan Bittner <stb@bf-consulting.de>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

See full text of GPL under http://www.gnu.org/copyleft/gpl.html

5. THANKS
=========

Thanks to my partner Wolfgang Fleig <wfg@bf-consulting.de>
for his help, co-authoring, dialectical antithesis and sponsoring.
Thanks to Ines Paegert for her impulses.
Thanks to Bram Moolenaar <Bram@moolenaar.net> for the Vim editor.

Thanks to the people who contributed with questions, bug reports,
suggestions, patches, discussion or just motivation:

    Klaus Horsten <horsten@gmx.at>.
    Patrik Nyman <patrik.nyman@orient.su.se>
    Engelhard Heﬂ <Engelhard.Hess@artofbits.de>
    Grant Bowman <grantbow@grantbow.com>
    Ward Fuller <wfuller@SeeBeyond.com>
    Mark S. Thomas <Mark.Thomas@SWFWMD.STATE.FL.US>



