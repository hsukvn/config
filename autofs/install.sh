#!/bin/bash

configs="auto.master auto.samba smb.auth"

for i in $configs; do
	echo "cp $i /etc/$i"
	sudo cp "$i" "/etc/$i"
done
