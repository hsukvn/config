#!/usr/bin/perl

use strict;
use warnings;

sub gcd {
	my ($a, $b) = @_;
	($a,$b) = ($b,$a) if $a > $b;
	while ($a) {
		($a, $b) = ($b % $a, $a);
	}
	return $b;
}

#my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

my ($mon, $mday) = (0,0);
if (@ARGV == 0) {
	($mday, $mon) = (localtime(time))[3,4];
	$mon += 1;
} elsif (@ARGV == 2) {	
	($mon, $mday) = @ARGV;
} else {
	print STDERR "usage: $0 ([MONTH] [DAY])\n";
}

my $passwd = sprintf "%x%02d-%02x%02d", $mon, $mon, $mday, gcd($mon, $mday);

print $passwd, "\n";

if ( -x "/usr/bin/xclip" ) {
	print STDERR "write to clip\n";
	open OUT, "| /usr/bin/xclip -sel clip";
	print OUT $passwd;
	close OUT;
}
