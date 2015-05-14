#!/usr/bin/perl
package th::WebAgent;

use strict;
use warnings;
use Carp;
use th::Util;

BEGIN {
	require Exporter;
	our @ISA	= qw(Exporter);
	our @EXPORT	= qw(curl);
	our @EXPORT_OK	= qw();
	our $VERSION	= 1.1;
}

my @depend_exec = qw/curl cat tail/;

sub curl {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $o = {
		tool       => 'curl',

		seq         => 1,
		output_fmt  => 'out%02d.html',
		output      => undef,
		pervurl     => undef,

		debug       => 0,
		withlog     => 1,
		verbose     => 0,
		log_fmt     => __PACKAGE__."::curl %s\n",

		# settings for HTTP header
		method      => 'get',
		agent       => undef, #'Mozilla/5.0',
		header_out  => undef,
		header_in   => undef,
		auth        => undef,
		referer     => 0,
		@_ # override settings
	};
	return bless($o, $class);
}

sub get {
	my $o = shift or confess "this is an object method";
	my $url = shift or confess "url must set";

	my ($cgiparam, $prevurl) = (undef, $o->{prevurl});
	my $file_out = sprintf $o->{output_fmt}, $o->{seq}++;
	my $file_err = "/tmp/th.WebAgent.pm.$$";

	my @cmd = ($o->{'tool'});

	push @cmd, @_ if @_;

	if ($o->{method} =~ /^post$/i) {
		($url, $cgiparam) = split /\?/, $url, 2;
	}

	if ('curl' eq $o->{'tool'}) {
		push @cmd, '--stderr', $file_err	if $file_err and $file_err ne '-';
		push @cmd, '-o', $file_out		if $file_out;
		push @cmd, '-d', $cgiparam		if $cgiparam;
		push @cmd, '-u', $o->{auth}		if $o->{auth};
		push @cmd, '-A', $o->{agent}		if $o->{agent};
		push @cmd, '-e', $o->{prevurl}		if $o->{prevurl} and $o->{referer};
		push @cmd, '-b', $o->{header_in}	if $o->{header_in};
		push @cmd, '-D', $o->{header_out}	if $o->{header_out};
	}

	push @cmd, $url;

	if ($o->{withlog}) {
		printf STDERR $o->{log_fmt}, "@cmd";
	}
	unless ($o->{debug}) {
		system @cmd;
		if($? == 0) {
			printf STDERR $o->{log_fmt}, "success";
			system('tail', '-1', $file_err) if $o->{verbose};
			$o->{output} = $file_out;
		} else {
			printf STDERR $o->{log_fmt}, "failed";
			system('cat', $file_err) if $o->{verbose};
			$o->{output} = undef;
		}
		unlink $file_err;
	} else {
		$o->{output} = $file_out;
	}

	($o->{prevurl}) = split(/\?/, $url);
}

sub post {
	my $o = shift or confess "this is an object method";
	my $url = shift or confess "url must set";
	my $cgiparam = undef;
	($url, $cgiparam) = split /\?/, $url, 2;
	if ('curl' eq $o->{tool}) {
		if ($cgiparam) {
			$o->get($url, '-d', $cgiparam);
		} else {
			$o->get($url);
		}
	} else {
		croak __PACKAGE__.": unknown tool '$o->{tool}'";
	}
}

sub html_parser {
	my $output = shift;
	my $fmt = shift;
	return undef unless defined $output and -f $output;

	open my $fh, "<$output" or die "open file '$output' failed";
	my $t = do {local $/; <$fh>};
	close $fh;

	my ($invisable) = ('title|script');
	$t =~ s{<\s*($invisable)[^>]*>.*?</\s*\1[^>]*>}{}igs;
	$t =~ s{<\s*/?\s*br[^>]*>}{<p>}sg;
	$t =~ s{<\s*/\s*tr[^>]*>}{<p>}sg;
	$t =~ s{<\s*/\s*td[^>]*>}{ | }sg;
	$t =~ s{<[^p>][^>]*>|&....;}{ }igs;
	$t =~ s{\s+}{ }sg;
	$t =~ s{<\s*p\s*>}{\n}sg;
	$t =~ s{([| \t\r]*\n)+}{\n}sg;
	return join("\n", map { sprintf $fmt, $_ } split(/\n/, $t))."\n";
};

1;
