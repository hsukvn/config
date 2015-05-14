#!/bin/bash

host=$DS_IP
file=
remote_path=
protocol='ssh'

while getopts 'fp:r:' opt; do
	case $opt in
		p) protocol="$OPTARG";;
		r) remote_path="$OPTARG";;
	esac
done
shift $((OPTIND -1))

if [ -z "$1" ]; then
	echo "$0 [filename]";
	exit -1;
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
		echo "send '$file' to ftp://$host/$remote_path/$file" >&2
		ftp -n $host <<EOF
user $user $pass
cd "$remote_path"
put "${file}" `basename ${file}`
quit
EOF
	;;
	ssh)
		if [ -z "$remote_path" ]; then
			remote_path="/root/$(basename $file)"
		fi
		user="root"
		echo "send '$file' to ssh://$user@$host/$remote_path" >&2
		cat "$file" | ssh "$user@$host" "cat > $remote_path"
	;;
esac
