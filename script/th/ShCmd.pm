package th::ShCmd;
#	automatic run sub by system, if sub is not found.

BEGIN {
	require Exporter;
	our @ISA	= qw(Exporter);
	our @EXPORT	= qw(AUTOLOAD);
	our @EXPORT_OK	= qw();
	our $VERSION	= 1.00;
	our %EXPORT_TAGS= (proto => [qw(echo who ls date)]);
	Exporter::export_ok_tags('proto');
}

sub AUTOLOAD {
	my $program = our $AUTOLOAD;
	$program =~ s/.*:://; # trim package name
	system($program, @_);
}

sub date (;$$);
sub who (;$$$$);
sub ls;
sub echo ($@);

1;
