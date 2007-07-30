#!/usr/bin/perl -w

use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Encode;

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/perlwikipedia_utils.pl'; # my own packages, this and the one below
require 'bin/fetch_articles_cats.pl';
require 'bin/html_encode_decode_string.pl';
require 'bin/get_html.pl';
require 'bin/rm_extra_html.pl';

undef $/;		      # undefines the separator. Can read one whole file in one scalar.

# A tool which reads my watchlist and tells if there are any redirects on it.
MAIN:{
  
  $| = 1; # flush the buffer each line
  
  my ($file, @files, $text, $sleep, $attempts, @tmp, $article, $cat, @articles, @red, @archives, @base_cats, @cats);
  my ($link, @links, %repeats, $logtext, $count);
     
  my $Editor=wikipedia_login();  $sleep = 1; $attempts=10;

  open(FILE, "<watchlist.html"); $text = <FILE>; close(FILE);
  
  @links = ($text =~ /title=\"(.*?)"/ig);
  $logtext = "";
  $count = 0;
  
  foreach $link (@links){
    $link = &rm_extra_html ($link);
    next if ($link =~ /:/); # not article namespace
    next if exists ($repeats{$link});
    $repeats{$link}=1;

    $text = wikipedia_fetch($Editor, $link . ".wiki", $attempts, $sleep);

    if ($text =~ /^\s*\#redirect/i){

      print "$link: $text\n";
      $logtext = $logtext . '* [http://en.wikipedia.org/w/index.php?title=' . &html_encode_string ($link) . '&redirect=no ' .  $link . ']' . "\n";
      $count++;

      if ($count > 1){
	wikipedia_submit($Editor, "User:Mathbot/Page1.wiki", "redirects", $logtext, $attempts, $sleep);
	$count = 0; 
      }

    }
  }

  wikipedia_submit($Editor, "User:Mathbot/Page1.wiki", "redirects", $logtext, $attempts, $sleep);
}
