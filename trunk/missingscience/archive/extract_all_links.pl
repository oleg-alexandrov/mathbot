#!/usr/local/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
undef $/; # undefines the separator. Can read one whole file in one scalar.

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use File::Find;
require "bin/read_from_write_to_disk.pl";

my %all_links;

MAIN:{

  my (@dirs, $link);

  @dirs = (
	   '/m1/aoleg/wp/articles/',
	   '/m1/aoleg/wp/missingscience/Wikipedia:Missing_science_topics/',
	   '/m1/aoleg/wp/missingscience/Wikipedia:Requested_articles/');
  find(\&extract_links, @dirs);
  
  open (FILE, ">", "All_links.txt");
  foreach $link (sort { $a cmp $b } keys %all_links){
    print FILE "\[\[$link\]\] -- $all_links{$link}\n";
  }
  close(FILE);
}

sub extract_links{

  my ($file, $text, @local_links, $link);
  
  $file = $File::Find::name;
  return unless ($file =~ /\.wiki/);

  if (! -e $file){
    print "There's an error! $file does not exist!!!\n";
    exit(0);
  }
  
  print "File is $file\n";
  open(FILE, "<$file");
  $text = <FILE>;
  close(FILE);
  
  @local_links = ($text =~ /\[\[\s*(.*?)\s*[\#\|\]]/g);
  foreach $link (@local_links){
    
    next if ($link =~ /^\s*$/); # ignore empty links
    next if ($link =~ /:/);     # look only at links in the article namespace
    
    $link =~ s/^(.)/uc($1)/eg;
    $link =~ s/_/ /g;
    
    $all_links {$link}++;
  }

}
