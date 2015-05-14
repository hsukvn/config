#!/bin/sh

WORD=$1
if [ -z "$WORD" ]; then
	echo "usage: $0 <word>"
	exit 0;
fi
env LANG=zh_TW.utf8 w3m -dump "http://tw.dictionary.yahoo.com/dictionary?p=$WORD" 2>/dev/null \
	| sed -n '/^依字典語言顯示/,/^知識\+/p' | sed -n '7,$p' \
	| grep -v "\(Dr\.eye 譯典通\|      □ \|^知識+\|    PyDict\)" \
	| sed '/^$/d'

#| grep -v "\( • definition\| • example\| • related expression\| • online resource\|Online Resources\)" \
