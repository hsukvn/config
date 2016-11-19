#!/usr/bin/perl
# vim:fdm=marker

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long qw(:config bundling);
use File::Basename;

my %opt = ();
my %opt_config = (
	# opt		    default	help						variable	handler
	"confirm|c"	=> [0,		"pop confirm messages",				'confirm'],
	"srcpath=s"	=> ["/synosrc",	"synosrc path",					'srcpath'],
	"platform|p=s"	=> ['7820 854x 5281 ixp425 6282r'
		.'bromolow x64 853x 6281 6180 824x ppc cedarview qoriq 816x armadaxp armada370 evansport catalina',
					"default platforms",				'platform'],
	"input|i=s"	=> ['',		"input file list. default is use argument list. '-' for use stdin",
											'input'],
	"force|f"	=> [0,		"do remove before cp",				'rmfirst'],
	# other options
	"tty"		=> [(-t STDOUT),"set output is tty. (output color codes)",	'tty'],
	"debug|d"	=> [0,		"enable debug flag",				'debug'],
	"help|h"	=> [0,		"this help message",				'help'],
);
{ # utils {{{
	my %color_cmd_mapping = (
		k => '0', r => '1', g => '2', y => '3', b => '4', p => '5', c => '6', w => '7'
	);
	sub color ($@) {
		my ($color_str, @str) = @_;
		my ($l, $f, $b, $filter) = ($color_str =~ /^(\d)?(\D)(\D)?(:.*)?$/);
		$l ||= '0'; $f ||= 'w'; $b ||= 'b'; $filter ||= ':^.+$';

		if (!$opt{tty}) {
			return wantarray ? @str : $str[0];
		}

		my $color_code = sprintf "\033[%s%s%sm", $l?'1;':'','3'. $color_cmd_mapping{$f},
			$b eq 'b'?'':';4'.$color_cmd_mapping{$b};
		$filter = substr($filter, 1);

		for my $s (@str) {
			next unless defined $s;
			$s =~ s/($filter)/$color_code$1\033[0m/g;
		}
		return wantarray ? @str : $str[0];
	}
	sub debug(@) {
		return 0 unless $opt{debug};
		print STDERR color("b", $_) for @_;
		return 1;
	}
	sub help() {
		printf STDERR "options:\n";
		printf STDERR color("1w", "\t--%-18s")." %s\n", $_, $opt_config{$_}[1]
			for sort keys %opt_config;
		exit 1;
	}
} #}}}
# parse arguments or dump help messages {{{
%opt = map { $opt_config{$_}[2] => $opt_config{$_}[0]; } keys %opt_config;
GetOptions(map {
	my $h = \$opt{$opt_config{$_}[2]};
	$h = eval "sub {\$opt{$opt_config{$_}[2]} = 0};" if /^no-/;
	$h = $opt_config{$_}[3] if $opt_config{$_}[3];
	$_ => $h;
} keys %opt_config) or help;
help if $opt{help};
print Dumper \%opt if $opt{debug};
# }}}

my @files = ();
if ('-' eq $opt{input}) {
	warn "read file list from stdin\n";
	@files = <>;
} elsif ($opt{input}) {
	open IN, "<$opt{input}" or die "$! $opt{input}";
	@files = <IN>;
	close IN;
} else {
	@files = @ARGV;
	print STDERR "please input the file list\n" and help if (0 == scalar @files); 
}

debug "process: ", join(", ", @files), "\n";

my $pwd = `/bin/pwd`;
chomp $pwd;
debug "$pwd\n";

die "not in ds.base\n" unless $pwd =~ m{\/ds\.base(-.+b)?(\/|$)};

for my $file ( @files ) {
	chomp($file);
	$file = "$pwd/$file";
	warn "file: $file is not existed" and next unless (-f $file or -d $file);

	printf STDERR "link %s: $file\n", (-f $file) ? "file" : "dir";

	for my $p (split(/\s+/, $opt{platform})) {
		my $tpwd = $pwd;
		my $tgr = $file;
		$tpwd =~ s/ds\.base/ds.$p/;
		$tgr =~ s/ds\.base/ds.$p/;
		next unless (-d $tpwd);

		if ($opt{confirm} && '-' ne $opt{input}) {
			print STDERR "to $tgr? [Y/n]";
			my $option = <STDIN>;
			next unless $option =~ /^$|^y|^yes/i;
			print STDERR "...";
		}
		
		if ($opt{rmfirst}) {
			debug "rm -rf $tgr; cp -al $file $tgr\n";
			system("/bin/rm", "-rf", $tgr);
			system("/bin/cp", "-al", $file, $tgr);
		} else {
			debug "cp -alf $file $tgr\n";
			system("/bin/cp", "-alf", $file, dirname($tgr));
		}

		if ($opt{confirm} && '-' ne $opt{input}) {
			print STDERR " done.\n";
		}
	}
}
