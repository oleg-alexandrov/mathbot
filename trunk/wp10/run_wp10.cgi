#!/usr/bin/perl -w

use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings

use lib '../modules'; # path to perl modules
use Unicode::Normalize;
use LWP::Simple;
use CGI::Carp qw(fatalsToBrowser);

# put the instructions below early to make sure the output is seen on screen
$| = 1; # flush the buffer each line
print "Content-type: text/html\n\n";
  
require 'bin/cgi-lib.pl';
require 'wp10_routines.pl';

MAIN: {

  my (%input, $project);
  
  # Read in all the variables set by the form
  &ReadParse(\%input);

  # Print the header
  &print_head();

  #print "This service does not work for the moment. I am looking for a new home for it. Thank you for your understanding.\n";
  #exit (0);

  $project = $input{'project'};

  # for debugging, call this cgi script from the command line
  if (@ARGV && !$project){
    $project = $ARGV[0];
  }
  
  if ( !$project || $project =~ /^\s*$/){
    print "Error! Can't have an empty project!\n";
    exit(0);
  }
  
  if ( length ($project ) > 100 ){
    print "Error! Must not have projects with name over 100 characters\n";
    exit(0);
  }

  # process a bit
  $project =~ s/^\s*//g; $project =~ s/\s*$//g; 
  $project =~ s/^(.)/uc($1)/eg;
  $project = "Category:$project articles by quality";
  
  
  # run the code
  print "Will work on <b>$project</b><br><br>\n";
  &main_wp10_routine ($project);

  print "<font color=red>Done with $project!</font><br>\n";
  &print_foot();
  
}


sub print_head {
    print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitio
nal.dtd">
<html>
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


