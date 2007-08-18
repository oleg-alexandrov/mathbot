#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
undef $/; # undefines the separator. Can read one whole file in one scalar.

MAIN: {


  my ($text, $top, $body, $bottom);
  
  my $file_in = 'changes.html';
  my $file_out = 'changes_out.html';

  open(FILE, "<$file_in");
  $text = <FILE>;
  close(FILE);
  
  ($top, $body, $bottom) = &extract_top_body_bottom($text);

  &parse_body ($body);
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

  my ($body, $line, @lines, $day, $marker);

  $body = shift;

  $marker = "\<img src=\"\/skins-1.5\/common\/images\/Arr_.png\"";
  @lines = split("<br.*?>\\s*", $body);

  $day = "";
  
  foreach $line (@lines){

    # current day
    if ($line =~ /\<h4\>(.*?)\<\/h4\>/){
      $day = $1;
    }

    next unless ($line =~ /(\Q$marker\E.*?)$/s);
    $line = $1;
    
    print "--------\n$line\n------------\n";
  }
}
