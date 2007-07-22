#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
use Encode;
use Unicode::Normalize;
use utf8;
use Encode 'from_to';
require 'google_links.pl';
require "identify_red.pl";
require 'merge_bluetext.pl';
require 'sectioning.pl';

undef $/;		      # undefines the separator. Can read one whole file in one scalar.

##########
### fix the rm_red to be robust!
### Never run this without supervision!
### Never run without preliminary tests on User:Mathbot/Pagex!
### Encodings at PlanetMath are screwed!

MAIN: {

  my ($spcount, $text, @red, %hash, @split, $prefix, $file, $maintext, @lines, @entries, $line, $key, $i, $letter);
  my ($subject, %red, %blue, $oldtext, $newtext, $fileno, $diffs, %blacklist, %case, $sep, %possib_links);

  &wikipedia_login();
  
  @split = ("ant", "ber", "bru", "che", "con", "cur", "dio", "ell", "fab", "fro", "gra", "her", "imb", "jac", "lag",
	    "lio", "mat", "muk", "nro", "par", "pol", "pyt", "reg", "sch", "sin", "sta", "tak", "tri", "vit", "zzzzzzzzzzz");
  
  $prefix='Wikipedia:Missing_science_topics/Maths';

  # 0. Read data allowing us to create alternative cases for links
  &read_upper_lower(\%case);  
  $sep = " X9ko4ApH60 "; # weird thing
  &read_all_possible_links("All_possib.txt", \%possib_links, $sep); # will add alternatives with different case 

  # 1. Read data
  &read_blacklist(\%blacklist);
  $fileno=30; $oldtext="";
  for ($i=1 ; $i <=$fileno; $i++){
    $file=$prefix . $i . ".wiki";
    $text=&fetch_file_nosave($file, 10, 2);
    # open (FILE, "<", $file); $text = <FILE>; close (FILE);   
    # &submit_file_nosave("User:Mathbot/Page$i.wiki", "A list, to test my bot.", $text, 10, 1); `sleep 5`;
    $oldtext = $oldtext . "\n" . $text;
  }
  @lines = split ("\n", $oldtext);
  
  open (FILE, "<", "New.txt");
  @lines = (@lines, split ("\n", <FILE>));
  close(FILE);

  # 2. Put all data in a hash
  foreach $line (@lines){
    $line =~ s/\<img.*?\>/\?\?\?/ig;
    next if ($line =~ /\?\?\?/);
    next if ($line =~ /\.\.\.\s*\]\]/); # rm links which are not complete
    $line =~ s/\[\[\s*/\[\[/g; $line =~ s/\s*\]\]/\]\]/g; # strip extra spaces
    $line =~ s/\"//g; # strip quotes
    $line =~ s/(\[\[.)/uc($1)/eg; # upcase

    next unless ($line =~ /^[\#\*]\s*\[\[(.*?)\]\]/);
    $key = $1; $key = &strip_accents($key); $key =~ s/^[^\w]*//g;
    next unless ($key =~ /^\w/);
    next if (exists $blacklist{$key});
       
    $line =~ s/\s*\<\!--\s*bottag\s*--\>.*?$//g; # strip google links
    $line =~ s/^[\*\#]\s*/\# /g;
    
    if (exists $hash{$key}){
      $hash{$key} = &do_merge ($hash{$key}, $line);
    }else{
     $hash{$key} = $line; 
   }
    
    # add alternative capitalizations (complicated function)
    $hash{$key} = &add_alternatives($hash{$key}, \%case, \%possib_links, $sep); # this line is screwed
    $hash{$key}=&add_google_links($hash{$key}); # search links at the end
  }

  # 3 Cut the hash in chunks and submit
  $hash{"\x{2002}"}=1; # an artificial entry, with the key a character bigger than z
  $newtext=""; $maintext=""; $spcount=1; 
  foreach $key (sort {$a cmp $b} keys %hash){
    
    if ($spcount <= $fileno && $split[$spcount-1] lt $key){ # close the file, submit, open new one

      # This code WILL cause trouble if server is down!!!!!!!!!
#       &identify_red(\%red, \%blue, $maintext); 
#       $maintext=rm_blue (\%red, $maintext);
      $maintext = &sectioning($maintext);
      $maintext = "{{TOCright}}\n" . $maintext;

      $prefix='User:Mathbot/Page';
#      $prefix='Wikipedia:Missing_science_topics/Maths';
      $subject='Rm bluelinks.';
      &submit_file_nosave("$prefix$spcount.wiki", $subject, $maintext, 10, 5);
      open (FILE, ">", "$prefix$spcount.wiki");    print FILE "$text\n";    close(FILE);
      $newtext = $newtext . $maintext; $maintext="";
      $spcount++;
    }

    $maintext = $maintext . $hash{$key} . "\n";
  }

  $diffs=&see_diffs ($oldtext, $newtext);
  &submit_file_nosave("User:Mathbot/Page11.wiki", "Changes to [[WP:MST]]", $diffs, 10, 5);
  print "Diff is:\n$diffs\n";

  &print_bluelinks(\%hash, \%blue);
}

sub do_merge {

  my ($p, $q, %map, @entries, $entry, $counter);
  $p = shift; $q =shift;
  $p = "$p $q";
  @entries = ($p =~ /\[\[(.*?)\]\]/g);

  $counter = 0;
  $p = "# ";
  foreach $entry (@entries){
    $counter++;
    next if (exists $map{$entry}); # did this before
    if ($counter ==1){
      $p = "$p" . "\[\[$entry\]\] possibly "; 
    }else{
      $p = "$p" . "\[\[$entry\]\] or "; 
    }
    $map{$entry}=1;
  }

  $p =~ s/\][^\]]*?$/\]/g; # strip all beyond last links
  return $p;
}

sub html_encode {
  local $_=$_[0];
  s/ /_/g;
  s/([^A-Za-z0-9_\-.:])/sprintf("%%%02x",ord($1))/eg;
  return($_);
}

sub html_decode {
  local $_ = shift;
  s/_/ /g;
  tr/+/ /;
  s/%(..)/pack('C', hex($1))/eg;
  return($_);
}

# will live a string with nothing but letters and digits (unless the number contains no letters and no digits)
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

sub rm_blue {

  my ($reds, $text, @lines, $entry, @entries, $blue, $line);

  $reds=shift; $text=shift;
  @lines = split ("\n", $text);
  $text="";
  foreach $line (@lines){
    
    $line = "$line\n" unless ($line =~ /^\s*$/);
    if ($line =~ /\[\[.*?\]\]/){
      @entries = ($line =~ /\[\[(.*?)\]\]/g);
      foreach $entry (@entries){
	$entry =~ s/^(.)/uc($1)/eg; #upper case
	if (! exists $reds->{$entry}){  # on this line there is a link which is not red
	  $blue=$entry;
	  $line = ""; # rm this line from our text
	  last; # done with this loop
	}
      }
    }
    $text = $text . $line;
  }
  return $text;
}

sub see_diffs {
  
  my ($o, $n, @old, @new, %Old, %New, $result);

  $o = shift; $n = shift;
  $o =~ s/(\[\[.)/uc($1)/eg;
  
  @old=split("\n", $o);
  @new=split("\n", $n);

  foreach (@old){
    next unless (/\[\[(.*?)\]\]/); 
    $Old{$1}=$_;
  }

  foreach (@new){
    next unless (/\[\[(.*?)\]\]/);
    $New{$1}=$_;
  }
  
  $result="==Removed==\n";
  foreach (sort {$a cmp $b} keys %Old){
    if (! exists $New{$_}){
      $result = $result . "$Old{$_}\n";
    }
  }

  $result = $result . "==Added==\n";
  foreach (sort {$a cmp $b} keys %New){
    if (! exists $Old{$_}){
      $result = $result . "$New{$_}\n";
    }
  }
  return $result; 
}  
  
sub read_blacklist {
  my ($blacklist, $file, @lines, $key);
  $blacklist=shift;
  
  $file='Wikipedia:Missing_science_topics/Blacklisted.wiki';
  open (FILE, "<$file");  @lines = (@lines, split ("\n", <FILE>));  close(FILE);

  foreach (@lines){
    next unless (/^\*\s*\[\[(.*?)\]\]/);
    $key = $1; $key = &strip_accents($key); $key =~ s/^[^\w]*//g;
    next unless ($key =~ /^\w/);
    $blacklist->{$key}=1;
#    print "$key\n";
  }
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


# add alternative capitalization
sub add_alternatives{

  my ($name, $case, @choices, %norepeat, $all_possib, $sep, $count, $line);
   $name = shift; $case = shift; $all_possib = shift; $sep=shift;

  # name has already a lot of links anyway, put them in choices, and let $name be also first choice, or second if possible
  $name =~ s/(\[\[.)/uc($1)/eg;
  $name =~ s/\s+/ /g;
  @choices= ($name =~ /\[\[(.*?)\]\]/g);
  if ($#choices >= 1){
    $name = $choices[1];
  } elsif ($#choices >= 0 ){
    $name = $choices[0];
  }
  $name =~ s/^(.)/uc($1)/eg;

  @choices = (@choices, $name); # well, if $name has no links after all, so @choices is empty, put $name in there

  $name=~ s/\b(.*?)\b/&fix_case($1, $case)/ge;
  $name =~ s/^(.)/uc($1)/ge;
  @choices = (@choices, $name);

  $name = lc ($name); $name =~ s/^(.)/uc($1)/ge;
  @choices = (@choices, $name);

  $name = lc ($name);
  if (exists $all_possib->{$name}){
    @choices = (@choices, split ($sep, $all_possib->{$name}));
  }

  $count = 1; $line = "# ";
  foreach (@choices){
    next if (exists $norepeat{$_});
    if ($count == 1){
      $line = $line . "\[\[$_\]\] possibly ";
    }else{
      $line = $line . "\[\[$_\]\] or ";
    }
    $norepeat{$_}=1; $count++;
  }
  $line =~ s/\s*\w+\s*$//g;
#  print "$line\n" if ($count >4);
  return $line;
}

sub read_upper_lower {

  my (@words, $word, $freq, $text, $case, $low);

  $case=shift;

  open (FILE, "<", "Lower.txt"); $text = <FILE>; close (FILE);
  @words = split ("\n", $text);
  foreach $word (@words){
    next unless ($word =~ /^(.*?)\s+(\d+)/);
    $word=$1; $freq=$2;
    $case->{$word}=$word;
  }

  open (FILE, "<", "Upper.txt"); $text = <FILE>; close (FILE);
  @words = split ("\n", $text);
  foreach $word (@words){
    next unless ($word =~ /^(.*?)\s+(\d+)/);
    $word=$1; $freq=$2;
    $low=lc($word);
    $case->{$low}=$word;
  }

}

sub read_all_possible_links {

  my ($file, $hash, $sep)=@_;
  my $link;

  open (FILE, "<", $file);
  foreach (split ("\n", <FILE>)){
    next unless (/\[\[\s*(.*?)\s*\]\]/);
    $link = $1; $link =~ s/^(.)/uc($1)/eg;

    if (! exists $hash->{lc($link)}){
      $hash->{lc($link)} = "";
    }
    $hash->{lc($link)}= $hash->{lc($link)} . $link . $sep;
  }
  close(FILE);

  foreach (keys %$hash){
    $hash->{$_} =~ s/$sep$//g;
#    print "$hash->{$_}\n";
  }
}

sub print_bluelinks {
  my ($hash, $blue, $text, $key, $line, $entry, @entries, $link, $bluetext, $total_blues, $existing_prefix);
  my ($index);
  
  $hash =shift; $blue = shift;
  $bluetext = ""; 
  foreach $key ( sort {$a cmp $b} keys %$hash){

    $line = $hash->{$key};
    next unless ($line =~ /\[\[.*?\]\]/);
    @entries = ($line =~ /\[\[(.*?)\]\]/g);
    $line = "";
    foreach $link( @entries){
      next unless (exists $blue->{$link});
      $line = $line . "\[\[$link\]\] or ";
    }
    next if ($line =~ /^\s*$/);
    $line =~ s/\s*or\s*$//g;
    $bluetext = $bluetext . "* $line\n";
  }

  $index = 'Wikipedia:Missing_science_topics';
  $existing_prefix = $index . '/ExistingMath';
  
  $total_blues = &merge_bluetext_to_existing_bluetext_subpages ($existing_prefix, $bluetext);
}

