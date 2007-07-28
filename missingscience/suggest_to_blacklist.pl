#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules

use WWW::Mediawiki::Client;   # upload from Wikipedia
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
require 'bin/strip_accents.pl';
require 'google_links.pl';
use Encode;

undef $/;		      # undefines the separator. Can read one whole file in one scalar.

MAIN: {

  my ($text, @lines, @links, $i);
  
  open (FILE, "<", $ARGV[0]);
  $text = <FILE>;
  close(FILE);
  
  
  @lines = split ("\n", $text);
  foreach (@lines){
    next unless (/\[\[(.*?)\]\]/);
    $_ = $1;
    if (/[a-z0-9][A-Z]/ || /-$/ || /[a-zA-Z]\d/){
      print "\* \[\[$_\]\]\n";
    }
  }
#  print "$text\n";

}


