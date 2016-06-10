#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/get_html.pl';

undef $/; # undefines the separator. Can read one whole file in one scalar.
$| = 1; # flush the buffer each line

# use main to avoid the curse of global variables
MAIN: {

  my (%entries, $entry, $entry_s, $link, $text, $error, @results, %redirs);
  
  &read_mathworld(\%entries);

  foreach $entry (sort {$a cmp $b} keys %entries){

    $entry_s = $entry; $entry_s =~ s/^\/(.*?)\.html/$1/g;

    #$entry_s='AffineConnection'; #for debugging

    # let's see which of the following two keywords would be more effective
    $link = 'https://www.google.com/search?q=' . $entry_s . '+SEE';
    #$link = 'https://www.google.com/search?q=' . $entry_s . '+SEE+Mathworld';

    print "$link\n";
    ($text, $error) = &get_html ($link);

    @results = &split_google_results ($text);
    &extract_mathworld_redir_if_exists ($entry_s, \%redirs, \@results);
    
  }
}


sub read_mathworld {

  my ($entries, $file, @files, $text, $line);

  $entries = shift;
  @files = (<mathworld/Mathworld*>, 'Completed_dots.txt');

  $text = "";
  foreach $file (@files){

    open(FILE, "<$file");
    $text = $text . <FILE>;
    close(FILE);
  }

  foreach $line (split ("\n", $text)){
    next unless ($line =~ /^(\/.*?) (.*?)$/);
    $entries->{$1} = $2;
  }
}

sub split_google_results {

  my ($text, $result, @results);

  $text = shift;
  
  @results = split ("(?=<h2 class=r>)", $text);

  foreach $result (@results){
    $result = "" unless ($result =~ /<h2 class=r>/);
    $result =~ s/<h2 class=r>//g;

    $result =~ s/\<\/?b\>//g; # strip google emphasizing
  }

  return @results;
}

sub extract_mathworld_redir_if_exists {
  
  my ($entry_s, $redirs, $results, $result, $redir, $name);

  ($entry_s, $redirs, $results) = @_;
  $redir = "";
  
  foreach $result (@$results){

    #    print "\n-----\n$result\n----\n\n";
    next unless ($result =~ /^\<a href=\"https:\/\/mathworld\.wolfram\.com\/\Q$entry_s\E[^\>]*?\>(.*?)\<\/a.*?SEE:\s*(.*?)\. /i);

    $name = $1; 
    $redir = $2;

    $name =~ s/\s*-+\s*from\s*Wolfram.*?$//ig;
    $name =~ s/\s*-+\s*from\s*Mathworld.*?$//ig;
    $name =~ s/^\s*(.*?)\s*$/$1/g;
    
    $redir =~ s/\s+\.\.\s*$//g;
    $redirs->{$entry_s} = $redir;
    
  }

  if ($redir){
    
    open(FILE, ">>Google_MW_redirs.txt");
    print FILE "\* \[\[$name\]\] \[https:\/\/mathworld.wolfram.com\/$entry_s\.html\] redirects to \[\[$redir\]\]\n";
    close(FILE);
    
    print "\* \[\[$name\]\] \[https:\/\/mathworld.wolfram.com\/$entry_s\.html\] redirects to \[\[$redir\]\]\n";
  }
  
  print "Sleep 5\n"; sleep 5;
}
