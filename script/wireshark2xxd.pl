#!/usr/bin/perl

open XXD, "| xxd -r";

while(<>){
	chomp;
	my @token = split(/\s+/,$_,18);

	print XXD $token[0].": ";

	for (my $i = 1 ; $i < 16 ; $i += 2) {
		print XXD $token[$i].$token[$i+1]." ";
	}

	print XXD $token[17]."\n";
}
