#!/usr/bin/perl

use lib $ENV{HOME} . '/public_html/cgi-bin/wp/modules'; # path to perl modules

use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use WWW::Mediawiki::Client;   # upload from Wikipedia

require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
require 'bin/get_html.pl';
require $ENV{HOME} . '/public_html/cgi-bin/wp/rfa/parse_edits.pl';
require $ENV{HOME} . '/public_html/cgi-bin/wp/rfa/extract_user.pl';

undef $/;		      # undefines the separator. Can read one whole file in one scalar.

MAIN: {

  my ($file, $text, $user, $sorting, $i, $success, $counter, $base, $log, $message, $nomin_nowiki);
  my (@recent_nomins, $nomin, $nomin_talk, $nomin_text, $beg, $end, $tag, %done, $key, $old_text);
  my ($nomin_or_talk, $edit_summary, $lang, $editsum, $tag_base);
  
  $success=0;
  $base=150;		      # base the percentage of edit summaries on $base last major and minor edits
  $lang = 'en';
  $beg='<!-- begin editcount box-->'; $end='<!-- end edit count box -->';
  
  chdir $ENV{HOME} . '/public_html/cgi-bin/wp/rfa';
  
  open (FILE, "<Done.txt"); $text=<FILE>;  close(FILE);
  $sorting=0;
  foreach $key (split "\n", $text) {
    $key =~ s/\s+\d+$//g;
    $done{$key}=$sorting;
    $sorting++; # arrange in hash in existing order, to write back in same order later
  }
  
  &wikipedia_login();
  $file='Wikipedia:Requests for adminship.wiki';
  $text=&fetch_file_nosave($file, 100, 1);
  if ($text =~ /^\s*$/) {
    print "Error! $file can't be empty!\n";
    exit(0);		      # there is some error, this file can't be empty
  }
  
  $sorting=-1000; # to make sure that newer entries come on top
  @recent_nomins = ($text =~ /\{\{(Wikipedia:Requests?[ _]for[ _](?:adminship|bureaucratship)\/.*?)\}\}/ig);

  foreach $nomin (@recent_nomins) {
    
    $nomin =~ s/_/ /g; $nomin = $nomin . ".wiki";
    $nomin_talk = $nomin; $nomin_talk =~ s/Wikipedia:/Wikipedia talk:/i; $nomin_talk =~ s/\.wiki$//g;  
    
    next if ($nomin =~ /Wikipedia:Requests for adminship\/Front matter/i); # not a real admin candidate
    next if ($nomin =~ /Wikipedia:Requests for adminship\/bureaucratship/i); # not a real admin candidate
    
    if (exists $done{$nomin}) {
      print "$nomin has been dealt with before\n";
      next;
    }
  
    print "Now dealing with $nomin\n";
    $nomin_text = &fetch_file_nosave($nomin, 10, 1); 
    $user = &extract_user ($nomin_text);
    next if ($user =~ /^\s*$/);
    
    $tag_base= $beg . "\n"
       . "*See \[\[User:$user\|$user\]\]\'s edit summary usage with " 
          . "[http://toolserver.org/~mathbot/cgi-bin/wp/rfa/edit_summary.cgi?user=" 
             . &html_encode($user) 
                . "&lang=$lang mathbot's tool]. "
                   . "For the edit count, see the \[\[$nomin_talk\|talk page\]\].\n"
                      . $end . "\n";
    $tag = $tag_base;
    print "$tag\n";
    
    # Do a quick post of the edit _count_ before getting to the main
    # business, posting a link to the edit _summary_ tool
    &post_edit_summary_on_talk_page($user, $nomin_talk);
    
    # try several times to add the comment on candidate's page. Stop if it is confirmed that the bot was successful
    $nomin_or_talk = $nomin; 
    for ($i=1 ; $i <= 20 ; $i++) {
      print "\nAttempt $i at submitting the edit summary link of $user\n\n";
      
      # if it failed after several tries, try instead to add the comment on the talk page
      if ($i >= 5){
        $nomin_or_talk = $nomin_talk . '.wiki';
        $nomin_or_talk = "Wikipedia talk:Requests for adminship.wiki" if ($i >= 10);
        $nomin_or_talk = "User talk:Oleg Alexandrov.wiki" if ($i >= 15);
        $tag = "==A bot request==\nHi. Can somebody please add the link below to the RfA? I can't do it, \n"
           . "presumably since this RfA was speedy deleted in the past and I can't handle that. Thanks!\n\n"
              . $tag_base . "\n\n~~~~\n\n";
      }
      
      # try to get the article one time, with 0 second sleep in between
      $nomin_text = &fetch_file_nosave($nomin_or_talk, 1, 0);
      
      if ($nomin_text =~ /\Q$beg\E/) { # thus said, stop the loop if success was achieved
        
        print "Success! Verified that the text was accepted!\n"; 
        $done{$nomin}=$sorting; # true success, mark this as done
        $sorting++;
        last;
      }
      
      $old_text=$nomin_text;
      # locate where to put the bot text (in '''Comments''')
      if ($nomin_text =~ /^(.*?\n(?:\'\'\'|\;|====)\s*General comments\s*?(?:\'\'\'|====|)\s*?\n)(.*?)$/s) { 
        $nomin_text = "$1$tag$2";
      } else {
        $nomin_text = "$nomin_text" . "$tag<!-- failed to locate the right place to put this text-->\n"; 
      }
      
      # try to submit the file just once, with zero sleep afterward
      # $success == 1 does not mean there was true success with current nomin, that is $done{$nomin}=$sorting;
      $message="Add a link to the edit summary usage tool for \[\[User:$user\|$user\]\]";
      $success=submit_file_advanced($nomin_or_talk, $message, $nomin_text, $old_text, 1, 0); 
      
      print "Sleep 5\n"; sleep 5; # take a nap, give the server a chance to update the info
    }
    
    $nomin_nowiki = $nomin; $nomin_nowiki =~ s/\.wiki//g;
  }
  
  $sorting=1;
  open (FILE, ">Done.txt");
  foreach $key ( sort { $done{$a} <=> $done{$b} } keys %done) {
    
    print FILE "$key $sorting\n";
    $sorting++;

    last if ($sorting > 1000);  # keep only the newest 1000 entries
  }
  close(FILE);

  exit (0) unless ($success); # the bot did not submit anything, so get out

  $log='User:Mathbot/Most recent admin candidate.wiki';

  $text=&fetch_file_nosave($log);
  $old_text=$text;
  $text = "~~~~"; # put the corrent datestamp in the file

  $editsum=&parse_edits($user, $lang, $base);

  $editsum = $editsum . " Nomin page: \[\[$nomin_nowiki\]\].";
  submit_file_advanced($log, $editsum, $text, $old_text, 2, 2); 
  
}		


sub post_edit_summary_on_talk_page{

  my ($user, $nomin_talk, $tool_url, $edit_count_text, $error, $old_text);
  my ($attempts, $sleep, $summary);

  $user = shift;
  $nomin_talk = shift;

  # .wiki extension necessary for submitting things
  $nomin_talk = $nomin_talk . '.wiki';
  
  $tool_url = 'http://toolserver.org/~interiot/cgi-bin/Tool1/wannabe_kate?username='
     . &html_encode($user)
        . '&site=en.wikipedia.org';
  

  # fetch the edit count, and extract only the necessary info from there
  print "Getting $tool_url\n";
  #($edit_count_text, $error) = get_html ($tool_url);
  #$edit_count_text = `/usr/bin/w3m -dump \"$tool_url\"`;
  $edit_count_text = `/usr/bin/lynx -dump \"$tool_url\"`;

  # strip extra newlines
  $edit_count_text =~ s/Based directly on these URLs.*?$//sg;
  $edit_count_text =~ s/[\t\r ]*\n/\n/g;
  $edit_count_text =~ s/\n\n\n+/\n\n/g;

  $edit_count_text =~ s/^.*?(User)/$1/sg;
  $edit_count_text = "<pre>\n" . $edit_count_text . "\n</pre>\n";
  
#  $edit_count_text =~ s/^.*?(\<table.*?\>.*?\<\/table\>).*?\s*$/$1/si;

  $edit_count_text = "==Edit count for $user==\n"
     . $edit_count_text . "\n"
        . "* The edit count was retrieved from \[$tool_url this link\] at ~~~~~.\n\n";

  $attempts = 2;
  $sleep = 5;
  
  $old_text = &fetch_file_nosave($nomin_talk, $attempts, $sleep);

  print "$edit_count_text\n";
  
  # Submit the edit count only if the talk page is empty.
  # (otherwise let the human editors figure it out).
  if ($old_text !~ /edit\s*count/i){

     $summary = "Posting the edit count for $user";
    
    $old_text =~ s/\s*$//g;

    $edit_count_text = $old_text . "\n\n" . $edit_count_text unless ($old_text =~ /^\s*$/);

    &submit_file_advanced($nomin_talk, $summary, $edit_count_text, $old_text, $attempts, $sleep);
    
  }else{ 
     print "$nomin_talk most likely has the edit count, so won't post it.\n";
  }  
}




