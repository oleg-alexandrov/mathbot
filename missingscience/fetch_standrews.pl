#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use LWP::Simple;
use open ':utf8'; # input/output in unicode

MAIN:{
  my ($address, $text, @entries);
  
  $address="http://www-history.mcs.st-andrews.ac.uk/history/Glossary/index.html";
  $text = get ($address);
  #print "$text\n";

  $text =~ s/\&\#(\d+);/chr($1)/eg;
  @entries = ($text =~ /javascript:glossary\(\'.*?\'\).*?\>(.*?)\</gi);
  open (FILE, ">", "Parsed_StAndrews.txt");
  foreach (@entries){
    s/^\s*//g; s/\s*$//g;
    s/^(.)/uc($1)/eg;
    s/_/ /g;
    next if (/^\s*$/);
    next if (/ or /);
    next if (/\//);
    next if (/ I+\s*$/);
    print FILE "\* \[\[$_\]\]\n";
  }
  close(FILE);
}

   
