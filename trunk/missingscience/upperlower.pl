#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use LWP::Simple;
use open ':utf8'; # input/output in unicode
undef $/;

my (@letters, $text, $address, @entries, $word, $name, $letter);
my ($counter, %upper, %lower, %all, %done, @words, $freq, $link);
my ($low, $up);

@letters=("0", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",  "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",  "X", "Y", "Z");

# Start with a file containing a large list of words and their frequency
# (obtained say by parsing all the math articles)
# Write all the words that show up more in lower case to one file 
# and words that show up more in upper case to another file).
# This is a simple way of distinguishing proper words.

open (FILE, "<:utf8", "Word_frequency.txt"); $text = <FILE>; close (FILE);
@words = split ("\n", $text);
foreach $word (@words){
  next unless ($word =~ /^(.*?)\s+(\d+)/);
  $word=$1; $freq=$2;
  $low = lc($word); 
  
  $lower{$low}=0 if (! exists $lower{$low});
  $upper{$low}=0 if (! exists $upper{$low});
  
  if ( $word =~ /^[A-Z]/){
   $upper{$low} = $upper{$low} + $freq;
  }else{
   $lower{$low} = $lower{$low} + $freq;
  }
}
open (FILE, ">:utf8", "Upper.txt");
foreach $low ( sort { $upper{$b} - $lower{$b} <=> $upper{$a} - $lower{$a} } keys %lower) {  
 
  $freq=$upper {$low} - $lower{$low};
  last if ( $freq <= 0 );
  $low =~ s/^(.)/uc($1)/eg;
  print FILE "$low $freq\n";
}
close(FILE);


open (FILE, ">:utf8", "Lower.txt");
foreach $low ( sort { $upper{$a} - $lower{$a} <=> $upper{$b} - $lower{$b} } keys %lower) {  

  $freq=-($upper {$low} - $lower{$low});
  last if ( $freq < 0 );
  print FILE "$low $freq\n";
}
close(FILE);



