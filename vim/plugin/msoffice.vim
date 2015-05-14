
autocmd BufReadPre *.pdf set ro nowrap
autocmd BufReadPost *.pdf silent %!pdftotext "%" -nopgbrk -layout -q -eol unix -

autocmd BufReadPre *.doc set ro
autocmd BufReadPost *.doc silent %!antiword -m UTF-8 "%"
"autocmd BufReadPost *.doc silent %!catdoc -x -d utf-8 "%"

autocmd BufReadPre *.xls set ro ft=csv
autocmd BufReadPost *.xls silent %!xls2csv -x -d utf-8 "%" | iconv -f utf8 -t utf8 -c
