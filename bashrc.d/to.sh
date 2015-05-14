#!/bin/bash
# Version:     1.0
# Maintainer:  thlu@synology.com
# Last Change: 2011.04.10 02:08
#  vim:fdm=marker

to() {
	local plat=${DEV_PLATFORM} branch=${DEV_BRANCH}
	local source_path= work_dir= new_dir= bookmark= print_file=
	local cur= prev= compword=
	local OPTIND= OPTARG= opt=

	local platforms="base bromolow 7820 x64 853x 6281 6180 854x 5281 824x ppc 6282r cedarview qoriq evansport"
	local branches="q1 q2 q3 eagle curr package dr3 addon eds allplat"
	local bookmarks="src sdk lnxsdk core ext dsm cp net firewall ddns sysinfo rsm test help ushelp box ls up"
	local verbose=

	local UseCommon=
	if type syno.common >/dev/null 2>&1; then
		UseCommon=on
	fi

	if [ "$COMP_CWORD" ]; then #{{{
		cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]}

		if [ "$UseCommon" -a "$cur" ]; then
			compword="$(syno.bookmark -l $cur) $(syno.bookmark -b "$branch" -l $cur)"
		fi

		if [ "$prev" = "-f" -o "$prev" = "--" ]; then
			_filedir
		elif printf "%s" "$platforms" | grep -wq "$prev"; then
			COMPREPLY=( $(compgen -W "$branches $bookmarks $compword" -- $cur) )
		elif printf "%s" "$branched" | grep -wq "$prev"; then
			COMPREPLY=( $(compgen -W "$platforms $bookmarks $compword" -- $cur) )
		else
			COMPREPLY=( $(compgen -W "$platforms $branches $bookmarks $compword" -- $cur) )
		fi
		return
	fi #}}}

	if [ $# -eq 0 ]; then
		echo "please set the arguments" >&2;
		to -h ; return
	fi

	# parse flag arguments {{{
	while getopts "f:dh" opt; do
		case "$opt" in
			f)	print_file=$OPTARG ;;
			d)	verbose=on ;;
			h)	cat >&2 <<EOF
USAGE: to [options] [platform|branch|bookmark|back pattern]
  platforms: $platforms
  branches:  $branches
  bookmarks: $bookmarks
EOF
				return 0 ;;
		esac
	done
	shift $((OPTIND-1))
	while [ ${1+isset} ]; do
		if [ "$1" = "--" -o "$1" = "-f" ]; then
			shift ; continue
		elif [ "${1:0:1}" = "-" ]; then
			echo "not support '-' options"
		elif printf "%s" "$platforms" | grep -wq "$1"; then
			plat="$1"
		elif printf "%s" "$branches" | grep -wq "$1"; then
			branch="$1"
		elif printf "%s" "$bookmarks" | grep -wq "$1"; then
			bookmark="$1"
		elif [ "$UseCommon" ] && syno.bookmark -q "$1" >/dev/null; then
			[ "$verbose" ] && echo "use syno.bookmark" >&2
			bookmark="$1"
		elif [ "$UseCommon" ] && syno.bookmark -b package -q "$1" >/dev/null; then
			[ "$verbose" ] && echo "use syno.bookmark -b package" >&2
			bookmark="$1"
		else
			break
		fi
		shift
	done
	if [ $# -gt 0 -a -z "$bookmark" -a -z "$plat" -a -z "$branch" ]; then
		bookmark="$1" ; shift
	fi
	if [ $# -gt 0 -a -z "$print_file" ]; then
		print_file="$1" ; shift
	fi
	#}}}

	# get platform and branch {{{
	if [ "$UseCommon" ]; then
		[ -z "$plat" ] && plat=$(syno.common -q get_platform)
		[ -z "$branch" ] && branch=$(syno.common -q get_branch)
	else
		if ! work_dir=$(pwd -P | sed -n "s,\(.*ds\.[^/]*\).*,\1,p") ; then
			echo "get work directory failed" >&2
			return 1
		fi
		if [ -z "$plat" ]; then
			case "$work_dir" in
				*/ds.*)	plat=${work_dir#*ds.} ;;
				*)	plat="base" ;;
			esac
		fi
		if [ -z "$branch" ]; then
			case "$work_dir" in
				*/ds.*)	branch=$(basename `dirname $work_dir`) ;;
				*)	branch="curr" ;;
			esac
		fi
	fi
	#}}}
	[ "$verbose" ] && echo "platform: $plat, branch: $branch, bookmark: $bookmark, print file: $print_file" >&2

	if [ -z "$bookmark" ]; then
		new_dir=`pwd -P | sed -n "s,/[^/]*/ds\.[^/]*,/$branch/ds.$plat,p"`

		if [ x"$plat" = x"base" -a -e "/synosrc/$branch/pkgscripts" ]; then
			new_dir=`echo -n "$new_dir" | sed -n 's,ds\.[^/]*/,,p'`
		fi

		if [ -z "$new_dir" ]; then
			bookmark="src"
		else
			if [ "$print_file" ]; then
				printf "%q %q\n" "$print_file" "$new_dir/$print_file"
			else
				echo "to platform $branch/ds.$plat: $new_dir" >&2;
				cd "$new_dir"
			fi
			return
		fi
	fi

	# find synosrc source path {{{
	if printf "%s" "$PS1" | grep -q "CHROOT" && test -d "/source"; then
		source_path="/source"
	elif [ -e "/synosrc/$branch/pkgscripts" -o -e "/synosrc/$branch/build_env" ]; then
		#pwd -P | grep -q "/synosrc/package" 2> /dev/null; then
		source_path="/synosrc/$branch/source"
		is_package_source=yes
	else
		source_path="/synosrc/$branch/ds.$plat/source"
	fi
	if [ ! -d "$source_path" ]; then
		echo "can not find source path. (candidate: $source_path)" >&2
		return 1;
	fi
	#}}}
	[ "$verbose" ] && echo "source path: $source_path" >&2

	# handle bookmark
	case "$bookmark" in
	ls)	[ "$is_package_source" ] \
		&& new_dir="$source_path/../pkgscripts" \
		|| new_dir="$source_path/../lnxscripts" ;;
	up)	new_dir="$source_path/lnxsdk/updater" ;;
	src)	new_dir="$source_path" ;;
	sdk)	new_dir="$source_path/libsynosdk/lib" ;;
	upg)	new_dir="$source_path/dsm-AdminCenter/modules/Update_Reset" ;;
	lnxsdk)	new_dir="$source_path/lnxsdk" ;;
	core)	new_dir="$source_path/libsynocore/lib" ;;
	core)	new_dir="$source_path/libsynoinstall/cpp/lib" ;;
	wupg)	new_dir="$source_path/webapi-Upgrade/src" ;;
	ext)	new_dir="$source_path/synojslib/ext-3.4" ;;
	dsm)	new_dir="$source_path/dsm" ;;
	cp)	new_dir="$source_path/dsm-ControlPanel" ;;
	net)	new_dir="$source_path/dsm-ControlPanel/modules/Network" ;;
	ddns)	new_dir="$source_path/dsm-ControlPanel/modules/DDNS" ;;
	firewall)new_dir="$source_path/dsm-ControlPanel/modules/Firewall" ;;
	sysinfo)new_dir="$source_path/dsm/modules/SystemInfoApp" ;;
	rsm)	new_dir="$source_path/dsm/modules/ResourceMonitor";;
	test)	new_dir="$source_path/dsm/modules/Test";;
	help)	new_dir="$source_path/uihelp/dsm";;
	ushelp)	new_dir="$source_path/uihelp_us2/dsm";;
	box)	new_dir="$source_path/busybox-1.16.1" ;;
	*)	if [ "$UseCommon" ]; then
			if ! new_dir=$(syno.bookmark -q "$bookmark"); then
				new_dir=
			fi
			if [ -z "$new_dir" ] && ! new_dir=$(syno.bookmark -q -b package "$bookmark"); then
				new_dir=
			fi
			[ "$verbose" ] && echo "use syno.bookmark: $new_dir" >&2
		fi;;
	esac

	if [ -z "$new_dir" ]; then
		if ! new_dir=`dirname $(pwd -P) | sed -n "s,^\(.*/$bookmark[^/]*\).*$,\1,p"`; then
			echo "get back dir failed" >&2 ; return
		fi
		if [ ! -z "$new_dir" ]; then
			if [ "$print_file" ]; then
				printf "%q %q\n" "$print_file" "$new_dir/$print_file"
			else
				echo "back to $new_dir" >&2;
				cd "$new_dir"
			fi
			return
		fi
		echo "no such bookmark or back pattern" >&2
		echo "" >&2
		to -h
		return 1
	elif [ "$print_file" ]; then
		printf "%q %q\n" "$print_file" "$new_dir/$print_file"
	else
		echo "to bookmark($bookmark): $new_dir" >&2;
		cd "$new_dir"
	fi
}
complete -F to to
