#!/usr/bin/perl

package main;
use strict;
use warnings;
use Data::Dumper;
use CGI;

use th::SessionFile;
use th::WebAgent;
use th::Util qw(:text color);

our $curl = th::WebAgent->curl();

1;
