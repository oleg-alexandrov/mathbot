#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use LWP::Simple;
use open ':utf8'; # input/output in unicode
undef $/;

my (@letters, $text, $address, @entries, $word, $name, $letter);
my ($counter, %upper, %lower, %all, %done, @words, $freq, $link);
my ($low, $up, $sep, $line, %alterns, $file, $seccount, $entry, $redirto);

@letters=("0", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",  "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",  "X", "Y", "Z");

open (FILE, "<:utf8", "Lower.txt"); $text = <FILE>; close (FILE);
@words = split ("\n", $text);
foreach $word (@words){
  next unless ($word =~ /^(.*?)\s+(\d+)/);
  $word=$1; $freq=$2;
  $lower{$word}=$word;
}

open (FILE, "<:utf8", "Upper.txt"); $text = <FILE>; close (FILE);
@words = split ("\n", $text);
foreach $word (@words){
  next unless ($word =~ /^(.*?)\s+(\d+)/);
  $word=$1; $freq=$2;
  $low=lc($word);
  $lower{$low}=$word;
}

open (FILE, "<:utf8", "MW_redirs.txt");
@entries = split ("\n", <FILE>);
close(FILE);

open (FILE, ">:utf8", "MW_redirs.txt");
foreach $entry (@entries){
  next unless ($entry =~ /\[\[(.*?)]].*?\[\[(.*?)\]\]/);
  $name = $1; $redirto=$2;
  
  $name =~ s/\b(.*?)\b/&fix_case($1, \%lower)/ge; $name =~ s/^(.)/uc($1)/ge;
  $redirto =~ s/\b(.*?)\b/&fix_case($1, \%lower)/ge; $redirto  =~ s/^(.)/uc($1)/ge;
  print FILE "* \[\[$name\]\] redirects to \[\[$redirto\]\]\n";
}
close(FILE);

sub fix_case {
 my $chunk=shift;
 my $hash=shift;
 my $chunklo = lc ($chunk); 
 if ( exists $hash->{$chunklo} ){
   $chunk = $hash->{$chunklo};
 }
 return $chunk;
}
