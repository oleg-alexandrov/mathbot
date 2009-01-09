#!/usr/bin/perl
use POSIX;                     # the strftime function
use CGI::Carp qw(fatalsToBrowser);
use strict;
undef $/; 

use lib '/home/mathbot/public_html/cgi-bin/wp/modules'; # path to perl modules
require 'bin/wikipedia_fetch_submit.pl'; 
require 'bin/wikipedia_login.pl';
require 'bin/get_html.pl';

# Summarize and list the recent Wikipedia articles for deletion

MAIN: {

  #&add_archived_discussions();
  
  # This line must be the first to print in a cgi script
  print "Content-type: text/html\n\n"; 

  $| = 1; # flush the buffer each line

  print "Please be patient, this script can take a minute or two "
     .  "if Wikipedia is slow ...<br><br>\n";
  
  chdir '/home/mathbot/public_html/wp/afd/'; # needed when running this from crontab

  &wikipedia_login();
  
  my ($stats, $detailed_stats, $detailed_combined_stats);
  $detailed_combined_stats = "{{shortcut|WP:OAFD|WP:OLDAFD}}\n";

  my ($test_mode, $summary_file);
  if (@ARGV){  $test_mode=1;  }else{  $test_mode=0;  } # see if we are in testing mode
  if (! $test_mode){
    $summary_file="Wikipedia:Articles_for_deletion/Old.wiki";
  }else{
    $summary_file="User:Mathbot/Page3.wiki";  
  }
  my $detailed_file = "Wikipedia:Articles_for_deletion/Old/Open AfDs.wiki";

  my $attempts=10;
  my $sleep=1;
  my ($text, $edit_summary, $error);
  $text = &wikipedia_fetch($summary_file, $attempts, $sleep);

  # add the discussion five days ago, if it is not already in $text
  ($text, $edit_summary) = &add_another_day ($text);

  my @lines = split("\n", $text);
  my $line;
  my ($brief_afd_link, $link, %stats_hash);
  foreach $line (@lines) {
    
    # extract the links to the open discussions
    next unless ($line =~ /^\*\s*\[\[(Wikipedia:(?:Pages|Votes|Articles) for deletion\/Log\/\d+.*?)\]\]/);
    $link=$1; 
    if ($link =~ /^(.*?)\|(.*?)$/){
       $link = $1; $brief_afd_link = $2;
    }else { 
       $brief_afd_link = $link;
    }
    print "Now doing $link ... ";
    
    my $full_link = $link; $full_link =~ s/ /_/g;
    $full_link = 'http://en.wikipedia.org/wiki/' . $full_link;

    ($text, $error) = &get_html ($full_link);

    # see which AfD/VfD debates are not closed yet, and put that info in the link. 
    # Get both a brief and a complete list, to put in different places.
    ($stats, $detailed_stats) = &see_open_afd_discussions ($link, $text, $detailed_file);
    $detailed_combined_stats = $detailed_combined_stats . $detailed_stats;

    $line = '* [[' . $link . '|' . $brief_afd_link . ']] ' . $stats;
    $stats_hash{$link} = "$line";
  }

  # The file might have changed while we were doing the calculation above.
  # Get a new copy.
  $text = &wikipedia_fetch($summary_file, $attempts, $sleep);
  ($text, $edit_summary) = &add_another_day ($text);
  @lines = split("\n", $text);
  
  # gather all the info in $text
  my $num_days      = 0; # cout how many days are listed, ...
  my $num_open_disc = 0; # ... and how open many discussions
  my $combined_stats="";
  foreach $line (@lines){
    if ($line =~ /^\*\s*\[\[(Wikipedia:(?:Pages|Votes|Articles) for deletion\/Log\/\d+.*?)\s*(?:\||\]\])/) {
      $link=$1;
      $num_days++;
      if (exists $stats_hash{$link}) {
        $line = $stats_hash{$link}; # Overwite this line with the stats we found above
      }
      if ( $line =~ /\((\d+) open/ ){
       $num_open_disc = $num_open_disc + $1;
      }
    }
    $combined_stats = $combined_stats . "$line\n";
  }

  my $utc_time=strftime("%H:%M, %B %d, %Y (UTC)", gmtime(time));
  $combined_stats =~ s/(\/afd\/afd\.cgi.*?\]).*?\n/$1 \(last update at $utc_time\)\n/;

  $edit_summary = "There are $num_open_disc open discussion(s) in $num_days day(s)."
     . $edit_summary;
  if ($num_open_disc > 200){
    $edit_summary = "Big Backlog: " . $edit_summary;
  }

  &wikipedia_submit($summary_file, $edit_summary, $combined_stats, $attempts, $sleep);
  &wikipedia_submit($detailed_file, $edit_summary, $detailed_combined_stats, $attempts, $sleep);

  print "<br>Finished! One may now go back to "
     . "<a href=\"http://en.wikipedia.org/w/index.php?title=Wikipedia:Articles_for_deletion/Old&action=purge\">" 
	. "Wikipedia:Articles for deletion/Old</a>. <br>\n";
}


sub add_another_day{

  my ($text, $afd_link, $hour_now, $thresh, $edit_summary, $SECONDS_PER_DAY, $brief_afd_link, $seconds);
    
  $text = shift;  

  # If beyond certain hour of the day (midnight GMT time),
  # add a link for the Afd/VfD discussion 5 days ago if not here yet
  $hour_now=strftime("%H", localtime(time));
  $thresh=16;

  if ($hour_now < $thresh){
    return ($text, "");
  }

  # Get the afd link for five days ago
  ($afd_link, $brief_afd_link) = &get_afd_link(-5);
  
  my $tag='<!-- Place latest vote day above - Do not remove this line -->';
  $edit_summary="";
  if ($text !~ /\n\*\s*\[\[\Q$afd_link\E/){
    $text =~ s/$tag/\* \[\[$afd_link\|$brief_afd_link\]\]\n$tag/g;
    $edit_summary=" Link to \[\[$afd_link\]\].";
  }

  return ($text, $edit_summary);
}

sub get_afd_link {

  my $days_from_now  = shift;
  
  my $SECONDS_PER_DAY = 60 * 60 * 24;

  my $seconds = time() + $days_from_now * $SECONDS_PER_DAY;
  my $afd_link = strftime("Wikipedia:Articles for deletion/Log/%Y %B %d",
                          localtime($seconds));
  $afd_link =~ s/ 0(\d)$/ $1/g; # make 2005 April 01 into 2005 April 1

  my $brief_afd_link = strftime("%d %B (%A)", localtime($seconds));
  $brief_afd_link =~ s/^0//g;

  return ($afd_link, $brief_afd_link);
}

sub fmt_date {

  my ($link, $date);
  $link = shift;

  # 'Wikipedia:Articles for deletion/Log/2006 December 16'  -->  '16 December'
  if ($link =~ /^.*\/(\d+)\s+(\w+)\s+(\d+)/){
    return "$3 $2";
  }else{
   return ""; 
  }
  
}

sub add_archived_discussions {

  # Discussions older than five days that are no longer at Afd/Old are considered
  # archived, and should be added to the page of archived discussions

  my ($text, $curr_year, $prev_year);
  
  # Temporary
  my $file = "archive.txt";
  
  open(FILE, "<$file"); $text = <FILE>; close(FILE);

  $curr_year = strftime("%Y", gmtime(time));
  $prev_year = $curr_year - 1;
  
  if ($text !~ /==+\s*$curr_year\s*==+/){

    # Add section for current year if missing
    if ($text !~ /^(.*?)(==+\s*)$prev_year(\s*==+)(.*?)$/s){
      return; # Prev year section is missing, don't know what to do
    }

    # Add current year above previous year
    $text = $1 . $2 . $curr_year . $3 . "\n" . $2 . $prev_year . $3 . $4;
  }

  # Any day in the current year up to six days ago is a candidate to be in the archive
  my $start = 34;
#  my $start = -6;
  my $stop  = -366;
  my $day;

  my ($all_links, $afd_link, $prev_afd_link, $link_sans_day, $prev_link_sans_day);

  $all_links     = "";
  $prev_afd_link = "";
  
  # Add only the days from the current year to the archive.
  # Go in reverse, from the most recent date towards the past.
  my $first_day = 1; # mark that this is the first day in the list
  for ($day = $start ; $day >= $stop ; $day--){

    my ($afd_link, $brief_afd_link) = &get_afd_link($day);

    next unless ($afd_link =~ /\/$curr_year/); # deal only with the current year

    # See if to add a section separating two months
    $link_sans_day      = $afd_link;      $link_sans_day      =~ s/\s*\d+$//g;
    $prev_link_sans_day = $prev_afd_link; $prev_link_sans_day =~ s/\s*\d+$//g;

    # Add a section heading only if we are between months or we arrived
    # at the most recent day
    if (
        $first_day ||
        ($link_sans_day ne $prev_link_sans_day && $prev_link_sans_day ne "")
       ){

      $link_sans_day =~ s/^(.*)\/(.*?)$/Deletion discussions\/$2/g;
      $all_links = $all_links . "\n===$link_sans_day===\n\n";

      $first_day = 0; # First day passed
    }
    
    $all_links = $all_links .  "* [[$afd_link]]\n";

    # Prepare for the next loop
    $prev_afd_link = $afd_link;
  }

  $text =~ s/(==+\s*$curr_year\s*==+\s*).*?(==+\s*$prev_year\s*==)/$1$all_links\n$2/g;
  print "$text\n";
  
  exit(0);
}

sub see_open_afd_discussions (){
  my $link = shift;
  my $text = shift;
  my $detailed_file = shift;

  my $stats = "";

  $text =~ s/\n//g;	      # rm newlines

  # strip the top part, as otherwise it confuses the parser below
  $text =~ s/^.*?\<div id=\"toctitle\"\>//sg;
  
  # some processing to deal with Vfd/afd ambiguity recently
  $text =~ s/\"boilerplate[_\s]+metadata[_\s+][avp]fd.*?\"/\"boilerplate metadata vfd\"/ig;
  
  $text =~   s/(\<div\s+class\s*=\s*\"boilerplate metadata vfd\".*?\<span\s+class\s*=\s*\"editsectio)(n)(.*?\>)/$1p$3/sgi;


  my @all =    ($text =~ /\<span\s+class\s*=\s*\"editsectio\w\".*?\>\[\<a href\s*=\s*\"\/w\/index.php\?title\s*=\s*(Wikipedia:\w+[_\s]for[_\s]deletion.*?)\"/g );

  my @open =   ($text =~ /\<span\s+class\s*=\s*\"editsection\".*?\>\[\<a href\s*=\s*\"\/w\/index.php\?title\s*=\s*(Wikipedia:\w+[_\s]for[_\s]deletion.*?)\"/g );

  my @closed = ($text =~ /\<span\s+class\s*=\s*\"editsectiop\".*?\>\[\<a href\s*=\s*\"\/w\/index.php\?title\s*=\s*(Wikipedia:\w+[_\s]for[_\s]deletion.*?)\"/g );

  my $openc=0;
   foreach (@open) {

    next if (/Wikipedia:\w+[_\s]for[_\s]deletion\/Log/i);
    next unless (/\&amp;section=(T-|)1/);
    s/\&.*?$//g;
    $openc++;

    $stats = "$stats " . "\[\[$_\|$openc]]";
  }
  print "($openc open / ";


  my $closedc=0;
   foreach (@closed) {
    next if (/Wikipedia:\w+[_\s]for[_\s]deletion\/Log/i);
    next unless (/\&amp;section=(T-|)1/);
    s/\&.*?$//g;
    $closedc++;

#    print "$closedc: $_\n";
  }
 print "$closedc closed / ";

  my $allc=0;
  foreach (@all) {
    next if (/Wikipedia:\w+[_\s]for[_\s]deletion\/Log/i);
    next unless (/\&amp;section=(T-|)1/);
    s/\&.*?$//g;
    $allc++;
#    print "$allc: $_\n";
  }
  print "$allc total discussions)<br>\n";

  # some gimmickry, to list to sections in $detailed_file.
  my $detailed_stats = $stats; 
  my $short_link = $link;
  $short_link =~ s/^.*\///g;
  $detailed_file =~ s/\.wiki$//g;

  # if there are too many open afds, link to the file listing them. Otherwise, list them right here. 
  if ($openc == 0 ){
    $stats = "($openc open / $closedc closed / $allc total discussions)";
  }elsif ( $openc > 20 ){
    $stats = "($openc open / $closedc closed / $allc total discussions; [[$detailed_file\#$short_link\|see open]])";
  }else{
    $stats = "($openc open / $closedc closed / $allc total discussions; open: $stats)";
  }

  my $http_link = $link; $http_link =~ s/ /_/g; 
  $http_link = '([http://en.wikipedia.org/w/index.php?title=' . $http_link . '&action=edit edit this day\'s list])'; 

  # text to add to a subpage listing all open discussions
  $detailed_stats =~ s/\s*\[\[(.*?)\|\d+\]\]/\* \[\[$1\]\]\n/g;
  $detailed_stats =~ s/_/ /g; 
  $detailed_stats = "==[[$link\|$short_link]]==\n" . $http_link . "\n" . $detailed_stats;
 
  return ($stats, $detailed_stats);  
}

