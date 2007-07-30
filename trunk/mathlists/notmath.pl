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

MAIN:{

  my ($articles_from_cats_file, $all_articles_file, %articles_from_cats, %all_articles, $text, $line, $sleep, $attempts);
  my ($old_letter, $letter);
  
  $all_articles_file='All_mathematics.txt';
  $articles_from_cats_file='All_mathematics_from_cats.txt';

  open(FILE, "<$all_articles_file");  $text = <FILE>; close(FILE);
  foreach $line (split ("\n", $text)){
    next if ($line =~ /^\s*$/);
    $all_articles{$line} = 1;
  }

  open(FILE, "<$articles_from_cats_file");  $text = <FILE>; close(FILE);
  foreach $line (split ("\n", $text)){
    next if ($line =~ /^\s*$/);
    $articles_from_cats{$line} = 1;
  }

  $text = "";
  $old_letter = "";
  
  foreach $line (sort {$a cmp $b} keys %all_articles){

    next if (exists $articles_from_cats{$line});
    next unless ($line =~ /^(.)/);
    $letter = uc ($1);

    if ($old_letter ne $letter){

      $text = $text . "\n" . '==' . $letter . '==' . "\n\n";
      $old_letter = $letter;
    }

    $text = $text . '* [[' . $line . ']]' . "\n";
       
  }

  print "$text\n";
  my $Editor=wikipedia_login();  $sleep = 1; $attempts=10;
#  $text = wikipedia_fetch($Editor, $link . ".wiki", $attempts, $sleep);
  wikipedia_submit($Editor, "User:Mathbot/Page1.wiki", "Not in math categories", $text, $attempts, $sleep);
}
