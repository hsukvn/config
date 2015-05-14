package th::Util;

use strict;
use warnings;
BEGIN {
	require Exporter;
	our @ISA	= qw(Exporter);
	our @EXPORT	= qw(color);
	our @EXPORT_OK	= qw();
	our $VERSION	= 1.00;
	our %EXPORT_TAGS= (
		'text' => [qw(h2c c2h i2c c2i wrap)],
	);
	Exporter::export_ok_tags('text');
}

{ # functions for color string 
	my %color_vim_mapping = ( #{{{
		Black		=> '30',
		DarkRed		=> '31',
		DarkGreen	=> '32',
		Brown		=> '33',   DarkYellow	=> '33',
		DarkBlue	=> '34',
		DarkMagenta	=> '35',
		DarkCyan	=> '36',
		LightGray	=> '37',   LightGrey	=> '37', Gray => '37', Grey => '1;37',
		DarkGray	=> '1;30', DarkGrey	=> '1;30',
		Red		=> '1;31', LightRed	=> '1;31',
		Green		=> '1;32', LightGreen	=> '1;32',
		Yellow		=> '1;33', LightYellow	=> '1;33',
		Blue		=> '1;34', LightBlue	=> '1;34',
		Magenta		=> '1;35', LightMagenta	=> '1;35',
		Cyan		=> '1;36', LightCyan	=> '1;36',
		White		=> '1;37',
	); #}}}

	my %color_cmd_mapping = (
		k => '0', r => '1', g => '2', y => '3', b => '4', p => '5', c => '6', w => '7'
	);

	sub color ($@) {
		my ($color_str, @str) = @_;
		my ($l, $f, $b, $filter) = ($color_str =~ /^(\d)?(\D)(\D)?(:.*)?$/);
		$l ||= '0'; $f ||= 'w'; $b ||= 'b'; $filter ||= ':^.+$';

		my $color_code = sprintf "\033[%s%s%sm", $l?'1;':'','3'. $color_cmd_mapping{$f},
			$b eq 'b'?'':';4'.$color_cmd_mapping{$b};
		$filter = substr($filter, 1);

		for my $s (@str) {
			next unless defined $s;
			$s =~ s/($filter)/$color_code$1\033[0m/g;
		}
		return wantarray ? @str : $str[0];
	}
}

sub h2c {
        join "", map{ pack "C", hex }(shift =~ /(..)/g);
        #join "", map{ chr hex }(shift =~ /(..)/g);
}
 
sub c2h {
        join "", map{ $_ = sprintf "%X", $_ }unpack( "C*", shift );
}

sub i2c {
	join "", map{ pack "C", $_ }(split /\s+/, shift);
}

sub c2i {
	join "", map{ $_ = sprintf "%3d", $_ }unpack( "C*", shift);
}

sub wrap {
format fh_fmt_TOP =
.
format fh_fmt =
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ~~
$_
.
	my $ofh = select(STDOUT);
	$^ = "fh_fmt_TOP";
	$~ = "fh_fmt";
	select($ofh);

	local $/ = '';
	while (<>) {
		write STDOUT;
	}
}
 
1;
