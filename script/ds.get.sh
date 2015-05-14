#!/bin/sh

host=$DS_IP
file=""
protocol='ssh'

while getopts 'p:' opt; do
	case "$opt" in
		p) protocol="$OPTARG";;
	esac
done
shift $((OPTIND-1))

if [ -z "$1" ]; then
	echo "$0 [filename]"
	exit -1
else
	file=$1
fi
if [ -n "$2" ]; then
	host=$2
fi

case "$protocol" in
	ftp)
		user="admin"
		pass="q"
		remote_path="web"
		echo "get ftp://$host/$remote_path/$file" >&2
		ftp -n $host <<EOF
user $user $pass
cd "$remote_path"
get "${file}"
quit
EOF
	;;
	ssh)
		user=root
		echo "get ssh://$host/$file" >&2
		ssh "$user@$host" "cat '$file'" > $(basename "$file")
	;;
esac
