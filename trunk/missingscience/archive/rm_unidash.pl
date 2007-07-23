#!/usr/local/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
use WWW::Mediawiki::fetch_submit; # my own packages, this and the one below
use WWW::Mediawiki::fetch_submit_nosave; # my own packages, this and the one below
use WWW::Mediawiki::wikipedia_login;
use Encode;
use utf8;

#use open ':utf8';	      # input/output in unicode
undef $/;		      # undefines the separator. Can read one whole file in one scalar.


# use main to avoid the curse of global variables
MAIN: {
  
  my ($prefix, $file, $text, $i, $subject);
  $prefix='Wikipedia:Missing_science_topics/Maths';

  for ($i=3 ; $i <=10  ; $i++){
    $file=$prefix . $i . ".wiki";
    
    $text=&fetch_file_nosave($file, 100, 2);
    $subject="Test my bot.";	
#    &submit_file_nosave("User:Mathbot/Page3.wiki", $subject, $text, 10, 1);

    $text=decode("utf8", $text); 
    $text =~ s/\x{2212}/-/g; # make the Unicode minus into a hyphen
    $text =~ s/\x{2013}/-/g; # make the Unicode ndash into a hyphen
    $text =~ s/\x{2014}/-/g; # make the Unicode mdash into a hyphen
    $text=encode("utf8", $text); 
    
    $subject="Convert Unicode dashes to ASCII dash, as mostly done in Wikipedia articles/redirects."; 
#    &submit_file_nosave("User:Mathbot/Page3.wiki", $subject, $text, 10, 1);
    &submit_file_nosave($file, $subject, $text, 10, 1);
  }
}

