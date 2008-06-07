#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
undef $/; # undefines the separator. Can read one whole file in one scalar.

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/identify_redlinks.pl';
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
require 'bin/fetch_articles_cats_old.pl';
require 'bin/html_encode_decode.pl';
require 'bin/get_html.pl';
require '../sectioning.pl';

# use main to avoid the curse of global variables
MAIN: {

  my ($text, $sleep, $attempts, $edit_summary, $wiki_page, $new_text);
  my (@rl, @bl, %redlinks, %bluelinks, $link, $link1, $link2, $line, $wiki_article);
  $sleep = 2; $attempts = 10;
  
  open(FILE, "<Synonyms.txt"); $text = <FILE>; close(FILE);
  $text =~ s/(\[\[)\s*(.)(.*?)\s*(\]\])/$1 . uc($2) . $3 . $4/eg;

  &wikipedia_login();

  $edit_summary = "Some links, for testing.";
  $wiki_page = "User:Mathbot/Page3.wiki";
#  &wikipedia_submit($wiki_page, $edit_summary, $text, $attempts, $sleep);

  $wiki_article = $wiki_page; $wiki_article =~ s/\.wiki$//g;
  &identify_redlinks ($wiki_article, \@rl, \@bl);
  foreach $link (@rl) {
    $redlinks{$link} = 1;
  }
  foreach $link (@bl) {
    $bluelinks{$link} = 1;
  }

  $new_text = "";
  foreach $line (split ("\n", $text)){
    next if ($line =~ /\$/); # ignore ugly article names having math formulas
    
    next unless ($line =~ /\[\[(.*?)\]\].*?\[\[(.*?)\]\]/);
    $link1 = $1; $link2 = $2;

    if (exists $redlinks{$link1} && exists $bluelinks{$link2}){
      $new_text .= "# [[$link1]] -------- [[$link2]]\n"; # keep the exact number of dashes, for another program

    }elsif (exists $redlinks{$link2} && exists $bluelinks{$link1}){
      $new_text .= "# [[$link2]] -------- [[$link1]]\n"; # keep the exact number of dashes, for another program
    }
  }

  $new_text = &sectioning ($new_text);
  
  $wiki_page = "User:Mathbot/Page4.wiki";
  &wikipedia_submit($wiki_page, $edit_summary, $new_text, $attempts, $sleep);
    
}
