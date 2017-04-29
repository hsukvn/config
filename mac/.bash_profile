# to be colourful
export CLICOLOR=1
export LSCOLORS=gxCxhxDxfxhxhxhxhxcxcx

# Tell grep to highlight matches
export GREP_OPTIONS='--color=auto'

# PS1 full path
export PS1='\u@\H:\w$ '

#library search path
export PATH="/usr/local/sbin:/usr/local/Cellar/node/6.2.1/bin:$PATH"
#alias
alias vim='/usr/local/bin/vim'
alias ll='ls -la'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ldd='otool -L'
alias qlmanage='qlmanage -p'
#Language setting
alias big5='LANG=zh_TW.big5'
alias unicode='LANG=zh_TW.utf-8'
#tmux
alias tmux='tmux -2'

export NVM_DIR="/Users/ilcic/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
