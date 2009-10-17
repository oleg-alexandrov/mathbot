#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use open 'utf8';

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use lib '../modules'; # path to perl modules

require 'bin/perlwikipedia_utils.pl'; # my own packages, this and the one below
require 'bin/identify_redlinks.pl';
undef $/; # undefines the separator. Can read one whole file in one scalar.
$| = 1; # flush the buffer each line

MAIN: {
  my ($text, $sleep, $attempts, $cats_file, $new_cats_file, $chunk, @chunks, $bottom, $separator);
  my ($edit_summary, $list);
  my (%redlinks_hash);
  
  # This line must be the first to print in a cgi script
  print "Content-type: text/html\n\n";

  my $Editor=wikipedia_login();
  $sleep = 1; $attempts=10;
  $separator = '<!-- separator --> <!-- Please do not delete or modify this line, as that will confuse the bot. -->';

  $cats_file="List_of_mathematics_categories.wiki";
  $new_cats_file="User:Mathbot/New math categories.wiki";

  $list = $cats_file; $list =~ s/\.wiki$//g;
  $edit_summary = "Add new categories. " . &make_redlinks_hash($list, \%redlinks_hash);
  
  $text = wikipedia_fetch($Editor, $cats_file, $attempts, $sleep);
  @chunks = split($separator, $text);
  $bottom = splice(@chunks, -1, 1); $bottom =~ s/^\s*//g;

  $text = wikipedia_fetch($Editor, $new_cats_file, $attempts, $sleep);
  foreach ( split ("\n", $text) ){
    s/(\[\[:Category:)([^\|]*?)(\]\])/$1$2\|$2$3/g; # pipe if not there yet

    s/(\[\[.*?\]\]\s*)(\(.*?\))(.*?)$/$1\<\!-- $2 --\>$3/g; # hide in comments any meta-info

    if (/^(\[\[:Category:.*?\]\].*?)\(math\)/){
      $chunks[0]=$chunks[0] . "\n$1\n";
    }  elsif (/^(\[\[:Category:.*?\]\].*?)\(mtn\)/){
      $chunks[1]=$chunks[1] . "\n$1\n";
    }  elsif (/^(\[\[:Category:.*?\]\].*?)\(other\)/){
      $chunks[2]=$chunks[2] . "\n$1\n";
    }
  }
  
  $text = "";
  foreach $chunk (@chunks){
    $text = $text .  &sort_categories_alphabetically_and_sectioning ($chunk, \%redlinks_hash) . $separator . "\n";
  }
  $text = $text .  $bottom;
  
  # Minor formatting fix. Make sure that each line that has a category
  # ends in &mdash; if the next line is also a category
  $text =~ s/(\[\[:Category:.*?\]\].*?)[ \t]*\&mdash;[ \t]*\n/$1\n/ig;
  $text =~ s/(\[\[:Category:.*?\]\].*?)[ \t]*[-]*[ \t]*\n(?=.*?\[\[:Category)/$1 \&mdash;\n/ig;

  wikipedia_submit($Editor, $cats_file, $edit_summary, $text, $attempts, $sleep);
  
  open (FILE, ">$cats_file"); print FILE "$text\n"; close(FILE); # some other programs use this data
}

sub sort_categories_alphabetically_and_sectioning {
  my ($top, $output, $text, @lines, %categories, $cat, $letter, $prev_letter, $redlinks_hash);
  $text = shift; 	
  $redlinks_hash=shift;
  
  if ($text =~ /^\s*(.*?)(\s*===.*?)$/s){
    $top=$1; $text=$2;
  }else{
   $top=""; 
  }

  @lines = split ("\n", $text);
  foreach (@lines){ 
   next unless (/^\[\[:Category:(.*?)[\]\|]/);
   $cat=$1;
   next if (exists $categories{$cat});      # avoid repetitions
   next if (exists $redlinks_hash->{$cat}); # rm categories which got deleted
   $categories{$cat}=$_;
 }  

  $output="$top\n";
  $letter=""; $prev_letter="";
  foreach ( sort { $a cmp $b } keys %categories ) {

    next unless (/^(.)/);
    $letter=$1;
    if ($letter ne $prev_letter && $letter !~ /\d/ ){ 
      $output = $output . "\n=== $letter ===\n\n";
      $prev_letter=$letter;
    }elsif ($letter =~ /\d/ && $prev_letter !~ /\d/){
      $output = $output . "\n=== 0&ndash;9 ===\n\n";
      $prev_letter=$letter;
    }
    $output = $output . "$categories{$_}\n";
  }  

  return $output;
}

sub make_redlinks_hash {
  my (@red_links, @blue_links, $list, $redlinks_hash, $red, $concatenated_reds);

  $list = shift; $redlinks_hash=shift;

  &identify_redlinks ($list, \@red_links, \@blue_links);
  
  $concatenated_reds="";
  $concatenated_reds = "Removed redlinked " if (@red_links);
  foreach $red (@red_links){
    
    $concatenated_reds = $concatenated_reds . "\[\[$red\]\], ";
    $red =~ s/^Category://ig;
    $redlinks_hash->{$red}=1;

    # Make sure this fits in the edit summary when submitted.
    last if (length ($concatenated_reds) > 100); 
  }

  $concatenated_reds =~ s/,\s*$/\./g;
  return $concatenated_reds;
}

