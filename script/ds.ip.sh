#!/bin/bash

hostname="${1:-atung}"

echo "find ip of \"$hostname\"" >&2;
ds_ip=`${dsassistant:-dsassistant.i386} | sed -n "/ $hostname/{N;p}" | tail -1`
echo "" >&2
echo ${ds_ip##* }

