#!/usr/local/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use LWP::Simple;
use open ':utf8'; # input/output in unicode
undef $/;

my (@letters, $text, $address, @entries, $link, $name, $letter);
my ($counter, @links, %done);
@letters=("0", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",  "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",  "X", "Y", "Z");
my $wget="wget -q -O - ";

open (FILE, "<:utf8", "Done.txt"); $text = <FILE>; close (FILE);
@links = split ("\n", $text);
foreach $link (@links){
  next unless ($link =~ /^\/./);
  $done{$link}=1;
}

foreach $letter (@letters){
  open (FILE, "<:utf8", "mathworld/Mathworld_$letter.txt"); $text = <FILE>; close (FILE);
  
  @links = split ("\n", $text);
  foreach $link (@links){
   next unless ($link =~ /^(\/.*?)\s/);
   $link = $1; $address="http://mathworld.wolfram.com$link";
   next if (exists $done{$link});

   print "Fetching $address to write to articles/$link\n";
   $text = `$wget \"$address\"`;
   
   print "-- $text\n";
   open (FILE, ">:utf8", "articles/$link");
   print FILE $text;
   close (FILE);

   open (FILE, ">>:utf8", "Done.txt");
   print FILE "$link\n";
   close (FILE);
   
   $done{$link}=1;
   print "Done with $link, take a 15 second nap.\n"; 
   `sleep 15`;
  }
}

   
