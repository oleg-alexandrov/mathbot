#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/wikipedia_login.pl';
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/read_from_write_to_disk.pl';

$| = 1; # flush the buffer each line
undef $/; # undefines the separator. Can read one whole file in one scalar.
 
MAIN:{ 
  my (@init, @completed, @list, %hlist, $article, $file, $i, $dir, $command, $art_stripped, $attempts, $sleep, $text);
  
  if ($#ARGV < 1){
    print "Usage: $0 To_do.txt Done.txt\n";
    exit(0);
  }
  
  # read the the files to be downloaded
  open (FILE, "<$ARGV[0]");  @list=split("\n", <FILE>);  close(FILE);
  
  # rememeber what was already downloaded, not to do it again
  open (FILE, "<$ARGV[1]");
  foreach (split("\n", <FILE>)){
    next if (/^\s*$/); # ignore empty lines
    $hlist{$_}=1;
  }
  close(FILE);

  &wikipedia_login(); $sleep = 1; $attempts=500; # necessary to fetch data from Wikipedia and submit
  
  foreach $article (@list){
    
    next if (exists $hlist{$article}); # don't download what was already downloaded
    next if ($article =~ /^\s*$/);     # ignore empty lines

    $text = &fetch_file_nosave($article . '.wiki', $attempts, $sleep);
    &write_article_to_disk ($article, $text);    
    print "\n\n";
    
    $hlist{$article}=1; # record this as downloaded

     # record that this article was downloaded
     open (FILE, ">>$ARGV[1]"); print FILE "$article\n"; close (FILE);
  }
}  
  
