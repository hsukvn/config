#!/bin/bash

# enable color support of ls and also add handy aliases
if [ "$TERM" != "dumb" ]; then
	#eval "`dircolors -b`"
	eval `dircolors ~/config/colorrc`
	alias ls='ls --color=auto -F'
	alias grep='grep --color'
fi

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ptt='env LANG=zh_TW.utf-8 screen -c ~/config/screenrc.bbs ssh bbs@ptt.cc'
alias ptt2='env LANG=zh_TW.utf-8 screen -c ~/config/screenrc.bbs ssh bbs@ptt2.cc'
alias vi='vim -p'
alias zvi='vim +syntax\ off'
alias py='ipython'
alias ll='ls -al'

alias con="screen /dev/ttyS0 115200,cs8"

alias gj="/root/config/gj/bin/gj"
alias tmux="tmux -2"

tt_error() {
	local ret=$?
	echo "$@" >&2
	return $ret
}
vv() {
	if [ $# -eq 0 ]; then
		echo "no arguments"
		return
	fi
	"$@" | vim -
}
avi() {
	local temp="$TMPDIR/avi.$$.cf"
	if [ $# -eq 0 ]; then
		tt_error "no arguments"
		return 1
	fi
	if type ag >/dev/null; then
		ag "$@" > "$temp"
	elif type ack >/dev/null; then
		ack "$@" > "$temp"
	else
		tt_error "no ack, use grep instead"
		grep -rn "$@" * > "$temp"
	fi

	if [ ! -s "$temp" ]; then
		tt_error "no search results"
		return 0
	fi
	vim +"cf $temp" +'vert copen80'

	rm -f "$temp"
}
fvi() {
	local temp="$TMPDIR/fvi.$$.cf"
	if [ $# -eq 0 ]; then
		tt_error "no arguments"
		return 1
	fi
	if [ $# -eq 1 ]; then
		find -name "*$1*" | sed 's/$/:1: /' > "$temp"
	else
		find -name "$@" | sed 's/$/:1: /' > "$temp"
	fi

	if [ ! -s "$temp" ]; then
		tt_error "no search results"
		return 0
	fi

	vim +"cf $temp" +'vert copen30'
	rm -f "$temp"
}
wiki() {
	local host=${1:-"bat.synology.io"}
	local url="http://$host/wiki"
	[ "$TERM" = "screen" ] && echo -e "\ekwiki\e\\"
	env LANG="zh_TW.utf-8" w3m $url
}
sc() {
	local session=${1:-syno}
	if screen -list | grep ".$session	"; then
		screen -rd "$session"
	else
		screen -c ~/config/screen.$session -S "$session"
	fi
}

# LANG settings
alias big5='LANG=zh_TW.big5'
alias unicode='LANG=zh_TW.utf-8'
#export LANG=zh_TW.Big5
#export LC_CTYPE=zh_TW.Big5
#export LESSCHARSET=latin1

