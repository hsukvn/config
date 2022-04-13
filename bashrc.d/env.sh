# export LANG=C.UTF-8
# export LANGUAGE=C
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export PATH=~/bin":$PATH"
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

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

# For cscope and vim temp dir
export TMPDIR=$HOME/.tmp
[ -d "$HOME" -a ! -d "$TMPDIR" ] && mkdir "$TMPDIR"

# For golang
export GOPATH=~/go
export PATH=$PATH:~/go/bin

# For debian
# export DEBEMAIL="kevin.hsu@ubnt.com"
# export DEBFULLNAME="Kevin Hsu"
