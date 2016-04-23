export LANG=C.UTF-8
export LANGUAGE=C

export PATH=~/bin":$PATH":"~/gocode/bin"
export PYTHONPATH="$HOME/config/pythonlib/${PYTHONPATH+:}$PYTHONPATH"

export EDITOR=vim
export PAGER=less

# For colourful man pages (CLUG-Wiki style)
export LESS_TERMCAP_mb=$'\E[01;33m'
export LESS_TERMCAP_md=$'\E[01;34m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'
export TERM=xterm-256color
# for cscope and vim temp dir
export TMPDIR=$HOME/.tmp
[ -d "$HOME" -a ! -d "$TMPDIR" ] && mkdir "$TMPDIR"

export GOPATH="/usr/share/go/"
