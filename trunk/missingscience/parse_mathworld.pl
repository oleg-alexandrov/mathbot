#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
use LWP::Simple;
use LWP::UserAgent;
use Encode;
undef $/;		      # undefines the separator. Can read one whole file in one scalar.

# Read the mathworld files, and write them to a file in Wikipedia format. That requires:
# 1. Completing dots in incomplete entries. 
# 2. Converting from uppercase to lowercase.
# Both are done automatically, and are not perfect. 

MAIN: {
  my (%mathworld, $line, %completed_dots, $file, $link, $completed, %upper, %case, %possib_links, $sep);
 
  $file="Completed_dots.txt"; $sep = " X9ko4ApH60 "; # weird thing
  &read_completed_dots (\%completed_dots, $file); # some completed entries are stored on disk
  print "Read completed\n";

  &read_upper_lower(\%case);
  print "Read upper lower\n";
  
  &read_mathworld(\%mathworld);
  print "Read mathworld\n";
  
  &read_all_possible_links("All_possib.txt", \%possib_links, $sep);
  print "Read all posibs\n";

  foreach $link (sort {$a cmp $b} keys %mathworld){

    if ($mathworld{$link} =~ /\.\.\.$/){
      #print "Will need to complete $mathworld{$link}\n";

      if (exists $completed_dots{$link}){
	#print "Completion is $completed_dots{$link}\n";
	$mathworld{$link}=$completed_dots{$link};
	next;
      }

      $completed=complete_link_with_google ($link, $file); # If works, gives exact answer. Write to disk then. Slow.
      print "Google gave\n\n$link --> $completed\n\n";
      if ($completed !~ /----/){
	$mathworld{$link}=$completed; # accept that if google gave success
	next;
      }else{
	print "********Failed in completing $link with google!!!!\n";
      }
      
      $mathworld{$link} =~ s/\[\[\s*/\[\[/g; $mathworld{$link} =~ s/\s*\]\]/\]\]/g; # strip extra spaces
      $mathworld{$link}=&complete_using_heuristic($link, $mathworld{$link}); # always works, gives wrong answer sometimes
    }
  }

  open (FILE, ">:utf8", "Parsed_mathworld.txt");
  foreach $link (sort {$a cmp $b} keys %mathworld){
    $link = &add_alternatives($mathworld{$link}, \%case, \%possib_links, $sep);
    print FILE "$link\n";
  }
  close(FILE);
}

sub read_completed_dots {

  my ($completed_dots, $file, $text, $line, @lines, $link, $name);
  $completed_dots=shift; $file=shift;
  open (FILE, "<:utf8", $file);
  $text = <FILE>;
  close(FILE);

  $text =~ s/\&\#(\d+);/chr($1)/eg; # convert from html to binary
  @lines = split ("\n", $text);

  foreach $line (@lines){
    next unless ($line =~ /^(\/.*?) (.*?)$/);
    $link =$1; $name=$2;
    next if ($name =~ /^\-+$/); # move over invalid entries
    $completed_dots->{$link}=$name;
  }
}

sub read_mathworld {
  
  my ($line, @lines, $link, $name, @letters, $letter, $mathworld);
  
  $mathworld = shift; # hash containing all the mathworld entries, as map from link to name
  @letters=("0", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",  "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",  "X", "Y", "Z");
  
  $line="";
  foreach $letter (@letters) {
    open (FILE, "<:utf8", "mathworld/Mathworld_$letter.txt");
    $line= $line . "\n" . <FILE>;
    close(FILE);
  }
  
  $line =~ s/\&\#(\d+);/chr($1)/eg; # convert from html to binary
  @lines=split("\n", $line);
  foreach (@lines) {
    next unless (/^(.*?) (.*?)$/);
    $link=$1; $name=$2;

    $name =~ s/\<\/?[ib]\>//g; # strip html markup
    $mathworld->{$link}=$name;					
  }
}

# complete dots in mathworld entries, by using google. Does not always work
# Write it to file also if it worked.
sub complete_link_with_google{

  my ($link, $file, $completed, $google, $req, $res, $ua, $text);
  $link = shift; $file = shift;
  
  print "Doing now $link\n";
  $google='http://www.google.com/search?q=' . "$link+mathworld";
  
  $ua = LWP::UserAgent->new;
  $ua->agent("$0/0.1 " . $ua->agent);
  # $ua->agent("Mozilla/8.0") # pretend we are very capable browser
  
  $req = HTTP::Request->new(GET => $google);
  $req->header('Accept' => 'text/html');
  
  # send request
  $res = $ua->request($req); 
  print "Sleep 2\n"; sleep 2; # take a nap

  # check the outcome
  if (! $res->is_success ){
    print "Get failed!\n";
    return "----"; 
  }

  $text = $res->decoded_content;

  # preprocessing
  print "$link\n";
  
  $text =~ s/\<\/?b\>//g; $text =~ s/\s+/ /g; $text =~ s/Wolfram\s*MathWorld/MathWorld/ig;
  if ($text =~ /^.*?mathworld[^\<\>]*?\Q$link\E[^\<\>]*?\>\s*([^\<\>]*?)\s*\<\/a/is){

    $completed=$1;
    $completed =~ s/\s*-+\s*from mathworld.*?$//ig;
    $completed =~ s/\s*\.\.\.*?$//g;
    $completed =~ s/\s*--\s*from.*?$//g;

    print "$completed\n";
    print "Write to $file: $link $completed\n";
    open (FILE, ">>:utf8", $file); print FILE "$link $completed\n"; close(FILE);
    
  } else{
    $completed='----';
  }
  return $completed;
}

# not always gives the right answer, but at least gives some answer, unlike the google way. Faster, too. 
sub complete_using_heuristic {

  my ($link, $name, $k, $complete);
  $link = shift; $name = shift; # use both the link and incomplete name to guess the completion

#  print "$link\n";
  $name =~ s/\.\.\.\s*$//g;
  $link =~ s/^\///g; $link =~ s/\.html//g;
  $link =~ s/([a-z])([A-Z])/$1 $2/g;
  $complete = $link;

#  print "$complete $name\n";
  return $complete unless  (substr ($complete, 0, 22) ne $name && substr($complete, 0, 21) ne $name);
  
  for ($k=0 ; $k < 21 ; $k++) {
    if (substr($complete, $k, 1) ne substr($name, $k, 1) && substr($complete, $k, 1) eq substr($name, $k+1, 1) ) {
      $complete = substr($complete, 0, $k) . substr($name, $k, 1) . substr($complete, $k, 100);
    }
  }
  return $complete unless  (substr ($complete, 0, 22) ne $name && substr($complete, 0, 21) ne $name);

  for ($k=0 ; $k < 21 ; $k++) {
    if (substr($complete, $k, 1) ne substr($name, $k, 1) && substr($complete, $k+1, 1) eq substr($name, $k+1, 1) ) {
      $complete = substr($complete, 0, $k) . substr($name, $k, 1) . substr($complete, $k+1, 100);
    }
  }
  return $complete unless  (substr ($complete, 0, 22) ne $name && substr($complete, 0, 21) ne $name);

  for ($k=0 ; $k < 21 ; $k++) {
    
    if (substr($complete, $k, 1) ne substr($name, $k, 1) && substr($complete, $k+2, 1) eq substr($name, $k+1, 1) && substr($complete, $k+1, 1) eq "e" ) {
      $complete = substr($complete, 0, $k) . substr($name, $k, 1) . substr($complete, $k+2, 100);
    }
  }
  return $complete unless  (substr ($complete, 0, 22) ne $name && substr($complete, 0, 21) ne $name);

  print "$link ++++ $complete ++++ $name ++++ failed!\n";
  return $link; # if all else failed. Don't return $complete as it may be mangled
}

sub parse_mathworld{

  my (@letters, $line, @entries, $link, $name, $mathworld, $letter);
  $mathworld =shift;
  
  @letters=("0", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",  "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",  "X", "Y", "Z");

  foreach $letter (@letters) {

    open (FILE, "<:utf8", "mathworld/Mathworld_$letter.txt");
    $line=<FILE>;
    close(FILE);

    @entries=split("\n", $line);
    foreach (@entries) {
      next unless (/^(.*?)\s+(.*?)$/);
      $link=$1; $name=$2;

      $link =~ s/^\///g; $link =~ s/\.html//g; $link =~ s/(\w)([A-Z])/$1 $2/g;

      $link =~ s/^(.)/uc($1)/eg;
      $name =~ s/^(.)/uc($1)/eg;
      $mathworld->{$name}=$link;
    }
  }
}

sub read_upper_lower {

  my (@words, $word, $freq, $text, $case, $low);

  $case=shift;
  
  open (FILE, "<:utf8", "Lower.txt"); $text = <FILE>; close (FILE);
  @words = split ("\n", $text);
  foreach $word (@words){
    next unless ($word =~ /^(.*?)\s+(\d+)/);
    $word=$1; $freq=$2;
    $case->{$word}=$word;
  }
  
  open (FILE, "<:utf8", "Upper.txt"); $text = <FILE>; close (FILE);
  @words = split ("\n", $text);
  foreach $word (@words){
    next unless ($word =~ /^(.*?)\s+(\d+)/);
    $word=$1; $freq=$2;
    $low=lc($word);
    $case->{$low}=$word;
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

  $name =~ s/^(.)/uc($1)/ge; $name =~ s/\s+/ /g;
  
  @choices = (@choices, $name); 
  
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

sub read_all_possible_links {

  my ($file, $hash, $sep)=@_;
  my $link;
  
  open (FILE, "<:utf8", $file);
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

