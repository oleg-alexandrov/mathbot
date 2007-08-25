#!/usr/bin/perl
use strict;                            # 'strict' insists that all variables be declared
use diagnostics;                       # 'diagnostics' expands the cryptic warnings

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/perlwikipedia_utils.pl'; # my own packages, this and the one below
require 'bin/fetch_articles.pl';

undef $/; # undefines the separator. Can read one whole file in one scalar.
use open 'utf8';             # input/output in unicode

# Fetch the existing lists of redlinks and bluelinks for WP:MST from Wikipedia.
# We will merge to them later.
MAIN: {
  
  my ($sleep, $attempts, $Editor, $file, $text, $path, @files, $count, $letter, @letters);
  
  $sleep = 1; $attempts=500; # necessary to fetch data from Wikipedia and submit
  $Editor=wikipedia_login();

  $path = 'Wikipedia:Missing science topics';

  @letters=("0", "A", "B", "C", "D", "E", "F", "G", "H", "I",
            "J", "K",  "L", "M", "N", "O", "P", "Q", "R", "S",
            "T", "U", "V", "W",  "X", "Y", "Z");

  @files = ();

  foreach $letter (@letters){
    $file = $path . '/ExistingMath' . $letter . '.wiki';
    push(@files, $file);
  }

  for ($count= 1 ; $count <= 30  ; $count++){
    $file = $path . '/Maths' . $count . '.wiki';
    push(@files, $file);
  }
  
  foreach $file (@files){
    
    print "Will fetch and write to disk $file\n\n\n\n";
    
    $text=wikipedia_fetch($Editor, $file, $attempts, $sleep); 

    open(FILE, ">$file");
    print FILE "$text\n";
    close(FILE);
  }
}
 

