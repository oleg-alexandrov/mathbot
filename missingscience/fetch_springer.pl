#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use LWP::Simple;
use Encode;

#use open ':utf8'; # input/output in unicode

my (@letters, $text, $address, @entries, $link, $altern, $altern2, $letter, $counter, $a, $b, $la);


@letters=("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",  "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",  "X", "Y", "Z");

foreach $letter (@letters){

  print "$letter\n";
  
  $address="https://eom.springer.de/$letter/default.htm";
  $text = get ($address);

  if ($text !~ /All entries within $letter(.*?)$/s){
    print "Error! Can't match text here!\n";
    exit(0);
  }
  $text = $1;
  #print "$text\n";
  
  $text =~ s/\&\#160;//g; # rm any quotes
  $text =~ s/\&\#(8210|8211|8212|8213);/-/g; # Unicode dashes to normal dash
  $text =~ s/\s+/ /g; $text =~ s/\&\#(\d+);/chr($1)/eg;
#  $text=decode("iso-8859-1", $text);
  
  @entries = ($text =~ /\<a class=\"newgeneral\" href=\"\w+.htm\"\>(.*?)\<\/a\>/sig);

  open (FILE, ">:utf8", "springer/Springer_$letter.txt");
  #open (FILE, ">", "springer/Springer_$letter.txt");
  for ($counter=0 ; $counter <= $#entries; $counter++){
    $link = $entries[$counter];
    $link =~ s/^\<img.*?\>/$letter/g;
    if ($link =~ /^(.*?)\s*,\s*(.*?)$/){
      $a=$1; $b=$2;
      $la = $a; $la =~ s/^(.)/lc($1)/e;
      $altern="$b $a";
      $altern2="$b $la";
      
      $link = "* \[\[$link\]\] possibly \[\[$altern2\]\] or \[\[$altern\]\]";
    }else{
      $link = "* \[\[$link\]\]";
    }
    
    print "$link\n";
    print FILE "$link\n";
  }
  close(FILE);

#  exit(0);
  
  `sleep 5`;
  
}

   
