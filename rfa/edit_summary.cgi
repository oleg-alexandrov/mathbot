#!/usr/bin/perl

use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings

use lib '../modules/';
require 'bin/cgi-lib.pl';
require 'parse_edits.pl';

MAIN: {

  # obligatory first print line in a cgi script
  print "Content-type: text/html\n\n";

  # flush the buffer each line
  $| = 1; 

  my (%input, $user, $lang, $base, $editsum);
  
  # Read in all the variables set by the web form
  &ReadParse(\%input);
  $user=$input{'user'}; 
  $lang=$input{'lang'}; 
    
  &print_head();

  $base=150;
  $editsum=&parse_edits($user, $lang, $base);
  print "$editsum\n";

  print '<hr><a href="../../../wp/rfa/edit_summary.html">Find the edit summary usage of another editor.</a>' . "\n";
  &print_foot();
  
}


sub print_head {
    print '<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
</head>
<body>

';

}

sub print_foot {
  print '
</body></html>

';
}

