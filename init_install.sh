#!/bin/bash

init_install() {
	sudo apt-get update
	sudo apt-get install vim git-core gcin screen w3m cifs-utils ssh samba \
		apache2 php5 python build-essential ctags cscope \
		nfs-kernel-server mailutils smbfs autofs xclip graphviz ethtool \
		unrar cu nethogs meld chromium-browser mercurial cproto autoconf \
		gimp wireshark freemind vncviewer cppcheck
}

# other non-free package:
#  google-chrome, opera, teamviewer, dropbox,

set_wireshark_permission() { # <user>
	local user=$1
	local bin_cap=/usr/bin/dumpcap

	if ! id | grep -wq wireshark; then
		sudo groupadd wireshark
		sudo usermod -a -G wireshark $(whoami)
	fi

	sudo chown root.wireshark "$bin_cap"
	sudo chmod 4750 "$bin_cap"

	# NOTE: log out gnome desktop to reload group list ?
}

set_python_modules() {
	sudo apt-get install python-pip
	sudo pip install markdown
}
set_python_argcomplete() {
	# reference: https://argcomplete.readthedocs.org/en/latest/
	sudo pip install argcomplete
	sudo activate-global-python-argcomplete
}

init_install
set_wireshark_permission
set_python_modules
set_python_argcomplete
pip install jsbeautifier

cat <<EOF
other settins

let user can chroot without password
	sudo env EDITOR=vim visudo
then add
	thlu    ALL=(root) NOPASSWD: /usr/sbin/chroot
EOF

#apt-get upgrade
