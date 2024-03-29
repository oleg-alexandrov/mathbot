#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use lib $ENV{HOME} . '/public_html/wp/modules';
use lib $ENV{HOME} . '/public_html/wp/mathlists';
use lib '/data/project/mathbot/perl5/lib/perl5/';
use lib '/data/project/mathbot/public_html/wp/modules/lib/perl5/x86_64-linux-gnu-thread-multi';

require 'bin/perlwikipedia_utils.pl'; 
require 'bin/get_html.pl';
require 'bin/rm_extra_html.pl';
require 'read_from_write_to_disk.pl';

use open 'utf8';

# Recent changes to the [[list of mathematicians]]
MAIN:{ 

  my @letters=("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z");
  my ($article, $letter, $base, $link, $text, @articles_list, $days, $limit, %articles_hash, $error, $list_of_changes);
  my ($file, $attempts, $sleep, $edit_summary, $work_dir);

  # go to the working directory
  $work_dir=$0; $work_dir =~ s/\/[^\/]*$/\//g; chdir $work_dir;
  
  my $Editor; # not needed, kept for the sake of the api
  $attempts = 10; $sleep = 1;
  $days=2;  $limit=5000;

  $base='https://en.wikipedia.org/w/index.php?title=Special:Recentchangeslinked&target=Wikipedia:WikiProject_Mathematics/List_of_mathematicians_';
  foreach $letter (@letters){
    
    $link = $base . '%28' . $letter . '%29&hideminor=0&days=' . $days . '&limit=' . $limit;

    print "now: getting $link\n";
    ($text, $error)  = &get_html($link);
    print "sleep $sleep\n"; sleep $sleep;
  
    @articles_list = (@articles_list, ($text =~ /\<li.*?\>\s*\(\s*\<a href=\"[^\"]*?\"\s+title=\"([^\"]*?)\"/ig) );
  }

  foreach $article (@articles_list){
    $article = &rm_extra_html($article);
    next if ($article =~ /(User|Talk|Wikipedia|Template|Portal):/i);
    next if ($article =~ /^List of/i); # not a mathematician
    $articles_hash{$article}=1;
  }
  
  # create a list of all articles which changed, download those articles, and write them to disk
  $list_of_changes = "";
  foreach $article (sort {$a cmp $b} keys %articles_hash){
    
    $list_of_changes = $list_of_changes . '#[[' . $article . ']]' . "\n";
    $text = wikipedia_fetch($Editor, $article . '.wiki', $attempts, $sleep);

    &write_to_disk($article, $text);
  }
  $list_of_changes =~ s/(\[\[)(Category:.*?\]\])/$1\:$2/g;
  $file = 'User:Mathbot/Recent changes.wiki';
  $edit_summary = "Recent changes to the [[list of mathematicians]]";
  
  wikipedia_submit($Editor, $file, $edit_summary, $list_of_changes, $attempts, $sleep);
}
