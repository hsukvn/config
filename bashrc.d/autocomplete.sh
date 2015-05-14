#!/bin/bash
# thlu@synology.com

_ac_vboxmanage() {
	local cur prev
	local words="list showvminfo registervm unregistervm createvm
			modifyvm clonevm import export startvm controlvm
			discardstate adoptstate snapshot closemedium
			storageattach storagectl bandwidthctl showhdinfo
			createhd modifyhd clonehd convertfromraw
			convertfromraw getextradata setextradata setproperty
			usbfilter sharedfolder guestproperty guestcontrol
			debugvm metrics hostonlyif dhcpserver extpack"

	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	if [ "$prev" = "vboxmanage" ]; then
		COMPREPLY=( $(compgen -W "$words" "$cur") )
	elif echo -n "$words" | grep -wq "$prev"; then
		words=$(vboxmanage "$prev" | sed -n '/VBoxManage '$prev'/,$s/[]\[|]/ /gp' | sed 's/VBoxManage '$prev'//')
		COMPREPLY=( $(compgen -W "$words" "$cur") )
	fi
}

complete -F _ac_vboxmanage vboxmanage
