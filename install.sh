#!/bin/bash

show_usage() {
	cat << EOF
Usage: $(basename $0) [options]
Options:
    -a        install basic apt packages
    -i        install configs
    -s        install for synology
    -u        uninstall configs and recover environments
    -h        show this help message
    -d        debug mode
EOF
}

while getopts "adhisu" opt; do
	case $opt in
		a) InstallApt=yes;;
		i) InstallConfig=yes;;
		s) InstallForSynology=yes;;
		u) UnInstallConfig=yes;;
		h) show_usage; exit 0;;
		d) DEBUG=on;;
	esac
done

if [ $OPTIND == 1 ]; then
	show_usage
	exit 0;
fi

shift $((OPTIND - 1))

PWD=`pwd`
BAKDIR="/root/.config.bak"
DOTFILES=$(ls $PWD/dotfiles)

exe() {
	echo $1
	if [ -z $DEBUG ]; then
		eval $1
	fi
}

install_apt() {
	exe "apt update"
	exe "apt install -y git"
	exe "apt install -y ssh vim samba"
	exe "apt install -y build-essential ctags cscope"
	exe "apt install -y python-pip python"
	exe "apt install -y python3-pip python3"
	exe "apt install -y silversearcher-ag id-utils"

	exe "pip3 install --upgrade requests"
	exe "pip3 install --upgrade zdict"
}

backup_config() {
	echo "star to backup from $BAKDIR..."
	[ ! -d $BAKDIR ] && exe "mkdir $BAKDIR"
	[ -d /root/bin ] && exe "mv /root/bin $BAKDIR/bin"
	[ -d /root/.vim ] && exe "mv /root/.vim $BAKDIR/vim"
	[ -f /root/.vimrc ] && exe "mv /root/.vimrc $BAKDIR/vimrc"

	[ ! -d $BAKDIR/dotfile ] && exe "mkdir $BAKDIR/dotfile"
	for dotfile in $DOTFILES; do
		[ -f /root/.$dotfile ] && exe "mv /root/.$dotfile $BAKDIR/dotfile/$dotfile"
	done
}

install_config() {
	backup_config

	echo "star to install..."
	exe "ln -s $PWD/bin /root/bin"
	exe "ln -s $PWD/vim /root/.vim"
	exe "ln -s /root/.vim/vimrc /root/.vimrc"

	for dotfile in $DOTFILES; do
		exe "ln -s $PWD/dotfiles/$dotfile /root/.$dotfile"
	done

	source /root/.bashrc
}

install_syno_build_tags() {
	[ ! -d "/synosrc" ] && return;
	exe "ln -s ~/config/script/syno.build.tags /synosrc/syno.build_tags"
}

install_syno_build_status() {
	exe "cd ~/config/addon"
	exe "tar zxvf JSON*"
	exe "cd JSON*"
	exe "perl Makefile.PL"
	exe "make"
	exe "make install"
	exe "cd -"
}

install_for_synology() {
	install_syno_build_tags
	install_syno_build_status
}

restore_config() {
	echo "star to restore from $BAKDIR..."
	[ ! -d $BAKDIR ]  && return;
	[ -d $BAKDIR/bin ] && exe "mv $BAKDIR/bin /root/bin"
	[ -d $BAKDIR/vim ] && exe "mv $BAKDIR/vim /root/.vim"
	[ -f $BAKDIR/vimrc ] && exe "mv $BAKDIR/vimrc /root/.vimrc"

	for dotfile in $DOTFILES; do
		[ -f $BAKDIR/dotfile/$dotfile ] && exe "mv $BAKDIR/dotfile/$dotfile /root/.$dotfile"
	done
	#finish
	exe "rmdir $BAKDIR/dotfile"
	exe "rmdir $BAKDIR"
}

uninstall_config() {
	echo "star to uninstall..."
	[ -L /root/bin ] && exe "rm /root/bin"
	[ -L /root/.vim ] && exe "rm /root/.vim"
	[ -L /root/.vimrc ] && exe "rm /root/.vimrc"
	[ -L /root/bin ] && exe "rm /root/bin"
	
	for dotfile in $DOTFILES; do
		[ -L /root/.$dotfile ] && exe "rm /root/.$dotfile"
	done
	restore_config
}

if [ $InstallApt ]; then
	install_apt
fi

if [ $InstallConfig ]; then
	echo "starting install config..."
	install_config
	echo "finish"
fi

if [ $InstallForSynology ]; then
	echo "starting install synology configs..."
	install_for_synology
	echo "finish"
fi

if [ $UnInstallConfig ]; then
	echo "starting uninstall config..."
	uninstall_config
	echo "finish"
fi
