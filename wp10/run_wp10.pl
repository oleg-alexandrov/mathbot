#!/usr/bin/perl -w
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings

# Some Wikipedia articles are categorized by quality.  Go through those categories, get a list of all such articles,
# and print them out in tables, sectioned by category. Also write a log of what happened, and this is the hardest. 
# See http://en.wikipedia.org/wiki/Wikipedia:Version_1.0_Editorial_Team/Index for more details.

# All the code is actually in wp10_routines.pl which we load and call below.
# It is convenient to keep things that way so that those routines can also be called from a CGI script.
require $ENV{HOME} . '/public_html/cgi-bin/wp/wp10/wp10_routines.pl'; 

$| = 1; # flush the buffer each line

MAIN:{

  # run the script
  # if it is run without any command line arguments, that is, like this:
  # ./run_wp10.pl
  # then @ARGV below is empty, and the script goes through all projects

  # if it is desired to run the script for one project only, call it as
  # ./run_wp10.pl "Adelaide articles by quality"
  # etc., so that value is then stored in @ARGV below
  
  &main_wp10_routine (@ARGV);
}



