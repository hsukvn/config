" projloader.vim
" Brief: load tag and path by project
" Version: 0.1
" Date: 2012.02.04 19:14
" Author: thlu <thlu@synology.com>

if exists("g:ProjLoaderInited")
	finish
endif

function s:DocOptions()
" OPTIONS:
"
" g:ProjLocalConfigName	(string)
" 	When we get b:ProjRoot, we will source the file
" 	b:ProjRoot.'/'.g:ProjLocalConfigName. default=vimrc
"
" b:ProjRoot.'/'.g:ProjLocalConfigName (vim script)
" 	this file will be source before initialize any other options
"
" g:ProjPlatform (string)
" 	This is the default platform to set path. For example, load headers
" 	in [platform path]/usr/include. default=$SYNO_CURR_PLATFORM
"
" g:ProjBasePath (string)
" 	When we can not get source path by git.
" 	default=/synosrc/curr/ds.base
"
" g:ProjFileIgnores (array)
" 	An array of file name filter to ignore.
"
" g:ProjDependentLevel (int)
" 	depth to load dependency project tags.
endfunc
function s:DocDependency()
" DEPENDENCY:
"
" git
" 	Only git repository is supported. We use git command to get the
" 	project root path (b:ProjRoot)
"
" syno.common
" 	I use this script to guess b:ProjBranch, b:ProjBasePath,
" 	b:ProjChrootPath
endfunc
function s:DocBufferVariables()
" Buffer Variables:
"
" These variables are loaded when buffer opend
"
" b:ProjRoot
" 	root path for this project
"
" b:ProjName
" 	project name (also name for tag file)
"
" b:ProjBranch
" 	branch name of syno build env
"
endfunc

let g:ProjLoaderDebug = 1
let g:ProjLoaderLog = []
function! s:Log(msg)
	if g:ProjLoaderDebug
		call add(g:ProjLoaderLog, a:msg)
	endif
endfunc

function! s:LoadTag(file)
	if 0 != strlen(a:file) && filereadable(a:file)
		execute ':setlocal tags+='.a:file
		return 1
	else
		return 0
	endif
endfunc
function! s:LoadPath(dir)
	if 0 != strlen(a:dir) && isdirectory(a:dir)
		execute ':setlocal path+='.a:dir
		return 1
	else
		return 0
	endif
endfunc

function s:InitGlobalDefault()
	if ! exists("g:ProjLocalConfigName")
		let g:ProjLocalConfigName = 'vimrc'
	endif
	if ! exists("g:ProjPlatform")
		if 0 != strlen($SYNO_CURR_PLATFORM)
			let g:ProjPlatform = $SYNO_CURR_PLATFORM
		else
			let g:ProjPlatform = '6281'
		endif
	endif
	if ! exists("g:ProjBasePath")
		if getcwd() =~ '/synosrc/package/source/'
			let g:ProjBasePath = '/synosrc/package'
		else
			let g:ProjBasePath = '/synosrc/curr/ds.base'
		endif
	endif

	if ! exists("g:ProjFileIgnores")
		let g:ProjFileIgnores = [g:ProjLocalConfigName, '.vimrc']
	endif
	if ! exists("g:ProjLoaderAutocmd")
		let g:ProjLoaderAutocmd = 1
	endif
	if ! exists("g:ProjDependentLevel")
		let g:ProjDependentLevel = 2
	endif
endfunc
call s:InitGlobalDefault()

function! s:InIgnoreList()
	let filename = expand("%:t")

	for pattern in g:ProjFileIgnores
		if filename =~ pattern
			return 1
		endif
	endfor
endfunc
function! s:InitBuffer()
	" 1. get project root
	if ! exists("b:ProjRoot")
		let git_root = system('git rev-parse --show-cdup')
		let b:ProjRoot = substitute(fnamemodify(git_root, ':p'), '/[\n\r]$', '', 'g')
		if 0 == strlen(b:ProjRoot)
			unlet b:ProjRoot
		endif
		call s:Log('ProjRoot: '.b:ProjRoot)
	endif

	if ! exists("b:ProjName") && exists("b:ProjRoot")
		let b:ProjName = fnamemodify(b:ProjRoot, ':t')
		call s:Log('ProjName: '.b:ProjName)
	endif

	" 2. load local config in ProjRoot
	if exists("b:ProjRoot") && exists("g:ProjLocalConfigName") && filereadable(b:ProjRoot.'/'.g:ProjLocalConfigName)
		execute 'source '.b:ProjRoot.'/'.g:ProjLocalConfigName
		call s:Log('source '.b:ProjRoot.'/'.g:ProjLocalConfigName)
	endif

	" synology build env
	let b:ProjBasePath = system('syno.common -q get_basepath '.shellescape(expand("%:p")))
	if getcwd() =~ '/synosrc/package/'
		let b:ProjPackageMode = 1
	else
		let b:ProjPackageMode = 0
	endif
	if 0 == strlen(b:ProjBasePath)
		let b:ProjBasePath = g:ProjBasePath
	endif
	call s:Log('ProjBasePath: '.b:ProjBasePath)

	let b:ProjBranch = system('syno.common -q get_branch '.shellescape(b:ProjBasePath))
	call s:Log('ProjBracnh: '.b:ProjBranch)

	let b:ProjPlatform = system('syno.common -q get_platform '.shellescape(b:ProjBasePath))
	if b:ProjPlatform == 'base' || b:ProjPackageMode
		let b:ProjPlatform = g:ProjPlatform
	endif
	call s:Log('ProjPlatform: '.b:ProjPlatform)

	if b:ProjPackageMode
		let b:ProjChrootPath = b:ProjBasePath.'/build_env/ds.'.b:ProjPlatform.'-4.1'
	else
		let b:ProjChrootPath = system('syno.common -q get_basepath -p '.shellescape(b:ProjPlatform).' '.shellescape(b:ProjBasePath))
		call s:Log('ProjChrootPath: '.b:ProjChrootPath)
	endif

	return 1
endfunc

function! s:LoadTagByName(name)
	if 1 == b:ProjPackageMode
		call s:LoadTag(b:ProjBasePath.'/tags/'.a:name.'.tags')
	else
		call s:LoadTag(b:ProjBasePath.'/../tags/'.a:name.'.tags')
	endif
	call s:LoadTag(b:ProjBasePath.'/source/'.a:name.'/tags')
endfunc
function! s:LoadPathByName(name)
	let projpath = b:ProjChrootPath.'/source/'.a:name
	if ! s:LoadPath(projpath.'/include')
		if ! s:LoadPath(projpath.'/includes')
			call s:LoadPath(projpath)
		endif
	endif
endfunc
function! s:GetDependProj(name)
	if ! filereadable(b:ProjBasePath."/lnxscripts/ProjectDepends.py")
		return []
	endif

	let line = system(b:ProjBasePath."/lnxscripts/ProjectDepends.py -x".g:ProjDependentLevel." -d '".a:name."'")
	return split(line, ' ')
endfunc

function! ProjLoader(name)
	call s:LoadTagByName(a:name)
	call s:LoadPathByName(a:name)
endfunc
function! ProjLoaderAuto()
	if s:InIgnoreList()
		call s:Log("ProjLoader: disabled")
		return
	endif
	if ! s:InitBuffer()
		return
	endif

	if expand("%") =~ '\.\(cpp\|cc\|C\|hpp\|CC\)$'
		call ProjLoader('cpp')
	endif

	if exists("b:ProjChrootPath")
		call s:LoadPath(b:ProjChrootPath.'/source')
		call s:LoadPath(b:ProjChrootPath.'/usr/include')
	endif

	if exists("b:ProjRoot")
		if filereadable(b:ProjRoot.'/tags')
			call s:LoadTag(b:ProjRoot.'/tags')
		endif
		call s:LoadPath(b:ProjRoot.'/')
	endif
	if exists("b:ProjDepends")
		for name in b:ProjDepends
			call ProjLoader(name)
		endfor
	endif
	if exists("b:ProjName")
		for name in s:GetDependProj(b:ProjName)
			call ProjLoader(name)

			" FIXME hardcode for libsynocore dependency
			if name == 'libsynosdk'
				call ProjLoader('libsynocore')
			endif
		endfor
		call ProjLoader(b:ProjName)
	endif
endfunc

if g:ProjLoaderAutocmd
	autocmd BufEnter * call ProjLoaderAuto()
endif

command -nargs=1 ProjLoad call ProjLoader(<args>)

let g:ProjLoaderInited = 1
