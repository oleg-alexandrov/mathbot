#!/usr/bin/perl -w
use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use LWP::Simple;
use CGI::Carp qw(fatalsToBrowser);

use lib '/u/cedar/h1/afa/aoleg' . '/public_html/wp/modules'; # path to perl modules
require 'bin/cgi-lib.pl';
require 'bin/do_colorize.pl';

MAIN: {

  my (%input, $file);
  
  # Read in all the variables set by the form
  &ReadParse(\%input);

  # Print the header
  print "Content-type: text/html\n\n";
  &print_head();

  $file = $input{'file'};
  if ($file =~ /[^\w\.\-]/ || $file =~ /^\./ || $file !~ /\.(pl|cgi)/ || ( ! -e $file) ){
    print "Error! Can show and colorize only perl and cgi programs, and only files which actually exist in this directory!\n";
    exit(0);
  }
  
  &do_colorize($file);
  &print_foot();
  
}


sub print_head {
    print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitio
nal.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" dir="ltr" lang="en">
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

