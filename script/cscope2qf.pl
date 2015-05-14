#!/usr/bin/perl

while(<>) {
	if (/^\s*(\d+)\s+(\d+)\s+(.+?)( <<([a-zA-Z0-9_-]+)>>)?$/) {
		printf "$3|$2| $1%s\n", defined $5 ? " $5" : "";
	} else {
		print $_;
	}
}
