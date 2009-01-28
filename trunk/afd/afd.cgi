#!/usr/bin/perl
use POSIX;                     # the strftime function
use CGI::Carp qw(fatalsToBrowser);
use strict;
undef $/; 

use lib $ENV{HOME} . '/public_html/cgi-bin/wp/modules'; # absolute path to perl modules
use lib '/home/mathbot/public_html/cgi-bin/wp/modules'; # absolute path to perl modules
use lib '../wp/modules'; # relative path to perl modules

require 'bin/wikipedia_fetch_submit.pl'; 
require 'bin/wikipedia_login.pl';
require 'bin/get_html.pl';

# Summarize and list the recent Wikipedia articles for deletion

MAIN: {
  
  # This line must be the first to print in a cgi script
  print "Content-type: text/html\n\n"; 

  $| = 1; # flush the buffer each line

  print "Please be patient, this script can take a minute or two "
     .  "if Wikipedia is slow ...<br><br>\n";

  # If the full path to the script is known (such as when running this
  # script from crontab), go to that directory first
  my $cur_dir = $0; # $0 stands for the executable, with or without full path
  if ($cur_dir =~ /^\//){
    $cur_dir =~ s/^(.*)\/.*?$/$1/g;
    #print "Will go to $cur_dir\n";
    chdir $cur_dir;
  }else{
   #print "Will stay in " . `pwd` . "\n"; 
  }

  # The log in process must happen after we switched to the right directory as done above
  &wikipedia_login();
  
  my ($stats, $detailed_stats, $detailed_combined_stats);
  $detailed_combined_stats = "{{shortcut|WP:OAFD|WP:OLDAFD}}\n";

  my $summary_file  = "Wikipedia:Articles_for_deletion/Old.wiki";
  my $detailed_file = "Wikipedia:Articles_for_deletion/Old/Open AfDs.wiki";

  my $attempts=10;
  my $sleep=1;
  my ($text, $edit_summary, $error);
  $text = &wikipedia_fetch($summary_file, $attempts, $sleep);

  # add the discussion from five days ago, if it is not already in $text
  ($text, $edit_summary) = &add_another_day ($text);

  # Find the number of open discussions for each listed day
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

  # Update the list of archived disucssions, the ones that are no longer at AfD/Old,
  # which is the text in $combined_stats
  my $archive_file = "Wikipedia:Archived deletion discussions.wiki";
  my $archive_text = &wikipedia_fetch($archive_file, $attempts, $sleep);
  my $success;
  ($archive_text, $edit_summary, $success) = &update_archived_discussions($archive_text,
                                                                       $combined_stats);
  if ($success){
    &wikipedia_submit($archive_file, $edit_summary, $archive_text, $attempts, $sleep);
  }
  
  print "<br>Finished! One may now go back to "
     . "<a href=\"http://en.wikipedia.org/w/index.php?title=Wikipedia:Articles_for_deletion/Old&action=purge\">" 
	. "Wikipedia:Articles for deletion/Old</a>. <br>\n";
}


sub add_another_day{

  my ($text, $afd_link, $hour_now, $thresh, $edit_summary, $SECONDS_PER_DAY, $brief_afd_link, $seconds);
    
  $text = shift;  

  # If beyond certain hour of the day (midnight GMT time),
  # add a link for the Afd/VfD discussion six days ago if not here yet
  $hour_now=strftime("%H", localtime(time));
  $thresh = 0;  # midnight on gmt

  if ($hour_now < $thresh){
    return ($text, "");
  }

  ($afd_link, $brief_afd_link) = &get_afd_link(-6);
  
  my $tag='<!-- Place latest vote day below this line. Do not move or modify this line -->';
  $edit_summary="";
  if ($text !~ /\n\*\s*\[\[\Q$afd_link\E/){
    $text =~ s/$tag/$tag\n\* \[\[$afd_link\|$brief_afd_link\]\]/g;
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

sub extract_links{

  # Extract links to afd discussions and put them into a hash
  
  my $text = shift;
  my @links_arr
     = ($text =~ /\[\[(Wikipedia:Articles for deletion\/Log\/\d+.*?)(?:\||\]\])/g);

  my ($link, %links_hash);
  foreach $link(@links_arr){
    $links_hash{$link} = 1;
  }

  return %links_hash;
}

sub update_archived_discussions {

  # Daily Afd pages that are at least six days old and that are no longer
  # at Afd/Old (where they are closed) are considered archived, and
  # should be added to the list of archived Afd pages.

  my ($archived_text, $afd_text, $success, $curr_year, $prev_year);

  $success = 0; # Not successful yet
  
  $archived_text = shift; # What is currently on the archived discussions page
  $afd_text      = shift; # What is at AfD/Old, those things should not yet be archived

  # Identify the discussions in AfD/Old, which won't be added to the archive
  my %skip_archive = &extract_links($afd_text);
  
  $curr_year = strftime("%Y", gmtime(time));
  $prev_year = $curr_year - 1;
  
  if ($archived_text !~ /==+\s*$curr_year\s*==+/){

    # Add section for current year if missing
    if ($archived_text !~ /^(.*?)(==+\s*)$prev_year(\s*==+)(.*?)$/s){
      $success = 0; # failed
      return ("", "", $success); # Prev year section is missing, don't know what to do
    }

    # Add current year above previous year
    $archived_text = $1 . $2 . $curr_year . $3 . "\n" . $2 . $prev_year . $3 . $4;
  }

  # Any day in the current year up to seven days ago is a candidate to be in the archive
  # (unless, again, that page is still at AfD/Old). Days 0, -1, -2, -3, -4, -5 
  # are still open, while day -6 is now in the process of being closed.
  my $start = -7;
  my $stop  = -366;
  my $day;

  my ($new_links, $afd_link, $prev_afd_link, $link_sans_day, $prev_link_sans_day);
  my (@new_links_array);

  @new_links_array = ();
  $new_links     = "";
  $prev_afd_link = "";
  
  # Add only the days from the current year to the archive.
  # Go in reverse, from the most recent date towards the past.
  my $first_day = 1; # mark that this is the first day in the list
  for ($day = $start ; $day >= $stop ; $day--){

    my ($afd_link, $brief_afd_link) = &get_afd_link($day);

    # Pages which are still at Afd/Old should not be archived yet.
    # Eventually after all discussions in such page are closed, the users will
    # remove the page from AfD/Old, and then the bot will get its hand on it.
    next if (exists $skip_archive{$afd_link});
    
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
      $new_links = $new_links . "\n===$link_sans_day===\n\n";

      $first_day = 0; # First day passed
    }
    
    $new_links = $new_links .  "* [[$afd_link]]\n";
    push(@new_links_array, $afd_link);
    
    # Prepare for the next loop
    $prev_afd_link = $afd_link;
  }

  # Before updating $archived_text, see what is there currently, so that
  # we can see what changed and put that in the edit summary.
  if ($archived_text !~
      /^(.*?==+\s*$curr_year\s*==+)(.*?)(==+\s*$prev_year\s*==.*?)$/s) {
    $success = 0; # failed
    return ("", "", $success); # Prev year section is missing, don't know what to do
  }

  my $p1 = $1;
  my $existing_text = $2;
  my $p3 = $3;

  # See what links are in @new_links_array and are not in %existing_links.
  # Put those in the edit summary.
  my %existing_links = &extract_links($existing_text);

  my $edit_summary = "";
  foreach $afd_link (@new_links_array){
    if (!exists $existing_links{$afd_link}){
      # This is a link which will be added to the archive now and which was
      # not there before
      $edit_summary = $edit_summary . "[[$afd_link]] ";
    }
  }

  if ($edit_summary eq ""){
    # Now new links were added now
    $success = 0; # failed
    return ("", "", $success);
  }

  # Replace in $archived_text the portion corresponding to the links for this year
  # with $new_links which contains the newly archived links 
  $archived_text = $p1 . "\n" . $new_links . "\n" . $p3;

  $success = 1; # succeeded
  $edit_summary = "Archiving " . $edit_summary;

  return ($archived_text, $edit_summary, $success);
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

