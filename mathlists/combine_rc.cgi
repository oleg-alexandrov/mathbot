#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	  # 'diagnostics' expands the cryptic warnings

use lib '/u/cedar/h1/afa/aoleg/public_html/wp/modules'; # path to perl modules
use CGI::Carp qw(fatalsToBrowser);
use Date::Parse;
use LWP::Simple;
use LWP::UserAgent;
use Encode;

require 'bin/perlwikipedia_utils.pl';
require 'bin/fetch_articles.pl';
require 'strip_accents_and_stuff.pl';
require 'lists_utils.pl';

use open 'utf8';
binmode STDOUT, ':utf8';

undef $/; # undefines the separator. Can read one whole file in one scalar.
$| = 1;   # flush the buffer each line

# Merge the recent changes to mathematics articles into one list
MAIN: {

  # First output line in any CGI script
  print "Content-type: text/html\n\n";

  my ($text, $top, $body, $bottom, $Editor, $url, $res, %changes, $sep, $key, $bot_tag);
  my ($file_tb, @recent_changes_pages, $page_pt, $date_old, $date);
  
  $file_tb = 'Top_bottom.html';
  $sep = '___';
  $bot_tag = '<!-- Just a bot tag -->';

  # First thing to print as output of the CGI script is the top of the
  # recent changes page as stored in the file from the previous run
  # (the top from the current run is not available yet).
  ($top, $bottom) = &read_top_bottom_from_file($file_tb, $bot_tag);
  print "$top\n";
  
  print '<br><p>Fetching the changes to the <b><a href="http://en.wikipedia.org/wiki/List_of_mathematics_articles">'
      . 'list of mathematics articles</a></b> in the last 24 hours...<br><p>' . "\n\n";

  # do some STDOUT manipulation to hide messages from wikipedia_login()
  open (SAVEOUT, ">&STDOUT");  open (STDOUT, ">/dev/null");
  $Editor=wikipedia_login();
  close(STDOUT); open (STDOUT, ">&SAVEOUT");

  #@recent_changes_pages=('0-9'); # useful for debugging
  @recent_changes_pages=('0-9', 'A-C', 'D-F', 'G-I', 'J-L', 'M-O', 'P-R', 'S-U', 'V-Z');

  # The loop parsing the recent changes
  foreach $page_pt (@recent_changes_pages){

    $text = &fetch_recent_changes($Editor, $page_pt);
    
    ($top, $body, $bottom) = &extract_top_body_bottom($text);
    
    &parse_body ($body, \%changes, $sep);
  }

  # Print the recent changes
  $date = "";
  foreach $key (sort {$b cmp $a} keys %changes){

    next unless ($key =~ /^\d+$sep(.*?)$sep/);
    $date_old = $date; $date = $1;
    if ($date ne $date_old){
      print "<h4>$date</h4>\n";
    }

    print $changes{$key} . "\n";
  }

  print "$bottom\n";
  
  # Write the new top and bottom go to file, for future reference
  open(FILE, ">$file_tb");
  print FILE $top . $bot_tag . $bottom;
  close(FILE);
  
}

sub read_top_bottom_from_file {

  my ($file_tb, $bot_tag, $top, $bottom, $text);

  $file_tb = shift; $bot_tag = shift;
  
  open(FILE, "<$file_tb"); $text = <FILE>; close(FILE);

  if ($text =~ /^(.*?)$bot_tag(.*?)$/s){
    
    $top = $1; $bottom = $2;
    
  }else{
    
    # if all fails, use a default top and bottom
    print "Error! Can't read top and bottom from file!\n";
    $top = '<html><body>'; $bottom = '</body></html>';
  }

  return ($top, $bottom);

}

sub fetch_recent_changes{

  my ($Editor, $page_pt, $url, $res, $text);

  $Editor = shift; $page_pt = shift;

  $url = 'http://en.wikipedia.org/w/index.php?title=Special:Recentchangeslinked&target=List_of_mathematics_articles_('
     . $page_pt . ')&hideminor=0&days=1&limit=5000';
  
  print "<a href=\"$url\">$page_pt</a>\&nbsp;";
  $res = $Editor->{mech}->get($url);

  if ($res->is_success ){
    
    $text = $res->decoded_content;

    # Test must be in Unicode in order to print corectly
    $text = Encode::encode('utf8', $text);
    
  }else{
    
    print "<font color='red'><b>Error! Could not get $url from the server!<b></font>\n";
    $text = "";
    
  }

  return $text;
}


sub extract_top_body_bottom {

  my ($text, $top, $body, $bottom, $base_url, $top_sep, $bot_sep);

  $text = shift;

  # make paths absolute
  $base_url = 'http://en.wikipedia.org/';
  $text =~ s/(")\//$1$base_url/g;

  $top_sep="Below are the last \<strong\>\\d+\<\/strong\> changes";
  $bot_sep="\<div class=\"printfooter\"\>";
  
  if ($text =~ /^(.*?)$top_sep(.*?)($bot_sep.*?)$/si){

    $top = $1; $body = $2; $bottom = $3;

  }else{

    print "Error! Can't match the top and bottom of the text to parse!\n";
    exit(0);

  }

  # Do some processing on the top. Strip irrelevant comments.
  $top =~ s/Related changes/Recent changes/g;
  $top =~ s/\<div id=\"\w+\"\>\(to pages linked from.*?$//sg;
  
  # Make sure the Wiki logo shows up in the toolbar on the left
  $bottom =~ s/(url\()\/(images\/wiki-en\.png\))/$1$base_url$2/g;

  # strip some links to mathbot from $bottom
  $bottom =~ s/\<li id=\"pt-.*?mathbot.*?\<\/li\>//ig;
  
  return ($top, $body, $bottom);
  
}

sub parse_body {

  my ($body, $changes, $line, @lines, $day, $date, $title, $text, $sep, $key);

  $body = shift; $changes = shift; $sep = shift;

  # clean up the html a bit
  $body =~ s/^.*?(<h4)/$1/sig;
  $body =~ s/\&nbsp;//g; 
  $body =~ s/\<a href=\"javascript.*?\"\>//g;
  $body =~ s/\<\/?div.*?\>//g;
  
  @lines = split("\n", $body);

  $day = "<b><font color='red'>Unknown date!!!</font></b>";
  $text = "";
  
  foreach $line (@lines){

    # current day
    if ($line =~ /\<h4\>(.*?)\<\/h4\>/i){
      $day = $1;
    }

    # Rm links to individual diffs for articles with more than one change.
    # If the current line passes this test, get the date.
    # This line is the most fragile part of the code. Let us hope that
    # it has no bugs causing this to skip good lines.
    next unless ($line =~ /(\d+:\d\d)\s*\<\/tt\>.*?title=\".*?\"\>(.*?)\</);
    $date = $day . " " . $1;
    $title = $2;

    # Ignore the math lists in the recent changes
    # (nothing interesting is happening there)
    next if ($title =~ /List of mathematics articles \(/);

    # Convert the date to Unix seconds format.
    # Will be used for chronological sorting.
    $date = str2time($date);

    # will sort by reverse date then alphabetically. Also keep track of the day.
    $key = $date . $sep . $day . $sep . $title;
    
    $changes->{$key} = $line;
    
  }

}
