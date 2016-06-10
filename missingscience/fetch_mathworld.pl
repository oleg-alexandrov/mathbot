#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use LWP::Simple;
use open ':utf8'; # input/output in unicode

my (@letters, $text, $address, @entries, $link, $name, $letter, $counter);


@letters=("0", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",  "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",  "X", "Y", "Z");

foreach $letter (@letters){

  print "$letter\n";
  
  $address="https://mathworld.wolfram.com/letters/$letter.html";
  $text = get ($address);

  $text =~ s/.*?\<div\s+class\s*=\s*\"index\"\>//sg; $text =~ s/\s+/ /g;
  @entries = ($text =~ /\<a\s+href=\"(.*?)\".*?\>(.*?)\<\/a/sig);

  open (FILE, ">:utf8", "mathworld/Mathworld_$letter.txt");
  for ($counter=0 ; $counter <= ($#entries-1)/2  ; $counter++){
    $link=$entries[2*$counter]; $name=$entries[2*$counter+1];
    print "$link $name\n";
    print FILE "$link $name\n";
  }
  close(FILE);
  sleep 2;
  
}

   
