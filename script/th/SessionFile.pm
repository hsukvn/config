#!/usr/bin/perl
# load session file as an perl hash.
# formats in session file are:
# 	1. [session name]
# 	2. # a line of comment
# 	3. key=value
# 	4. key="value"
# 	5. key='value'
# 	6. a real line -> set type to 'line'
package th::SessionFile;
use strict;
use warnings;
use overload q("") => \&toString;

BEGIN {
	require Exporter;
	our @ISA	= qw(Exporter);
	our @EXPORT	= qw();
	our @EXPORT_OK	= qw();
	our $VERSION	= 1.1;
}

our %is_type = ('key-value' => 1, 'line' => 1);

my %default = (
	type => 'key-value',
	start_session => '.start',
);

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $obj = bless {
		'.config' => {
			'sessions' => [],
			'type' => $default{'type'},
		},
	}, $class;

	$obj->load(@_) if @_;

	return $obj;
};

sub type {
	my $o = shift;
	if (@_) {
		die __PACKAGE__.": invalid type name '$_[0]'" unless $is_type{$_[0]};
		$o->config('type', @_);
	}
	return $o->config('type');
}

sub config {
	my $o = shift;
	my $key = shift or die;
	$o->{'.config'}{$key} = shift if @_;
	return $o->{'.config'}{$key};
};

sub sessions {
	my $o = shift;
	return @{ $o->config('sessions') };
};

sub load {
	my $o = shift;
	my ($session, $prev_session) = ($default{'start_session'}, "");

	for my $line (@_) {
		chomp $line;
		next if ($line =~ /^\s*(#|$)/);

		if ($line =~ /^\[([^\]]+)\]$/) {
			$session = $1;
			push @{ $o->config('sessions') }, $session;
			next;
		}

		if ('line' eq $o->config('type')) {
			push @{ $o->{$session} }, $line;
		} elsif ('key-value' eq $o->config('type')) {
			if ($line =~ /^\s*([^=]+)\s*=\s*?(["']?)(.*)\2$/) {
				$o->{$session}{$1} = defined($3) ? $3 : "";
			} else {
				die "parse error >> $line\n";
			}
		} else {
			die 'unknown type of session file';
		}
	}

	if (exists $o->{ $default{'start_session'}}) {
		unshift @{ $o->config('sessions') }, $default{'start_session'};
	}
	return scalar @_;
};

sub load_file {
	my $o = shift;
	my $file = shift;
	open my $fh, "<$file" or die "open file '$file' failed";
	my $ret = $o->load(<$fh>);
	close $fh;
	return $ret;
}

sub toString {
	my $o = shift;
	my $str = "";

	for my $s ($o->sessions()) {
		$str .= sprintf "\n[$s]\n";

		if ('ARRAY' eq ref $o->{$s}) {
			$str .= sprintf join("\n", @{$o->{$s}})."\n";
			next;
		}
		if ('HASH'  eq ref $o->{$s}) {
			for my $key (keys %{$o->{$s}}) {
				$str .= sprintf "%s=%s\n", $key, $o->{$s}{$key};
			}
		}
	}
	return $str;
};

1;
