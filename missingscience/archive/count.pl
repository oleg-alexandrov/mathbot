#!/usr/local/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
use WWW::Mediawiki::fetch_submit; # my own packages, this and the one below
use WWW::Mediawiki::fetch_submit_nosave; # my own packages, this and the one below
use WWW::Mediawiki::wikipedia_login;

#use encoding 'utf8';
#use open ':utf8';	      # input/output in unicode
undef $/;		      # undefines the separator. Can read one whole file in one scalar.

# use main to avoid the curse of global variables
MAIN: {
 
 my ($red, $i, $file, $text, @lines, %count, $line, @entries, $blue, $redcount, $bluecount, @files);
  
  $red='Wikipedia:Missing_science_topics/Maths';
  $blue='Wikipedia:Missing_science_topics/ExistingMath';

  $text = "";
  for ($i=1 ; $i <=30; $i++){
    $file=$red . $i . ".wiki";
    open (FILE, "<", $file); $text = $text . "\n" . <FILE>; close (FILE);   
  }
    
 @lines = split ("\n", $text);
 $redcount=0;
 foreach $line (@lines){
   next unless ($line =~ /\[\[(.)/);
   $redcount++;
  }
 print "Total redlinks: $redcount\n";

 @files = <$blue*>;
 $text = ""; 
 foreach $file (@files){
   open (FILE, "<", $file); $text = $text . "\n" . <FILE>; close (FILE);   
 }
 @lines = split ("\n", $text);

 $bluecount=0;
  foreach $line (@lines){
    next unless ($line =~ /\[\[(.)/);
    $bluecount++;
  }
 print "Total bluelinks: $bluecount\n";
 print "Total= ", $bluecount + $redcount, "\n";
 print "Percentage= " . 100*$bluecount/($redcount+$bluecount);
}  

