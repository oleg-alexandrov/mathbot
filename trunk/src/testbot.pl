#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings

# make sure you write below the correct path to the wikipedia_perl_bot directory
use lib '/u/cedar/h1/afa/aoleg/public_html/wp/src/wikipedia_perl_bot';

use Perlwikipedia; #Note that the 'p' is capitalized, due to Perl style
require 'bin/perlwikipedia_utils.pl';

undef $/;                     # undefines the separator. Can read one whole file in one scalar.

MAIN: {

  #log in (make sure you specify a password in bin/wikipedia_login.pl)
  my $user = 'Mathbot';
  my $editor=&wikipedia_login($user);
  
  my $sleep = 2;   # how long to sleep between fetch/submit operations on Wikipedia pages
  my $attempts=10; # how many attempts one should take to fetch/submit Wikipedia pages
  
  # a file to edit. 
  my $file='Wikipedia:Sandbox';

  # fetch the wikicode of $file
  my $text = wikipedia_fetch($editor, $file, $attempts, $sleep);

  # append to it some test
  $text = $text . "\n Testing!\n";

  # submitting to Wikipedia (notice that this routine will just overwrite existing
  # Wikipedia text, it will not attempt to merge with changes which happened in between

  my $edit_summary='Just a test';
  &wikipedia_submit($editor, $file, $edit_summary, $text, $attempts, $sleep);
}

# Note: If you have problems, try to check the version of the LWP
# package (which should be installed on your system) with the command
# perl -MLWP -e 'print $LWP::VERSION'
# Version 5.50 or under does not work well, while version 5.79 works
# great.

# If you still have problems, try replacing above 'Wikipedia:Sandbox' with some other page.
