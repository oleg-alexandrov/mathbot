#!/usr/bin/perl
use strict;                            # 'strict' insists that all variables be declared
use diagnostics;                       # 'diagnostics' expands the cryptic warnings

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/perlwikipedia_utils.pl'; # my own packages, this and the one below
require 'bin/perlwikipedia_utils.pl';

undef $/; # undefines the separator. Can read one whole file in one scalar.
use open 'utf8';             # input/output in unicode

# Fetch the current planetmath entries from Wikipedia.
# Those are considered "old", since we will merge those pages
# with updated versions of the lists from PlanetMath.
MAIN: {
  
  my ($sleep, $attempts, $Editor, $file, $text, $path, @files);
  
  $sleep = 1; $attempts=500; # necessary to fetch data from Wikipedia and submit
  $Editor=wikipedia_login();

  # Go to the working directory
  chdir 'data';

  $path = 'Wikipedia:WikiProject Mathematics/PlanetMath Exchange/';

  $file = $path . 'Table of topics.wiki';
  $text=wikipedia_fetch($Editor, $file, $attempts, $sleep); 

  @files = ($text =~ /\[\[(\Q$path\E.*?)(?:\||\]\])/g);
  foreach $file (@files){

    $file =~ s/^.*\///g;
    $file = $file . '.wiki';
    $file =~ s/ /_/g;
    
    $text=wikipedia_fetch($Editor, $path . $file, $attempts, $sleep); 

    print "Will write to $file\n\n\n\n";
    open(FILE, ">$file");
    print FILE "$text\n";
    close(FILE);
    
  }
}
 

