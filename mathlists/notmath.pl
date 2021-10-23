#!/usr/bin/perl -w

use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Encode;

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/perlwikipedia_utils.pl'; # my own packages, this and the one below
require 'bin/perlwikipedia_utils.pl';
require 'bin/html_encode_decode_string.pl';
require 'bin/get_html.pl';
require 'bin/rm_extra_html.pl';

use open 'utf8';
undef $/;		      # undefines the separator. Can read one whole file in one scalar.

MAIN:{

  my ($articles_from_cats_file, $all_articles_file, %articles_from_cats);
  my (%all_articles, $text, $line, $sleep, $attempts);
  my ($old_letter, $letter, $log_file, $Editor, $edit_summary, $count);
  
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

  $text = "__NOTOC__";
  $old_letter = "";
  $count = 0;
  
  foreach $line (sort {$a cmp $b} keys %all_articles){

    next if (exists $articles_from_cats{$line});
    next unless ($line =~ /^(.)/);
    $letter = uc ($1);

    if ($old_letter ne $letter){

      $text = $text . "\n" . '==' . $letter . '==' . "\n\n";
      $old_letter = $letter;
    }

    $text = $text . '* [[' . $line . ']]' . "\n";
    $count ++;
    
  }

  print "$count articles not in math categories.\n";
  $Editor=wikipedia_login();  $sleep = 1; $attempts=10;
  $log_file = "User:Mathbot/Page1.wiki";
  $edit_summary = "Not in math categories";
  wikipedia_submit($Editor, $log_file, $edit_summary, $text, $attempts, $sleep);
}
