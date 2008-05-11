#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
undef $/; # undefines the separator. Can read one whole file in one scalar.

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/perlwikipedia_utils.pl';

use open 'utf8';

# create a list of most linked to math articles from other math articles
# mark which of those articles are rated by quality by the math wikiproject
MAIN: {

  my (@articles, %linked_freq, $line, $article, $freq, %math_hash, $text, $rated_file, $rated_file_bz2);
  my (%rated_hash, $sep, $outfile, $attempts, $sleep);
  
  chdir $ENV{'HOME'} . '/public_html/wp/mathlists/redlinks';
 
  # get the list of math articles. Put the entries in the list in a hash
  open (FILE, "<", "../All_mathematics.txt");    @articles=split ("\n", <FILE>);  close(FILE);
  open (FILE, "<", "../All_mathematicians.txt"); @articles=(@articles, split ("\n", <FILE>));  close(FILE);
  foreach $article (@articles){
    $math_hash{$article} = 1;
  }
  
  # get a list of all articles linked from math articles, with how many math articles link to each article in the list
  # of all those articles, keep only the math ones (e.g., [[English language]] is linked a lot from math articles
  # but we will ignore it for our purposes.
  open(FILE, "<Links.txt"); $text = <FILE>; close(FILE);
  foreach $line (split ("\n", $text)){

    next unless ($line =~ /^.*?\[\[(.*?)\]\].*?(\d+)\s*$/);
    $article = $1; $freq = $2; # an article, and how many times it is linked to
    
    next unless (exists $math_hash{$article});
    $linked_freq{$article} = $freq;
  }

  # now read the articles which were rated by quality as part of the math wikiproject
  # if the file containing the ratings is compressed, uncompress it
  $rated_file = '/tmp/wp10/Mathematics_articles_by_quality_old_ids';
  $rated_file_bz2 = $rated_file . ".bz2";
  if (-e $rated_file_bz2){
    print `bunzip2 -fv $rated_file_bz2` . "\n";
  }
  
  if (! -e $rated_file){
    print "$rated_file does not exist. Bailing out.\n";
    exit(0);
  }

  $sep = ' ;; ';
  open(FILE, "<$rated_file"); $text = <FILE>; close(FILE);
  foreach $line (split ("\n", $text)){

    next if ($line =~ /^\#/); # a line starting with # is a comment to be ignored
    next unless ($line =~ /^(.*?)$sep/); # there is a separator 
    $article = $1;
    $rated_hash{$article} = 1;
  }


  # create a list of all math articles linked from other math articles in the decreasing
  # frequency of being linked to. Mark articles which are not assessed yet
  $text = "";
  foreach $article (sort { $linked_freq{$b} <=> $linked_freq{$a} } keys %linked_freq){

    $text .= '# [[' . $article . ']] ([[Talk:' . $article . '|talk]]) ' . $linked_freq{$article} . ' ';
    $text .=  '<font color=red>not rated!</font>' if (! exists $rated_hash {$article} );
    $text .= "\n"; 

    # cut the list when we arrive at articles which are linked from a number of articles
    # which is less than a current threshhold.
    last if ($linked_freq{$article} <= 10);
  }
  $text = &print_header() . $text; # add a note on top

  # Write to file. 
  $outfile = 'User:Mathbot/Most_linked_math_articles.wiki';
  open(FILE, ">$outfile");  print FILE "$text\n";  close(FILE);

  # Also submit to Wikipedia.
  my $Editor=wikipedia_login();
  $attempts = 10; $sleep = 5; 
  wikipedia_submit($Editor, $outfile, "Update", $text, $attempts, $sleep);
}

sub print_header {

  return
'This is a list of mathematics articles which are most linked to from other mathematics articles (that\'s the number on the right).

The point of this list is that the more linked to an article is, the more important it probably is, and the more crucial is for it to be in good shape.

Also, articles which are not yet in [[Wikipedia:Version 1.0 Editorial Team/Mathematics articles by quality]] are pointed out.

';
  
}
