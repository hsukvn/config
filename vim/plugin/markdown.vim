if !has('python')
	finish
endif

function! Markdown2HTML()
	pyfile ~/config/vim/tools/markdown2html.py
endfunc

command! MKD2HTML call Markdown2HTML()
