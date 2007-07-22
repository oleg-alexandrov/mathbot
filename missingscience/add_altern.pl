#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use LWP::Simple;
use open ':utf8'; # input/output in unicode
undef $/;

my (@letters, $text, $address, @entries, $word, $name, $letter);
my ($counter, %upper, %lower, %all, %done, @words, $freq, $link);
my ($low, $up, $sep, $line, %alterns, $file, $seccount);

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

my $number;
for ($number = 1; $number <=10; $number++) {
  print "$number\n";
  
  $file="Wikipedia:Missing_science_topics/Maths$number.wiki";
open (FILE, "<:utf8", "$file");
@entries = split ("\n", <FILE>);
close(FILE);

$sep="xk9Skf9SaOKLaD";

$seccount=1000;
open (FILE, ">:utf8", "$file");
foreach $line (@entries) {
  $seccount++;
  next unless ($line =~ /\[/);
  $line =~ s/^.*?\[+//g; 
  $line =~ s/\]\]+.*?\[\[+/ $sep /g;
  $line =~ s/\]\].*?$//g;

  %alterns=();
  $counter =0;
  $word="";
  foreach (split(" $sep ", $line)){
    $alterns{$_} =$counter++;
    $word = $_ if ($word eq "");
  }
  $word =~ s/\b(.*?)\b/&fix_case($1, \%lower)/ge; 
  $word =~ s/^(.)/uc($1)/ge;
  $alterns{$word} = $counter++  if (! exists $alterns {$word} );

  if ($seccount > 20) { 
    if ($word =~ /^(...)/){
       $letter = $1;
    }else{
      $letter = "Section"; 
    }
    print FILE "\n==$letter==\n\n";
    $seccount=0;
  }

  $word = "\#"; $counter=0;
  foreach ( sort {$alterns{$a} <=> $alterns {$b} } keys %alterns) {
    if ($counter == 0 ){
      $word = "$word\[\[$_\]\]";
      $counter=1;
    }elsif ($counter ==1){
      $word = "$word possibly \[\[$_\]\]";
      $counter=2;
    }else{
      $word = "$word or \[\[$_\]\]"; 
    }
  }
  print FILE "$word\n";
}
close(FILE);
}

sub fix_case {
 my $chunk=shift;
 my $hash=shift;
 my $chunklo = lc ($chunk); 
 if ( exists $hash->{$chunklo} ){
   $chunk = $hash->{$chunklo};
 }
 return $chunk;
}
