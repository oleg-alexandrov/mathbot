#!/usr/local/bin/perl 
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use CGI::Carp qw(fatalsToBrowser);

use lib '/u/cedar/h1/afa/aoleg/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
require "bin/fetch_articles.pl";

undef $/;		      # undefines the separator. Can read one whole file in one scalar.

MAIN: { 

  $| = 1; # flush the buffer each line

  print "Content-type: text/html\n\n"; 
  print "<center><b>This script must be run from the talk page of some nonempty list of topics.</b></center>\n";

  my ($list, $list_talk, $talk, $read, $p1, $p2, $p3, $p4, $p5, $main, @newcats, $cat, @cats, $debug); 
  my (%blacklist, %list_current, @lines, @new_articles, %new_articles_hash, $liststrip, $sleep, $attempts);

  $sleep = 1; $attempts=10;
  $list_talk=$ENV{QUERY_STRING}; %ENV=(); # delete ENV for safety reasons

  #$debug=1; if ($debug){ $list_talk="User talk:Mathbot/Page2"; }
  
  if ($list_talk !~ /^[\s\w]*talk:/i) {
    print "Error! The string passed to this code must be of the form e.g., Talk:List_of_probability_topics<br>\n";
    exit(0);
  }
  $list_talk =~ s/[+ ]/_/g; $list_talk =~ s/^.*?\/wiki\///ig; $list_talk = "$list_talk.wiki";
  $list = $list_talk; $list =~ s/Talk://g; $list =~ s/[_\s]*talk:/:/g;

  &wikipedia_login();
  $talk=&fetch_file_nosave($list_talk, $attempts, $sleep); $talk = decode('utf8', $talk);
  $main=&fetch_file_nosave($list, $attempts, $sleep);  $main = decode('utf8', $main);

  $read=1;		      # read
  ($talk, $p1, $p2, $p3, $p4, $p5) = &printout ($talk, $list, $read, $p1, $p2, $p3, $p4, $p5);

  @lines = ( $main =~ /\[\[(.*?)[\|\]]/g);
  foreach (@lines) {
    next if (/\:/); 
    s/_/ /g; s/^(.)/uc($1)/eg;
    $list_current{$_}=1;
  }

  @lines = ( $p2 =~ /\[\[(.*?)[\|\]]/g);
  foreach (@lines) {
    next if (/\:/);
    s/_/ /g; s/^(.)/uc($1)/eg;
    $blacklist{$_}=1;
  }
  $liststrip=$list; $liststrip =~ s/_/ /g; $liststrip =~ s/\.wiki//g; $blacklist{$liststrip}=1;

  @cats = ($p3 =~ /\[\[:(Category:.*?)\]\]/g);

  print "<br>Searching for articles mising in \"$liststrip\". <br><br>\n";
  &fetch_articles(\@cats, \@new_articles, \@newcats);

  $p1="";
  foreach ( @new_articles ) {
    $new_articles_hash{$_}=1;
    next if (exists $list_current{$_});
    next if (exists $blacklist{$_});
    $p1 = "$p1" . "\[\[$_\]\] --\n";
  }

  $p4="";
  foreach $cat (@newcats){
    $p4 = $p4 . "[[:$cat]] --\n";
  }

  $p5="";
  foreach (keys %list_current){
    if (! exists $new_articles_hash{$_}){
      $p5 = $p5 . '[[' . $_ . ']] -- ' . "\n"; 
    }
  }
  
  $read=0;		      # write 
  ($talk, $p1, $p2, $p3, $p4, $p5) = &printout ($talk, $list, $read, $p1, $p2, $p3, $p4, $p5);

  print "Modifying the talk page of \"$liststrip\"<br>\n";
  $talk = encode('utf8', $talk);
  &submit_file_nosave($list_talk, "List articles missing from the \[\[$liststrip\]\].", $talk, $attempts, $sleep);

  $list_talk =~ s/\.wiki//g;
  print "Done. You may now go back to the <A href=\"http://en.wikipedia.org/wiki/$list_talk\">$list_talk</a><br>\n";
  
}
sub printout {
  
  $_ = shift;
  my $list = shift; $list =~ s/_/ /g; $list =~ s/\.wiki//g;
  
  my ($AStart, $AEnd, $BStart, $BEnd, $CStart, $CEnd, $DStart, $DEnd, $EStart, $EEnd, $tmp);
  my ($p1, $p2, $p3, $p4, $p5, $qA, $qB, $qC, $qD, $qE, $qF);
  $AStart='<!-- bottag:A:begin -->'; $AEnd='<!-- bottag:A:end -->'; 
  $BStart='<!-- bottag:B:begin -->'; $BEnd='<!-- bottag:B:end -->'; 
  $CStart='<!-- bottag:C:begin -->'; $CEnd='<!-- bottag:C:end -->'; 
  $DStart='<!-- bottag:D:begin -->'; $DEnd='<!-- bottag:D:end -->';
  $EStart='<!-- bottag:E:begin -->'; $EEnd='<!-- bottag:E:end -->';
  
  if (/^(.*?$AStart)(.*?)($AEnd.*?$BStart)(.*?)($BEnd.*?$CStart)(.*?)($CEnd.*?$DStart)(.*?)($DEnd.*?$EStart)(.*?)($EEnd.*?$)/s) {

    $qA=$1; $p1=$2;
    $qB=$3; $p2=$4;
    $qC=$5; $p3=$6;
    $qD=$7; $p4=$8;
    $qE=$9; $p5=$10;
    $qF=$11;

  }elsif (/^(.*?$AStart)(.*?)($AEnd.*?$BStart)(.*?)($BEnd.*?$CStart)(.*?)($CEnd.*?$DStart)(.*?)$DEnd(.*?)$/s) {
    
    $qA=$1; $p1=$2;
    $qB=$3; $p2=$4;
    $qC=$5; $p3=$6;
    $qD=$7; $p4=$8;
    
    $qE = "$DEnd\n===E: Articles in [[$list]] not in categories===\nMay be redirects or articles which should be removed/categorized.\n$EStart";
    
    $qF="$EEnd" . "$9";
    $p5="";
    
    
  } else {
    $qA="== List updater == \nIn subsection A below, listed are articles which are missing from the [[$list]]. They were found by looking in the categories in subsection C. One can add more categories to be searched to subsection C, see some suggestions in subsection D. \n\nAll this process can be restarted by clicking on the link at the bottom of subsection D.\n\nPlease note that anything around here is editable, but please don't modify the lines of the form\n:<nowiki><!-- bottag:X:begin --></nowiki>\nor their order.\n\n=== A: Articles missing from the [[$list]] ===\n$AStart";
    

    $qB = "$AEnd\n===B: Place here articles not wanted either in the [[$list]] or in subsection A. ===\n\n$BStart"; 
    $qC = "$BEnd\n===C: Categories to be searched ===\nThe bot will look for potential additions to the [[$list]] in this list of categories. You may add any other categories to this list, for example from subsection D below. Use the format <nowiki>[[:Category:XXX]]</nowiki> (the colon (:) shows up twice!). \n$CStart";
    
    $qD = "$CEnd\n===D: Potential searchable categories ===\nMove up to subsection C any categories which the bot should search for missing articles in the [[$list]].\n$DStart";
    
    $qE = "$DEnd\n===E: Articles in [[$list]] not in categories===\nMay be redirects or articles which should be removed/categorized.\n$EStart";
    
    $qF="$EEnd$_";
    
    $p1=""; $p2=""; $p3=""; $p4=""; $p5="";
    
  }
      
      my $read=shift;

      if (! $read ) { 
	$p1=shift; $p2=shift; $p3=shift; $p4=shift; $p5=shift;
      }

      $p1 =~ s/^\s*//g; $p1 =~ s/\s*$//g;
      $p2 =~ s/^\s*//g; $p2 =~ s/\s*$//g;
      $p3 =~ s/^\s*//g; $p3 =~ s/\s*$//g;
      $p4 =~ s/^\s*//g; $p4 =~ s/\s*$//g;
      $p5 =~ s/^\s*//g; $p5 =~ s/\s*$//g;
      
      $qE =~ s/\s*$//g;
      
      $_ = "$qA\n\n$p1\n\n$qB\n\n$p2\n\n$qC\n\n$p3\n\n$qD\n\n$p4\n\n$qE\n\n$p5\n\n$qF\n";
      
      return ($_, $p1, $p2, $p3, $p4, $p5);
    }
     
