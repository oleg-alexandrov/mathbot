#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Term::ANSIColor;
use Term::GetKey;
use WWW::Mediawiki::Client;
use Getopt::Std;
use Pod::Usage;
use Lingua::Ispell qw(:all);                  # ispell
$Lingua::Ispell::path = '/usr/bin/ispell';

require "encode_decode.pl";

my ($art_encoded, $art_decoded, $dir, $text, $punct_mark);
my ($arts);


if (@ARGV){
  &make_list_of_matches(); # get the list of articles to work on
 }else{
 &perform_replacements();
}

my $mcounter=0;
# search through all articles for possible matches, save them for later
sub make_list_of_matches {
  my ($art_encoded, $art_decoded, $dir, $text, @articles, $line);

  # get the list of articles
  open (FILE, "<User:Oleg_Alexandrov/Test_page3.wiki");
  $line=join (" ", <FILE>);
  close(FILE);
  
  @articles = ($line =~ /\[\[(.*?)\]\]/g);
  
  # blancket this
  open (FILE, ">To_do.txt");

  foreach (@articles){
    print FILE "$_\n";
  }
  close(FILE);

  exit(0);
  
  foreach $art_encoded (@articles) {
    $art_encoded =~ s/\n//g;           # rm newline  
    next if ($art_encoded =~ /^\s*$/); # ignore empty lines
    next if ($art_encoded =~ /\//); # ingnore articles having a backslash (those end up in different directory)

    next if ($art_encoded !~ /^(\w)/); # ingnore articles starting with a funny character (non alphanumeric)
    $dir=$1;
    next unless ($dir =~ /[A-Z]/);
    
    # article to work with
    $art_decoded=&decode($art_encoded);
    $art_decoded =~ s/ /_/g;
    $art_decoded = $art_decoded . ".wiki";

    open (FILE_IN, "<../articles/$dir/$art_decoded") || next; # get the file from its directory, or move on
    $text=join ("", <FILE_IN>);
    close(FILE_IN);

    if ( &blank_line(\$text, $art_decoded, 0)  ) { # see if ispell finds any spelling mistakes (don't correct them now)
      print "Will work on: $art_encoded\n\n\n";
      open (FILE_OUT, ">>To_do.txt");
      print FILE_OUT "$art_encoded\n";
      close(FILE_OUT);
    }
  }
  
}

# take the list of articles which need punctuation fixes. And do the work.
sub perform_replacements {

  my ($text, $art_encoded, $art_decoded, @init, @articles, @done_already, %Done, $dotfile, $dir);

  # get the articles which need punctuation fixes
  open (FILE, "<To_do.txt");
  @articles=<FILE>;
  close(FILE);
  foreach (@articles){
    chomp; # rm newline
  }
  
  # get the articles which are done already
  open (FILE, "<Done_already.txt");
  @done_already=<FILE>;
  close(FILE);
  foreach (@done_already){
    chomp; # rm newline
  }

  # put @done_already in a hash
  foreach $art_encoded (@done_already){
    $Done{$art_encoded}=1;
  }

  foreach $art_encoded ( @articles ) {
    
    next if (exists $Done{$art_encoded}); # skip the articles which were done
    next if ($art_encoded =~ /^\s*$/);    # ignore empty lines
    next if ($art_encoded =~ /\//);       # ingnore articles having a backslash (those end up in different directory)

    next if ($art_encoded !~ /^(\w)/);      # ingnore articles starting with a funny character (non alphanumeric)
    $dir=uc($1);
    next unless ($dir =~ /[A-Z]/);
    
    # article to work with
    $art_decoded=&decode($art_encoded);
    $art_decoded =~ s/ /_/g;
    $dotfile="." . "$art_decoded" . ".ref.wiki";
    $art_decoded = $art_decoded . ".wiki";

    print "Now fetching $art_decoded\n";
    # Get from Wikipedia the up to date copy of the article. This fragment is copied from the mvs package.
    my $method= "do_update";
    my $wmc = WWW::Mediawiki::Client->new(@init);
    $wmc->$method($art_decoded);
    # read the article in
    open (FILE, "<$art_decoded") || die "Cant open $art_decoded!\n"; # get the file
    $text=join ("", <FILE>);
    close(FILE);
    print "done!\n";
    
    # Put periods, if necessary. This is the heart of the code.
    if ( &blank_line(\$text, $art_decoded, 1)  ) {
      
      open (FILE, ">$art_decoded"); # write to disk
      print FILE "$text";
      close(FILE);
#       print `\\mv -fv \"$art_decoded\" upload` . "\n"; # tell what will happen
#       print `\\mv -fv \"$dotfile\" upload` . "\n"; # move the article to the upload directory (and its dotfile)
      
    }else{
#       print `\\mv -fv \"$art_decoded\" upload/update_local` . "\n"; # tell what will happen
#       print `\\mv -fv \"$dotfile\" upload/update_local` . "\n"; # will go back to my collection, w/o uploading
      
    }
    
    # Mark the current article as done
    open (FILE, ">>Done_already.txt");
    print FILE "$art_encoded\n";
    close(FILE);

    print color 'green';
    print "done with $art_decoded\n\n";
    print color 'white';
    
    `sleep 10`;

    $mcounter++;

#     if ( $dir !~ /A/){
#       print "done with A. exiting. \n";
#       exit(0);
#     }
    
    
    if ($mcounter > 60){
      print "mcounter is $mcounter. Exiting!\n";
      exit(0);
    }
  }
}

sub blank_line {
  my ($ptext, $text, $word, @words, $pointer, @options, $counter, $choice, $answer, $sep, $before, $after, $i, @tmp);
  my ($art_decoded, $success, %ignored_before, $temp, %dictionary, $interactive, $name);

  $ptext=$_[0]; $text=$$ptext; # pass by reference
  $art_decoded=$_[1]; $art_decoded =~ s/\.wiki//g; $art_decoded =~ s/_/ /g; # current article.
  $interactive=$_[2];     
  $success=0;          # 1 if some spelling mistakes got corrected.
  print "now in $art_decoded\n";
  
#  if ($text =~ /(^|\n)([^\n]*)(couldn|doesn|won|can|shouldn|wouldn)(\'t)(.*?\n)/){
#  if ($text =~ /\{\{merge\}\}\s*\[\[/i){
#  if ($text =~ /(.)(.)(knows?n?)(\'t)(.*?\n)/i){
#  if ($text =~ /\n([^\n]*?\[http:\/\/www-gap.dcs.st-and.ac.uk\/~history\/Mathematicians\/\w[^\n]*?MacTutor.*?)\n/i){
  if ($text !~ /MacTutor/i){
    open (FILE, ">>result.txt");
    print "$art_decoded does not have MacTutor link! \n";
    print FILE "$art_decoded\n";
    close(FILE);
    
#     if ($interactive){
# #      $text =~ s/\{\{merge\}\}\s*\[\[(.*?)\]\]/\{\{mergewith|$1\}\}/sg;
#       $text =~ s/\[http:\/\/www-gap.dcs.st-and.ac.uk\/~history\/Mathematicians\/(\w.*?)\.html.*?\n/\{\{MacTutor Biography\|id=$1\}\}\n/;

      
#       $$ptext = $text;

#       print "Done, take a nap!\n";
#      `sleep 15`;

#     }
#     return 1;
  }else{
   print "$art_decoded has the MacTutor link!\n"; 
  }
  return 1;
}

