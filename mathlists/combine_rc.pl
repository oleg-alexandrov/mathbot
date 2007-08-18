#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use open 'utf8';
binmode STDOUT, ':utf8';

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use Date::Parse;
require 'bin/perlwikipedia_utils.pl'; # my own packages, this and the one below
require 'bin/fetch_articles.pl';
require 'strip_accents_and_stuff.pl';
require 'lists_utils.pl';
undef $/; # undefines the separator. Can read one whole file in one scalar.

MAIN: {


  my ($text, $top, $body, $bottom, $Editor, $url, $res);

  my $file_in = 'changes.html';
  my $file_out = 'changes_out.html';

#   $Editor=wikipedia_login();
#   $url = 'http://en.wikipedia.org/wiki/Special:Recentchangeslinked/List_of_mathematics_articles_%28A-C%29';
#   print "Now will do\n";
#   $res = $Editor->{mech}->get($url);
#   $text = $res->decoded_content;
#   open(FILE, ">$file_out");
#   print FILE "$text\n";
#   close(FILE);
  
#   exit(0);
  
  open(FILE, "<$file_in");
  $text = <FILE>;
  close(FILE);
  
  ($top, $body, $bottom) = &extract_top_body_bottom($text);

  $body = &parse_body ($body);

  open(FILE, ">$file_out");
  print FILE "$top\n-------\n$body\n----------\n$bottom\n";
  close(FILE);
  
}


sub extract_top_body_bottom {

  my ($text, $top, $body, $bottom, $base_url, $top_sep, $bot_sep);

  $text = shift;

  # make paths absolute
  $base_url = 'http://en.wikipedia.org/';
  $text =~ s/(<a href=")\//$1$base_url/g;

  $top_sep="Below are the last \<strong\>\\d+\<\/strong\> changes";
  $bot_sep="\<div class=\"printfooter\"\>";
  
  if ($text =~ /^(.*?)$top_sep(.*?)($bot_sep.*?)$/si){

    $top = $1; $body = $2; $bottom = $3;

  }else{

    print "Error! Can't match the top and bottom of the text to parse!\n";
    exit(0);

  }

  return ($top, $body, $bottom);
  
}

sub parse_body {

  my ($body, $line, @lines, $day, $date, $title, $text);

  $body = shift;

  # clean up the html a bit
  $body =~ s/^.*?(<h4)/$1/sig;
  $body =~ s/\&nbsp;//g; 
  $body =~ s/\<a href=\"javascript.*?\"\>//g;
  $body =~ s/\<\/?div.*?\>//g;
  
  @lines = split("\n", $body);

  $day = "";
  $text = "";
  
  foreach $line (@lines){

    # current day
    if ($line =~ /\<h4\>(.*?)\<\/h4\>/){
      $day = $1;
    }

    # strip lines not matching an entry in the recent changes
    #next unless ($line =~ /(\<img src=\"\/skins-1.5\/common\/images\/Arr_r.png\".*?)$/s);
    #                        \<img src=\"\/skins-1.5\/common\/images\/Arr_.png\"
    #$line = $1;

    #print "--\n$line\n---\n";
    #next;
    
    # Rm links to individual diffs for articles with more than one change
    # If the current line passes this test, get the date.
    # This line is the most fragile part of the code. Let us hope that
    # it has no bugs causing this to skip good lines.
    next unless ($line =~ /(\d+:\d\d)\s*\<\/tt\>.*?title=\".*?\"\>(.*?)\</);
    $date = $day . " " . $1;
    $title = $2;

    my $tmp = str2time($date);
    $tmp = localtime($tmp);
    
    print "$date --  $tmp $title\n";
    $text .= $line . "\n";

    #print "--------\n$line\n------------\n";
  }

  return $text;
}
