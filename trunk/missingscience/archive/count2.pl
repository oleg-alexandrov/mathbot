#!/usr/local/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
use WWW::Mediawiki::fetch_submit; # my own packages, this and the one below
use WWW::Mediawiki::fetch_submit_nosave; # my own packages, this and the one below
use WWW::Mediawiki::wikipedia_login;
use Encode;
require Encode;
use Unicode::Normalize;
use utf8;
use Encode 'from_to';

#use encoding 'utf8';
#use open ':utf8';	      # input/output in unicode
undef $/;		      # undefines the separator. Can read one whole file in one scalar.

# use main to avoid the curse of global variables
MAIN: {
 
 my ($prefix, $i, $file, $text, @lines, %count, $line, @entries, $blue, $redcount, $bluecount, @files, $tcount);
  
  $prefix='Wikipedia:Missing_science_topics/Maths';

  $text = "";
  for ($i=1 ; $i <=10; $i++){
    $file=$prefix . $i . ".wiki";
    open (FILE, "<", $file); $text = $text . "\n" . <FILE>; close (FILE);   
  }
    
  @lines = split ("\n", $text);

 $redcount=0; $tcount=0;
  foreach $line (@lines){
    next unless ($line =~ /\[\[(.*?)\]\]/);
    $redcount++;
    $_ = $1;
    $_ = &strip_accents($_);
    $_ = substr ($_, 0, 3);
    #    print "$_\n";

    if ($redcount >= 516){
      $redcount=0;
      $tcount++;
      print "\"$_\", ";
    }
  }
}


sub strip_accents { 

#  my ($text, @letters
  local $_=shift;

  $_=decode("utf8", $_); # must be there, don't ask why

  s/\x{2212}/-/g; # make the Unicode minus into a hyphen
  s/\x{2013}/-/g; # make the Unicode ndash into a hyphen
  s/\x{2014}/-/g; # make the Unicode mdash into a hyphen
  
  my @letters=split("", $_);
  foreach (@letters){

    ##  convert to Unicode first
    ##  if your data comes in Latin-1, then uncomment:
    #$_ = Encode::decode( 'iso-8859-1', $_ );  

   s/\xe4/a/g;  ##  treat characters \x{00E4} \x{00F1} \x{00F6} \x{00FC} \x{00FF}
   s/\xf1/n/g;  ##  this was wrong in previous version of this doc    
   s/\xf6/o/g;
   s/\xfc/u/g;
   s/\xff/y/g;

   $_ = NFD( $_ );   ##  decompose (Unicode Normalization Form D)
   s/\pM//g;         ##  strip accents

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

   s/([^\0-\x80])//g;  ##  strip everything else
   
 }
  
  $_ = join ("", @letters);
  $_=  lc($_); # make all lower case, to identify articles which differ on only case
  return $_; 
}

