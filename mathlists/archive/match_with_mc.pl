#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
require "encode_decode.pl";

my (@mc, @wp, $url);

$url='https://www-history.mcs.st-andrews.ac.uk/history/Mathematicians/';
open (FILE, "<Mc_tutor.html");
@mc=<FILE>;
close(FILE);

open (FILE, "<Articles_shortened_list.txt");
@wp=<FILE>;
close(FILE);

my %wp_key;
foreach (@wp){
  s/\s*$//g;
  next if (/^\s*$/);

  $_ = &decode($_);
  s/_/ /g;
  
  s/\s*\(mathematician\)//ig;
  
  next unless (/[\s_]*([^\s_]+?$)/);
    
  if (exists $wp_key{$1}) {
    $wp_key{$1} = "$wp_key{$1}, [[$_]]";
  }else{
    $wp_key{$1} = "[[$_]]";
  }
    
}

my (%mc_key, $name);
foreach (@mc){
  s/\s*$//g;
  next if (/^\s*$/);

  s/--\s*//g;
  
  next unless (/^(.*?)[_\.]/);
  if (exists $mc_key{$1}) {
    $mc_key{$1} = "$mc_key{$1}, [$url$_]";
  }else{
    $mc_key{$1} = "[$url$_]";
  }
}

open (FILE, ">User:Oleg_Alexandrov/Test_page3.wiki");

foreach (keys %mc_key){
  print FILE "MacTutor: $mc_key{$_} ";

  if (exists $wp_key{$_}){
    print FILE "Wikipedia: $wp_key{$_}\n\n";
  }else{
    print FILE "Wikipedia: N/A\n\n";
  }
}

sub proj {

  $_=shift;
#  s/\'s//g;
  s/[\&,;\'\(\)]//g;
  s/[_]/ /g;
  
  my @letters=split("", $_);
  foreach (@letters){

   ##  convert to Unicode first
   ##  if your data comes in Latin-1, then uncomment:
   #$_ = Encode::decode( 'iso-8859-1', $_ );  

#    s/\xe4/ae/g;  ##  treat characters \x{00E4} \x{00F1} \x{00F6} \x{00FC} \x{00FF}
#    s/\xf1/ny/g;  ##  this was wrong in previous version of this doc    
#    s/\xf6/oe/g;
#    s/\xfc/ue/g;
#    s/\xff/yu/g;

   s/\xe4/a/g;  ##  treat characters \x{00E4} \x{00F1} \x{00F6} \x{00FC} \x{00FF}
   s/\xf1/n/g;  ##  this was wrong in previous version of this doc    
   s/\xf6/o/g;
   s/\xfc/u/g;
   s/\xff/y/g;

   $_ = NFD( $_ );   ##  decompose (Unicode Normalization Form D)
   s/\pM//g;         ##  strip combining characters

   # additional normalizations:

   s/\x{00df}/ss/g;  ##  German beta \x{201C}\x{00DF}\x{201D} -> \x{201C}ss\x{201D}
   s/\x{00c6}/AE/g;  ##  \x{00C6}
   s/\x{00e6}/ae/g;  ##  \x{00E6}
   s/\x{0132}/IJ/g;  ##  \x{0132}
   s/\x{0133}/ij/g;  ##  \x{0133}
   s/\x{0152}/Oe/g;  ##  \x{0152}
   s/\x{0153}/oe/g;  ##  \x{0153}

   tr/\x{00d0}\x{0110}\x{00f0}\x{0111}\x{0126}\x{0127}/DDddHh/; # \x{00D0}\x{0110}\x{00F0}\x{0111}\x{0126}\x{0127}
   tr/\x{0131}\x{0138}\x{013f}\x{0141}\x{0140}\x{0142}/ikLLll/; # \x{0131}\x{0138}\x{013F}\x{0141}\x{0140}\x{0142}
   tr/\x{014a}\x{0149}\x{014b}\x{00d8}\x{00f8}\x{017f}/NnnOos/; # \x{014A}\x{0149}\x{014B}\x{00D8}\x{00F8}\x{017F}
   tr/\x{00de}\x{0166}\x{00fe}\x{0167}/TTtt/;                   # \x{00DE}\x{0166}\x{00FE}\x{0167}

   s/[^\0-\x80]//g;  ##  clear everything else; optional

 }
  $_ = join ("", @letters);
  
  return lc($_);
}
