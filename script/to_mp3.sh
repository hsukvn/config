#!/bin/bash

input="$1";
output="$2";

if [ -z "$input" ]; then
	echo "usage: $0 [input.wma]" >&2;
	exit 1;
fi

if [ -e "audiodump.wav" ]; then
	echo "temp file is existed" >&2;
	exit 1;
fi

if [ -z "$output" ]; then
	output="$input.mp3"
fi

mplayer -ao pcm "$input"
lame audiodump.wav "$output"
rm audiodump.wav

if [ ! -z "$artist" ]; then
	mid3v2 -a "$artist" "$output"
fi
if [ ! -z "$album" ]; then
	mid3v2 -A "$album" "$output"
fi

mid3v2 -l "$output"
