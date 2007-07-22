#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
use Encode;

#use open ':utf8';	      # input/output in unicode
undef $/;		      # undefines the separator. Can read one whole file in one scalar.


# use main to avoid the curse of global variables
MAIN: {

  my (%blacks, @lines, $prefix, $link, $text, $line, $i, $file);
  
  open (FILE, "<:utf8", "Wikipedia:Missing_science_topics/Blacklisted.wiki");
  @lines = split ("\n", <FILE>);
  close(FILE);
  foreach (@lines){
    next unless (/^\s*\*\s*\[\[(.*?)\]\]/);
    $blacks{$1}=1;
  }

  $prefix='Wikipedia:Missing_science_topics/Maths';

  for ($i=1 ; $i <=10  ; $i++){
    $file=$prefix . $i . ".wiki";
    
    $text=&fetch_file_nosave($file, 100, 2);
    @lines = split ("\n", $text);
    $text="";
    foreach $line (@lines){

      $line = "$line\n" unless ($line =~ /^\s*$/);
      if ($line =~ /\[\[(.*?)\]\]/){
	$link =$1;
	if (exists $blacks{$link}){
	  print "Will remove [[$link]]\n";
	  $line = ""; # rm this line from our text
	}
      }
      
      $text = $text . $line;
    }
    
    &submit_file_nosave($file, "Move some nonstandard names to [[Wikipedia:Missing_science_topics/Blacklisted]]", $text, 10, 1);
  }
}

