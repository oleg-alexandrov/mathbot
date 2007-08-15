#!/usr/bin/perl
use strict;                            # 'strict' insists that all variables be declared
use diagnostics;                       # 'diagnostics' expands the cryptic warnings
use LWP::Simple;

my $base='http://planetmath.org/';
my ($level, $file);
undef $/; #read the whole file in a line

chdir "data";

my $text = get('http://planetmath.org/browse/objects/');
open (FILE, ">ZZZ0.txt");
print FILE "$text\n";
close(FILE);

for ($level=0 ; $level < 5 ; $level++){
  my @files=split("\n", `ls ZZZ$level*`);
  foreach $file (@files){
    $file =~ s/\n//g;
    print "$file----------\n";
    &get_level($file, $level+1, $base);
  }

  print "----------\n";
}

sub get_level{
  my ($file, $level, $base)=@_;
  my ($contents, @lines, $url, $text);
  
  open FILE, "<$file";
  $contents=<FILE>;
  close(FILE);

  $contents =~  s/\<\/?font.*?\>//g;
  $contents =~  s/\n//g;
  $contents =~  s/\<tr.*?\>/\n/g;
  $contents =~  s/\<\/?tr.*?\>//g;

  @lines=split("\n", $contents);

  foreach (@lines) {
    next if (! /\/browse\//);
    #  print "--$_--\n";
    next unless (/(browse\/objects\/.*?)\".*?\<td\>.*?\<td\>(.*?)\</);
    $url="$base" . "$1";
    $contents="ZZZ$level" . "000" . "$1" . "$2";
    $contents =~ s/\//_/g;
    $contents =~ s/ /+/g;
    print "$url -- $contents\n";

    $text=get($url);
    open (FILE, ">$contents");
    print FILE "$text\n";
    close(FILE);
  }
}
