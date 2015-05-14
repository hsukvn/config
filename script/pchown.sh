#!/bin/bash

user=${1:-$(id -u)}
group=${2:-$(id -g)}

if proj_dir=$(git rev-parse --show-cdup); then
	[ -z "$proj_dir" ] && proj_dir=.
else
	echo "not a git dir" >&2
	proj_dir=.
fi
echo "sudo chown -R $user.$group $proj_dir" >&2
sudo chown -R "$user.$group" "$proj_dir"
