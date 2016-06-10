#!/usr/bin/perl
use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Encode;

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/wikipedia_login.pl';
require 'bin/wikipedia_fetch_submit.pl';
require 'bin/get_html.pl';

MAIN:{

  # go through the numbers 0-9 and letters A-Z
  my ($ascii_pos, $letter, $text, $all_text, $error, $prefix, $link, @entries, $entry, $count, $info);
  my (%links, %synonyms, %redirects, $attempts, $sleep, $file, $edit_summary);
  
  $prefix = 'https://planetmath.org/encyclopedia/';

  # extract the raw html source of all planetmath lists
  $all_text = "";
  for ($ascii_pos = 48; $ascii_pos < 91  ; $ascii_pos++){

    $letter = chr ($ascii_pos);
    next unless ($letter =~ /[0-9A-Z]/);
    print "Now doing $letter\n";
    
#    $letter = "A"; # for debugging
    $link = $prefix . $letter;
    ($text, $error) = &get_html ($link);

    $all_text = $all_text . $text;
    print "sleep 1\n"; sleep 1;
#    last;
  }

  $all_text = encode('utf8', $all_text); # Unicode encoding seems to be necessary
  $all_text =~ s/\<\/td\>/\n/g; # introduce newlines to easier separate the text
#  print "$all_text\n";

  # parse the obtained text and extract the links
  @entries = ($all_text =~ /\<tr\>\<td\>(\<a href=\"\/encyclopedia\/.*?\<\/a\>.*?)\n/gi);

  $count = 0;
  foreach $entry (@entries){
    $count++;
    
    # given an image, keep just the alt part
    $entry =~ s/\<img.*?alt=\"(.*?)\".*?\/\>/$1/ig;
    
    # extract the data from $entry
    next unless ($entry =~ /^\<a href.*?\>\s*(.*?)\s*\<\/a\>\s*(.*?)\s*$/i);
    $entry = $1; $info = $2;
    $entry =~ s/^(.)/uc($1)/eg; 

    if ($info =~ /^\s*\(in\s*\<i\>\s*(.*?)\s*\<\/i\>\)/i){
      $info = $1; $info =~ s/^(.)/uc($1)/eg;
      $redirects{$entry} = $info;
      
    }elsif ($info =~ /^\s*\(=\s*\<i\>\s*(.*?)\s*\<\/i\>\)/i){
      $info = $1; $info =~ s/^(.)/uc($1)/eg;
      $synonyms{$entry} = $info;
	 
    }elsif ($info =~ /\(.*?owned/i){
      print "Error in $info!\n";
      exit(0);

    }else{
      # plain link, not a redirect nor an alternative name of same article
      $info = 1;
      $links{$entry} = $info;
    }

    #  print "$count: $entry --- $info\n\n\n";
  }

  #submit to WP
  $text = "";
  foreach $entry (sort {$a cmp $b} keys %links){
    $text = $text . '*WP: [[' . $entry . ']]' . "\n";
  }
  foreach $entry (sort {$a cmp $b} keys %synonyms){
    $text = $text . '*WP: [[' . $entry . ']]' . " is synonymous with [[" . $synonyms{$entry} . "]]\n";
  }
  foreach $entry (sort {$a cmp $b} keys %redirects){
    $text = $text . '*WP: [[' . $entry . ']]' . " is redirect to [[" . $redirects{$entry} . "]]\n";
  }

  open(FILE, ">Fetched_planetmath.txt");
  print FILE "$text\n";
  close(FILE);
  
#  &wikipedia_login(); $attempts = 10; $sleep = 2;
#  $file = "User:Mathbot/Page3.wiki";
#  $edit_summary="Submit a list of links";
#  &wikipedia_submit($file, $edit_summary, $text, $attempts, $sleep);
}


