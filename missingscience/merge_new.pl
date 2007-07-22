#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
require 'bin/strip_accents.pl';
use Encode;
use Unicode::Normalize;
use utf8;
use Encode 'from_to';
require 'google_links.pl';
require "identify_red.pl";
require 'sectioning.pl';

undef $/;		      # undefines the separator. Can read one whole file in one scalar.

##########
### fix the rm_red to be robust!
### Never run this without supervision!
### Never run without preliminary tests on User:Mathbot/Pagex!
### Encodings at PlanetMath are screwed!

MAIN: {

  my ($spcount, $text, @red, %hash, @split, $prefix, $file, $maintext, @lines, @entries, $line);
  my ($attempts, $sleep, $key, $i, $letter, %possib_links);
  my ($subject, %red, %blue, $oldtext, $newtext, $fileno, $diffs, %blacklist, %case, $sep);
  my ($total_blues);
  &wikipedia_login();
  
  @split = ("ant", "ber", "bru", "che", "con", "cur", "dio", "ell", "fab", "fro", "gra", "her", "imb", "jac", "lag", "lio", "mat", "muk", "nro", "par", "pol", "pyt", "reg", "sch", "sin", "sta", "tak", "tri", "vit", "zzzzzzzzzzz");
  
  $prefix='Wikipedia:Missing_science_topics/Maths';
  $attempts = 5;
  $sleep    = 5;
  
  # 0. Read data allowing us to create alternatives with different case for links
  &read_upper_lower(\%case);  
  $sep = " X9ko4ApH60 "; # weird thing
  &read_all_possible_links("All_possib.txt", \%possib_links, $sep); 

  # 1. Read data
  &read_blacklist(\%blacklist);
  $fileno=30; $oldtext="";
  for ($i=1 ; $i <=$fileno; $i++){
    $file=$prefix . $i . ".wiki";
    $text=&fetch_file_nosave($file, 10, 2);
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
    $key = $1; $key = &strip_accents($key); $key =~ s/^[^\w]*//g; $key = lc ($key);
    next unless ($key =~ /^\w/);
    next if (exists $blacklist{$key});
       
    $line =~ s/\s*\<\!--\s*bottag\s*--\>.*?$//g; # strip google links
    $line =~ s/^[\*\#]\s*/\# /g;
    
    if (exists $hash{$key}){
      $hash{$key} = &merge_lines ($hash{$key}, $line);
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
      &identify_red(\%red, \%blue, $maintext); 
      $maintext=rm_blue (\%red, $maintext);
      $maintext = &sectioning($maintext);
      $maintext = "{{TOCright}}\n" . $maintext;

      $prefix='User:Mathbot/Page';
#      $prefix='Wikipedia:Missing_science_topics/Maths';
      $subject='Rm bluelinks.';
      &submit_file_nosave("$prefix$spcount.wiki", $subject, $maintext, $attempts, $sleep);
      open (FILE, ">", "$prefix$spcount.wiki");    print FILE "$text\n";    close(FILE);
      $newtext = $newtext . $maintext; $maintext="";
      $spcount++;
    }

    $maintext = $maintext . $hash{$key} . "\n";
  }

  $diffs=&see_diffs ($oldtext, $newtext);
  &submit_file_nosave("User:Mathbot/Page41.wiki", "Changes to [[WP:MST]]", $diffs, $attempts, $sleep);
  print "Diff is:\n$diffs\n";

  $total_blues = &print_bluelinks(\%hash, \%blue);

  # $newtext has all the new redlinks. Count how many they are.
  # Then call the routine update_stats below to calc the stats.
  
}

sub merge_lines {

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
    $key = $1; $key = &strip_accents($key); $key =~ s/^[^\w]*//g; $key = lc ($key);
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

  return $total_blues;
}

sub update_stats {

    my ($index, $total_reds, $total_blues, $big_total, $percentage, $beg_tag, $end_tag, $stats, $no1, $no2, $text, $file);
    $index = shift; $total_reds = shift; $total_blues = shift; 
    
    $big_total = $total_reds + $total_blues; 
    $percentage = 100 * $total_blues / $big_total; $percentage = sprintf("%.2f", $percentage);

    $no1 = $percentage / 100; $no2 = 1 - $no1;
    $beg_tag = '<!-- begin bottag -->'; $end_tag = '<!-- end bottag -->';

    $stats ="
Of the $big_total entries, there are $total_reds remaining. 
{\| style=\"border: 1px solid black\" cellspacing=1 width=75% height=15x align=center
 \|+ <big>'''$percentage%'''</big> completed <small>(estimate)</small>
 \|align=center width=$no1% style=background:#7fff00\|
 \|align=center width=$no2% style=background:#ff7f50\|
 \|}
";

  $file = $index . '.wiki';
  $text = &fetch_file_nosave($file, 100, 1);
  $text =~ s/($beg_tag).*?($end_tag)/$1$stats$2/sg;

  &submit_file_nosave($file, "Update the progress for the math lists", $text, 10, 5); 
}


sub merge_bluetext_to_existing_bluetext_subpages{
  my ($existing_prefix, $all_bluetext, $letter, @letters, $file, $text, $bighash, $line, @lines, $link, $total_blues);
  $existing_prefix = shift; $all_bluetext = shift; 

  @letters=(0, "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",  "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",  "X", "Y", "Z");

  # put all bluetext into one fat string
  foreach $letter (@letters){

    $file = $existing_prefix . $letter . ".wiki";
    $text = &fetch_file_nosave($file, 100, 1);

    $all_bluetext = $all_bluetext . $text . "\n";
  }

  # group the lines in the bluetext by letter
  @lines = split ("\n", $all_bluetext);
  foreach $line (@lines){

    next unless ($line =~ /\[\[(.*?)\]\]/);
    $link = $1;
    $link =~ s/^(.)/uc($1)/eg;

    next unless ($link =~ /^(.)/);
    $letter = $1; 
    $letter = "0" if ($letter !~ /[A-Z]/);

    # need to treat below the case when $bighash->{$letter}->{$link} already exists in $bighash
    # then that needs to be merged with the current line.
    $bighash->{$letter}->{$link} = $line;
  }

  # merge the lines into chunks of text and submit
  $total_blues=0;
  foreach $letter (sort {$a cmp $b} keys %$bighash){

    $text = "";
    foreach $link ( sort {$a cmp $b} keys %{$bighash->{$letter}} ){
      $text = $text . $bighash->{$letter}->{$link} . "\n";
      $total_blues++;
    }

    $file = $existing_prefix . $letter . ".wiki";
    print "--------------------$file\n";
    &submit_file_nosave($file, "Move bluelines from the math lists at [[Wikipedia:Missing_science_topics]]", $text, 10, 5);
  }
  return $total_blues;
}
