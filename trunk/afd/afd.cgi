#!/usr/bin/perl
use POSIX;                     # the strftime function
use CGI::Carp qw(fatalsToBrowser);

use lib '/home/mathbot/public_html/cgi-bin/wp/modules'; # path to perl modules
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
require 'bin/get_html.pl';

undef $/; # undefines the separator. Can read one whole file in one scalar.

MAIN: {

  print "Content-type: text/html\n\n"; # this line must be the first to print in a cgi script

  $| = 1; # flush the buffer each line

  print "Please be patient, this script can take a minute or two if Wikipedia is slow ...<br><br>\n";
  
  chdir '/home/mathbot/public_html/wp/afd/'; # needed when running this from crontab
  &wikipedia_login();
  
  my ($info, $expanded_info, $tmp);
  $expanded_info = "{{shortcut|WP:OAFD|WP:OLDAFD}}\n";
 
  if (@ARGV){  $test=1;  }else{  $test=0;  } # see if we are in testing mode
  if (! $test){
    $file="Wikipedia:Articles_for_deletion/Old.wiki";
  }else{
    $file="User:Mathbot/Page3.wiki";  
  }
  $expanded_file = "Wikipedia:Articles_for_deletion/Old/Open AfDs.wiki";

  $attempts=10; $sleep=1;
  $text = &wikipedia_fetch($file, $attempts, $sleep);

  # add the discussion five days ago, if it is not already in $text
  ($text, $message) = &add_another_day ($text);

  @lines = split("\n", $text);
  foreach $line (@lines) {
    
    # extract the links to the open discussions
    next unless ($line =~ /^\*\s*\[\[(Wikipedia:(?:Pages|Votes|Articles) for deletion\/Log\/\d+.*?)\]\]/);
    $link=$1; 
    if ($link =~ /^(.*?)\|(.*?)$/){
       $link = $1; $after_pipe = $2;
    }else { 
       $after_pipe = $link;
    }
    print "Now doing $link ... ";
    
    $full_link=$link; $full_link =~ s/ /_/g; $full_link = 'http://en.wikipedia.org/wiki/' . $full_link;
    ($text, $error) = &get_html ($full_link);

    # see which AfD/VfD debates are not closed yet, and put that info in the link. 
    # Get both a summary and a complete list, to put in different places.
    ($info, $tmp) = &see_open_afd_discussions ($link, $text, $expanded_file);
    $expanded_info = $expanded_info . $tmp;

    $line = '* [[' . $link . '|' . $after_pipe . ']] ' . $info;
    $hash{$link} = "$line";
  }

  # The file might have changed while we were doing the calculation above. Get a new copy.
  $text = &wikipedia_fetch($file, $attempts, $sleep);
  ($text, $message) = &add_another_day ($text);
  @lines = split("\n", $text);
  
  # gather all the info in $text
  my $num_days = 0; # cout how many days are listed, ...
  my $num_disc = 0; # ... and how many discussions
  $text="";
  foreach $line (@lines){
    if ($line =~ /^\*\s*\[\[(Wikipedia:(?:Pages|Votes|Articles) for deletion\/Log\/\d+.*?)\s*(?:\||\]\])/) {
      $link=$1;
      $num_days++;
      if (exists $hash{$link}) {
	$line = $hash{$link};
      }
      if ( $line =~ /\((\d+) open/ ){
       $num_disc = $num_disc + $1;
      }
    }
    $text = $text . "$line\n";
  }

  $utc_time=strftime("%H:%M, %B %d, %Y (UTC)", gmtime(time));
  $text =~ s/(\/afd\/afd\.cgi.*?\]).*?\n/$1 \(last update at $utc_time\)\n/;

  $edit_summary="There are $num_disc open discusions in $num_days days." . $message;
  if ($num_disc > 200){
    $edit_summary = "Big Backlog: " . $edit_summary;
  }

  &wikipedia_submit($file, $edit_summary, $text, $attempts, $sleep);
  &wikipedia_submit($expanded_file, $edit_summary, $expanded_info, $attempts, $sleep);

  print "<br>Finished! One may now go back to "
     . "<a href=\"http://en.wikipedia.org/w/index.php?title=Wikipedia:Articles_for_deletion/Old&action=purge\">" 
	. "Wikipedia:Articles for deletion/Old</a>. <br>\n";
}


sub add_another_day{

  my ($text, $fivedays_ago, $hour_now, $thresh, $message, $SECONDS_PER_DAY, $after_pipe, $seconds);
    
  $text = shift;  

  # if beyond certain hour of the day, add a link for the Afd/VfD discussion 5 days ago if not here yet
  $hour_now=strftime("%H", localtime(time));
  $thresh=16;
  
  if ($hour_now < $thresh){
    return ($text, "");
  }
  
  $SECONDS_PER_DAY = 60 * 60 * 24;

  $seconds = time() - 5*$SECONDS_PER_DAY;
  $fivedays_ago=strftime("Wikipedia:Articles for deletion/Log/%Y %B %d", localtime($seconds));
  $fivedays_ago =~ s/ 0(\d)$/ $1/g; # make 2005 April 01 into 2005 April 1

#  $after_pipe = &fmt_date($fivedays_ago);
  $after_pipe = strftime("%d %B (%A)", localtime($seconds)); $after_pipe =~ s/^0//g;	  

  my $tag='<!-- Place latest vote day above - Do not remove this line -->';
  $message="";
  if ($text !~ /\n\*\s*\[\[\Q$fivedays_ago\E/){
    $text =~ s/$tag/\* \[\[$fivedays_ago\|$after_pipe\]\]\n$tag/g;
    $message=" Link to \[\[$fivedays_ago\]\].";
  }

  return ($text, $message);
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

sub see_open_afd_discussions (){
  my $link = shift;
  my $text = shift;
  my $expanded_file = shift;

  my $result = "";

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

    $result = "$result " . "\[\[$_\|$openc]]";
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

  # some gimmickry, to list to sections in $expanded_file.
  my $expanded_list = $result; 
  my $short_link = $link;
  $short_link =~ s/^.*\///g;
  $expanded_file =~ s/\.wiki$//g;

  # if there are too many open afds, link to the file listing them. Otherwise, list them right here. 
  if ($openc == 0 ){
    $result = "($openc open / $closedc closed / $allc total discussions)";
  }elsif ( $openc > 20 ){
    $result = "($openc open / $closedc closed / $allc total discussions; [[$expanded_file\#$short_link\|see open]])";
  }else{
    $result = "($openc open / $closedc closed / $allc total discussions; open: $result)";
  }

  my $http_link = $link; $http_link =~ s/ /_/g; 
  $http_link = '([http://en.wikipedia.org/w/index.php?title=' . $http_link . '&action=edit edit this day\'s list])'; 

  # text to add to a subpage listing all open discussions
  $expanded_list =~ s/\s*\[\[(.*?)\|\d+\]\]/\* \[\[$1\]\]\n/g;
  $expanded_list =~ s/_/ /g; 
  $expanded_list = "==[[$link\|$short_link]]==\n" . $http_link . "\n" . $expanded_list;
 
  return ($result, $expanded_list);  
}

