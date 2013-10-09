#!/usr/bin/perl

$| = 1; # flush the buffer each line

# This line must be the first to print in a cgi script
print "Content-type: text/html\r\n\r\n";

use POSIX;                     # the strftime function
use CGI::Carp qw(fatalsToBrowser);
use strict;
undef $/; 

use lib $ENV{HOME} . '/public_html/cgi-bin/wp/modules'; # absolute path to perl modules
use lib '/home/mathbot/public_html/cgi-bin/wp/modules'; # absolute path to perl modules
use lib '../wp/modules'; # relative path to perl modules

require 'bin/perlwikipedia_utils.pl';
require 'bin/get_html.pl';

# Count and list the pages containing Wikipedia articles for deletion discussions (AfD).
# Archive the pages on which all deletion discussions are closed.
# Initialize pages for the upcoming days.

# Discussions more than this number of days in the past are considered old and must be listed at AfD
my $afd_cutoff = 7; 

my $gEditor;

MAIN: {
  
  print "Please be patient, this script can take a minute or two "
     .  "if Wikipedia is slow ...<br><br>\n";

  # If the full path to the script is known (such as when running this
  # script from crontab), go to that directory first
  my $cur_dir = $0; # $0 stands for the executable, with or without full path
  if ($cur_dir =~ /^\//){
    $cur_dir =~ s/^(.*)\/.*?$/$1/g;
    chdir $cur_dir;
  }else{
  }

  # The log in process must happen after we switched to the right directory as done above
  $gEditor=wikipedia_login();

  my $attempts = 10;
  my $sleep    = 1;

  my $summary_file  = "Wikipedia:Articles_for_deletion/Old.wiki";
  my $detailed_file = "Wikipedia:Articles_for_deletion/Old/Open AfDs.wiki";

  # Display the number of open afd discussions in the pages listed in
  # in $summary_file and put links to those those discussions in $detailed_file.
  # Return the list of pages in $combined_stats, we'll need that to decide which
  # pages to archive.
  my $combined_stats = &count_and_list_open_AfDs($summary_file, $detailed_file,
                                                 $attempts, $sleep);

  # Update the list of archived disucssions, the ones that are no longer at AfD/Old,
  # which is the text in $combined_stats
  my $archive_file = "Wikipedia:Archived deletion discussions.wiki";
  &update_archived_discussions($archive_file, $combined_stats, $attempts, $sleep);
  
  # Initialize afd pages for the next several days
  &initialize_new_afd_days($attempts, $sleep);
  
  print  "<br>Finished! One may now go back to "
       . "<a href=\"http://en.wikipedia.org/w/index.php?title="
       . "Wikipedia:Articles_for_deletion/Old&action=purge\">" 
       . "Wikipedia:Articles for deletion/Old</a>. <br>\n";
}


sub count_and_list_open_AfDs {

  # Display the number of open afd discussions in $summary_file and list them in $detailed_file.
  
  my $summary_file  = shift;
  my $detailed_file = shift;
  my $attempts      = shift;
  my $sleep         = shift;
      
  my ($stats, $detailed_stats, $detailed_combined_stats);
  $detailed_combined_stats = "<noinclude>{{Older AfDs}}<noinclude/>\n{{shortcut|WP:OAFD|WP:OLDAFD}}\n";

  my ($text, $edit_summary, $error);

  # Fetch the summary file
  $text = wikipedia_fetch($gEditor, $summary_file, $attempts, $sleep);

  # add the discussion from $afd_cutoff+1 days ago, if it is not already in $text
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
    $text = wikipedia_fetch($gEditor, $link, $attempts, $sleep); 

    #my $full_link = $link; $full_link =~ s/ /_/g;
    #$full_link = 'http://en.wikipedia.org/wiki/' . $full_link;

    #($text, $error) = &get_html ($full_link);

    # see which AfD debates are not closed yet, and put that info in the link. 
    # Get both a brief and a complete list, to put in different places.
    ($stats, $detailed_stats) = &see_open_afd_discussions ($link, $text, $detailed_file, $attempts, $sleep);
    $detailed_combined_stats = $detailed_combined_stats . $detailed_stats;

    $line = '* [[' . $link . '|' . $brief_afd_link . ']] ' . $stats;
    $stats_hash{$link} = "$line";
  }

  # The file might have changed while we were doing the calculation above.
  # Get a new copy.
  $text = wikipedia_fetch($gEditor, $summary_file, $attempts, $sleep);
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

  wikipedia_submit($gEditor, $summary_file, $edit_summary, $combined_stats, $attempts, $sleep);
  wikipedia_submit($gEditor, $detailed_file, $edit_summary, $detailed_combined_stats, $attempts, $sleep);

  return $combined_stats;
}

sub add_another_day{

  my ($text, $afd_link, $hour_now, $thresh, $edit_summary, $SECONDS_PER_DAY, $brief_afd_link, $seconds);
    
  $text = shift;  

  # If beyond certain hour of the day (midnight GMT time),
  # add a link for the Afd discussion six days ago if not here yet
  $hour_now=strftime("%H", localtime(time));
  $thresh = 0;  # midnight on gmt

  if ($hour_now < $thresh){
    return ($text, "");
  }

  ($afd_link, $brief_afd_link) = &get_afd_link(-$afd_cutoff-1); # Older than $afd_cutoff
  
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

  my $archive_file = shift; # The name of the file containing the archives
  my $afd_text     = shift; # What is at AfD/Old, those things should not yet be archived
  my $attempts     = shift;
  my $sleep        = shift;

  # The current text on the archive. We'll add to it.
  my $archived_text = wikipedia_fetch($gEditor, $archive_file, $attempts, $sleep);

  my ($curr_year, $prev_year);

  # Identify the discussions in AfD/Old, which won't be added to the archive
  my %skip_archive = &extract_links($afd_text);
  
  $curr_year = strftime("%Y", gmtime(time));
  $prev_year = $curr_year - 1;
  
  if ($archived_text !~ /==+\s*$curr_year\s*==+/){

    # Add section for current year if missing
    if ($archived_text !~ /^(.*?)(==+\s*)$prev_year(\s*==+)(.*?)$/s){
      print "Previous year section is missing, don't know what to do<br><br>\n";
      return;      
    }

    # Add current year above previous year
    $archived_text = $1 . $2 . $curr_year . $3 . "\n" . $2 . $prev_year . $3 . $4;
  }

  # Any day in the current year up no earlier than
  # $afd_cutoff+2 days ago is a candidate to be in the archive
  # (unless, again, that page is still at AfD/Old). Days 0, -1,
  # -2, -3, -4, -5, , ...  -$afd_cutoff are still open, while
  # day -$afd_cutoff-1 is now in the process of being closed.
  my $start = -$afd_cutoff-2; my $stop  = -366; my $day;

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
    print "Previous year section is missing, don't know what to do<br><br>\n";
    return;
  }

  my $p1            = $1;
  my $existing_text = $2;
  my $p3            = $3;

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
    print "No new pages to archive<br><br>\n";
    return;
  }

  # Replace in $archived_text the portion corresponding to the links for this year
  # with $new_links which contains the newly archived links 
  $archived_text = $p1 . "\n" . $new_links . "\n" . $p3;

  $edit_summary = "Archiving " . $edit_summary;
  
  wikipedia_submit($gEditor, $archive_file, $edit_summary, $archived_text, $attempts, $sleep);
}

sub see_open_afd_discussions (){

  my $link = shift;
  my $text = shift;
  my $detailed_file = shift;
  my $attempts = shift;
  my $sleep = shift;
  $sleep = 0.1;

  $text =~ s/\<\!--.*?--\>//g;
  my @pages = ( $text =~ /\{\{((?:WP|Wikipedia):Articles for deletion\/.*?)\}\}/ig);
  my ($openc, $closedc, $allc) = (0, 0, 0);
  my $stats = "";
  foreach my $page (@pages){
	  #print "$page\n";
	  $text = wikipedia_fetch($gEditor, $page, $attempts, $sleep);
	  #print "$text\n";
	  if ($text =~ /boilerplate[\s\w]*afd vfd xfd-closed/){
		  $closedc++;
	  }else{
		  $openc++;
		  $stats = "$stats " . "\[\[$page\|$openc]]";
          }
	  $allc++;
	  #exit(1);

     #if ($openc > 0 || $allc > 20) { last; } # temporary!!!  
  }
  print "$stats\n";
  print "($openc open / ";
  print "$closedc closed / ";
  print "$allc total discussions)<br>\n";
  #exit(1);

  #my $match  = "[^\>]*?\>\\[\<a href=\"[^\"]*?section=T-1\" title=\"([^\"]*?)\"\>edit";
  #my @all    = ($text =~ /\<span\s+class=\"mw-editsection$match/g );
  #my @open   = ($text =~ /\<span\s+class=\"mw-editsection[^-]$match/g );
  #my @closed = ($text =~ /\<span\s+class=\"mw-editsection-closed$match/g );

  #$openc=0;
  # foreach (@open) {
  #  $openc++;
  #  # Link to the page having the currently open afd
  #  #print "open $_\n";
  #  $stats = "$stats " . "\[\[$_\|$openc]]";
  #}
  #print "($openc open / ";

  #$closedc=0;
  # foreach (@closed) {
  #  $closedc++;
  #}
  # print "$closedc closed / ";

  #$allc=0;
  #foreach (@all) {
  #  $allc++;
  #}
  #print "$allc total discussions)<br>\n";

  # Some gimmickry, to list to sections in $detailed_file
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

sub initialize_new_afd_days {

  # Initialize afd pages for the next several days by putting in a
  # preamble for each day. When such a future day becomes today, the
  # users will edit that afd page page and will add afd listings below
  # the preamble.

  print "\n\n<br><br><b>Initializing AfD pages for the next several days</b><br>\n";
  
  # Parameters related to fetching/submitting data to Wikipedia
  my $attempts = shift;
  my $sleep    = shift;
  
  my ($day);
  
  for ($day = 1 ; $day < 5 ; $day++){
    
    my ($prev_afd_link, $prev_afd_name) = &get_afd_link($day - 1);
    my ($curr_afd_link, $curr_afd_name) = &get_afd_link($day + 0);
    my ($next_afd_link, $next_afd_name) = &get_afd_link($day + 1);

    my $days_page = $curr_afd_link . ".wiki";
    my $days_text = wikipedia_fetch($gEditor, $days_page, $attempts, $sleep);

    if ($days_text !~ /^\s*$/){
      # This day's page is not empty, so it was already initialized. Skip it.
      print "Page exists<br><br>\n\n";
      next;
    }
    
    # Form the page for the current day
    $days_text = &get_page_text($prev_afd_link, $prev_afd_name,
                                $next_afd_link, $next_afd_name);

    # Initialize the page for the day
    print "\n<br>Initializing $curr_afd_link<br>\n";
    my $edit_summary = "Initializing a new AfD day";
    wikipedia_submit($gEditor, $days_page, $edit_summary, $days_text, $attempts, $sleep);

  }
  
}

sub get_page_text {

  my ($prev_afd_link, $prev_afd_name, $next_afd_link, $next_afd_name) = @_;

  # Strip the text in parentheses from the text "1 February (Sunday)"
  $prev_afd_name =~ s/\s*\(.*?\)\s*//g;
  $next_afd_name =~ s/\s*\(.*?\)\s*//g;
  
return '{{Recent AfDs}}
<div class="boilerplate metadata vfd" style="background-color: #F3F9FF; margin: 0 auto; padding: 0 1px 0 0; border: 1px solid #AAAAAA; font-size:10px">
{| width = "100%"
|-
! width="50%" align="left"  | <font color="gray">&lt;</font> [['
. $prev_afd_link . '|' . $prev_afd_name
. ']]
! width="50%" align="right" |  [['
. $next_afd_link . '|' . $next_afd_name
. ']] <font color="gray">&gt;</font>
|}
</div>
<div align = "center">\'\'\'[[Wikipedia:Guide to deletion|Guide to deletion]]\'\'\'</div>
{{Cent}}
<small>{{purge|Purge server cache}}</small>
__TOC__
<!-- Add new entries to the TOP of the following list -->

';
   
}

