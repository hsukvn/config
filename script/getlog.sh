#!/bin/bash

Download() {
	local url=$1
	local output=$2

	[ -n "$url" -a -n "$output" ] || return 1

	case $url in
		http://*)
			wget -O "$output" "$url" ;;
		ftp://*)
			curl $url > $output;;
		*)
			return 1 ;;
	esac
}

#smb_source="`syno.common -q get_basepath`/source/samba-3.2.2/source"
#smb_source="`syno.common -q get_basepath`/source/samba-3.6.x/source3"
host_ds="th15.local"
log_file_in=${TMPDIR:-/tmp}/smb.log
log_file_out=${log_file_in}
do_wget=y
url=
file=log.smbd

usage() {
	local progname=`basename $0`
	cat <<EOF
$proname [options] [url]
Options:
  -h               show help message
  -i [input]       do not get file. use [input] file istead
  -o [output]      save log file to [output]
  -a [hostname|ip] set host for download log file
  -p               do not get file. use default local log file
url options
  -c               download log.smbd.client
  -w               download log.winbindd
  -s               download log.smbd (default)
  -n               download log.nmbd
  -d               download log.winbindd-dc-connect
  -f [filename]    download file in /usr/syno/synoman/log/[filename]
  -P               download profile
EOF
}
while getopts "hi:o:a:pwsndf:cP" opt; do
	case $opt in
		h) usage ; exit 0 ;;
		a) host_ds=$OPTARG ;;

		i) do_wget=n ; log_file_in=$OPTARG ;;
		o) log_file_out=$OPTARG ;;
		p) do_wget=n ; log_file_in=${TMPDIR:-/tmp}/smb.log ;;

		w) file=log.winbindd ;;
		s) file=log.smbd ;;
		n) file=log.nmbd ;;
		d) file=log.winbindd-dc-connect ;;
		c) file=log.smbd.client ;;
		f) file=$OPTARG ;;
		P) url="http://$host_ds:5000/profile.txt"
		   log_file_out=~/.tmp/profile.txt
	esac
done
shift $((OPTIND - 1))
if [ $# -gt 0 ]; then
	url=$1 && shift
fi

if [ -z "$url" ]; then
	url="http://$host_ds:5000/log/$file"
fi

if [ "$do_wget" = "y" ]; then
	if Download "$url" "$log_file_out"; then
		log_file_in=${log_file_out}
	else
		echo "download [$url] failed" >&2
		exit 1
	fi
fi

if [ ! -r "$log_file_in" ]; then
	echo "can not read log file [$log_file_in]" >&2
	return 1
fi

if [ x"$(basename "$log_file_out")" = xprofile.txt ]; then
	sed 's,: *,\t,' "$log_file_out" | /usr/bin/xclip -sel clip
	exit 0
fi

if [ -n "$smb_source" ]; then
	echo vim "+cd $smb_source" "+cf $log_file_in" "+vert copen80" "+setlocal fdm=marker"
	vim "+cd $smb_source" "+cf $log_file_in" "+vert copen80" "+setlocal fdm=marker"
else
	echo vim "+cf $log_file_in" "+vert copen80" "+setlocal fdm=marker"
	vim "+cf $log_file_in" "+vert copen80" "+setlocal fdm=marker"
fi

if [ "x$log_file_in" != "x$log_file_out" ]; then
	cp "$log_file_in" "$log_file_out"
fi
