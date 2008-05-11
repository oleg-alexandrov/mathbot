#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
undef $/; # undefines the separator. Can read one whole file in one scalar.

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use lib $ENV{HOME} . '/public_html/wp/mathlists';
require 'bin/perlwikipedia_utils.pl';
require "read_from_write_to_disk.pl";

use open 'utf8';

# write a list of links (red and blue) showing up in math articles. For each
# link, memorize in how many articles it shows up. 
MAIN:{
  my ($Editor, $article, $text, $count, @local_links, $link, %links, @articles, %local_hash);

  $Editor=wikipedia_login();

  # get the list of math articles
  open (FILE, "<", "../All_mathematics.txt");    @articles=split ("\n", <FILE>);  close(FILE);
  open (FILE, "<", "../All_mathematicians.txt"); @articles=(@articles, split ("\n", <FILE>));  close(FILE);
  
  $count=0;
  foreach $article (@articles) {
    
    next if ($article =~ /^\s*$/); # ignore empty lines
    print "--------------------------now in $article\n";

    $text = &read_from_disk_or_wikipedia($Editor, $article);
    
    # make a local hash containing all links which show up in this article
    @local_links = ($text =~ /\[\[\s*(.*?)\s*[\#\|\]]/g);
    %local_hash=();
    foreach $link (@local_links){

      next if ($link =~ /^\s*$/); # ignore empty links
      next if ($link =~ /:/);     # look only at links in the article namespace
	 
      $link =~ s/^(.)/uc($1)/eg;
      $link =~ s/_/ /g;

      $local_hash {$link}++;
    }
   
    # adding things to %local_hash first, and to %hash later, makes 
    # sure that if a link shows up many times in an article it is
    # still counted only once in %links
    foreach $link (keys %local_hash){
       $links{$link}++;
    }
    
    # code very useful for debugging, don't delete
    $count++; 
    #last if ($count > 400);
  }

  # write to disk. Links which show up more often come on top.
  open (FILE, ">", "Links.txt");
  foreach $link ( sort { $links{$b} <=> $links{$a} } keys %links ){
    print FILE "\[\[$link\]\] -- $links{$link}\n";
  }
  close(FILE);
}
