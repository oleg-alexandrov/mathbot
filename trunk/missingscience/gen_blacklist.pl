#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
use Encode;
require 'google_links.pl';

#use open ':utf8';	      # input/output in unicode
undef $/;		      # undefines the separator. Can read one whole file in one scalar.


# use main to avoid the curse of global variables
MAIN: {

  my ($text, $prefix, @lines, @links, $i);
  
  $prefix='Wikipedia:Missing_science_topics/Maths';
  $text = "";
  
  for ($i=1 ; $i <=30  ; $i++){

    open (FILE, "<:utf8", "$prefix$i.wiki");
    $text = $text . "\n" . <FILE>;
    close(FILE);

  }

  @lines = split ("\n", $text);
  foreach (@lines){
    next unless (/\[\[(.*?)\]\]/);
    $_ = $1;
    if (/[a-z0-9][A-Z]$/ || /-$/ || /[a-zA-Z]\d/){
      print "\* \[\[$_\]\]\n";
    }
  }
#  print "$text\n";

}


