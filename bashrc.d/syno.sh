#!/bin/bash

export SYNO_CURR_PROJ_LIST="$HOME/proj.list"
#export SYNO_CURR_PLATFORM="853x"
#export SYNO_CURR_PLATFORM="6281"
#export SYNO_CURR_PLATFORM="x64"
export SYNO_CURR_PLATFORM="cedarview"

_SynoPathCompletion()
{
	local cur words
	local source_path="$(syno.common -q get_basepath)/source"

	if [ -z "$source_path" ]; then
		source_path="/synosrc/curr/ds.base/source"
	fi

	cur="${COMP_WORDS[COMP_CWORD]}"
	words=$(ls -t --indicator-style="none" "$source_path")
	COMPREPLY=( $(compgen -W "$words" "$cur") )
}
_SynoPlatform()
{
	local platform="$(syno.common -q enum_platform)"
	COMPREPLY=( $(compgen -W "$platform" "${COMP_WORDS[COMP_CWORD]}") )
}
_SynoPathOrFileCompletion()
{
	local cur= prev=
	if [ -z "$COMP_CWORD" ]; then
		return 1
	fi
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	case "$prev" in
		-f) _filedir ;;
		*) _SynoPathCompletion ;;
	esac
}
complete -F _SynoPathCompletion BuildAll
complete -F _SynoPathCompletion SynoUpdate
complete -F _SynoPathCompletion SynoBuild
complete -F _SynoPathOrFileCompletion syno.status
complete -F _SynoPlatform syno.chroot
complete -F _SynoPathCompletion syno.build.this
