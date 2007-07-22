#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
use LWP::Simple;
use LWP::UserAgent;
use Encode;
undef $/;		      # undefines the separator. Can read one whole file in one scalar.

# Read the springer files, and write them to a file in Wikipedia format. That requires:
MAIN: {

  my ($line, @lines, $link, $name, @letters, $letter);
  
  @letters=("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",  "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",  "X", "Y", "Z");
  
  $line="";
  foreach $letter (@letters) {
    open (FILE, "<springer/Springer_$letter.txt");
    $line= $line . "\n" . <FILE>;
    close(FILE);
  }
  
  open (FILE, ">", "Parsed_springer.txt");
  $line =~ s/\&\#(\d+);/chr($1)/eg; # convert from html to binary
  @lines=split("\n", $line);
  foreach (@lines) {
    next unless (/\[\[.*?\]\]/);
    next if (/\<img/i);
    print FILE "$_\n";
  }
 close(FILE);
}

