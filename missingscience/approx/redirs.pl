#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use Encode;

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';

undef $/;		      # undefines the separator. Can read one whole file in one scalar.

MAIN: {
  
  my ($text, $line, @lines, $from, $to, $tob, $file, %Done, $edit_summary);

  &wikipedia_login();
  
  open (FILE, "<:utf8", "Done.txt");    $text = <FILE>;    close (FILE);
  foreach (split ("\n", $text)){      $Done{$_}=1;    }  
  
  $text=&fetch_file_nosave("User:Mathbot/Page3.wiki", 100, 1);
  @lines = split ("\n", $text);
  foreach (@lines){
    next unless (/^\s*\#\s*(.*?)\s*--------\s*(.*?)\s*$/);
    $from = $1; $to=$2;
    
    if (exists $Done{$from}){
      print "Did \[\[$from\]\] before, skipping...\n";
      next;
    }

    open (FILE, ">>:utf8", "Done.txt");    print FILE "$from\n";   close (FILE);

    $Done{$from}=1;
    print "Redirecting from \[\[$from\]\]  to \[\[$to\]\]\n";

    $text = &fetch_file_nosave($from . ".wiki", 3, 1);
    if ($text !~ /^\s*$/){
      print "------------------\"$from\" exists, skipping.\n";
      next;
    }
    
    $file = $to . ".wiki";
    $text=&fetch_file_nosave($file, 100, 1);
    if ($text =~ /^\#redirect.*?\[\[(.*?)\]\]/i){
      $tob=$1;
      $tob =~ s/(\||\#).*?$//g; 
      next if ($tob =~ /^\s*$/);
      &fetch_file_nosave($from . ".wiki", 3, 1);
      
      #      $edit_summary = "Redirect from \[\[$from\]\] to \[\[$to\]\] "
      #      . "(and bypass redirect to \[\[$tob\]\]). "
      # . "This edit is filling in redlinks in the math section of \[\[WP:MST\]\]";

      $edit_summary = "Redirect from \[\[$from\]\] to \[\[$to\]\] (and bypass redirect to \[\[$tob\]\]). "
	 . "This is a user-supervized edit";
      
      &submit_file_nosave($from . ".wiki", $edit_summary, "#redirect \[\[$tob\]\]", 3, 1);
    }else{

#      $edit_summary = "Redirect from \[\[$from\]\] to \[\[$to\]\]. "
#	 . "This edit is filling in redli\nks in the math section of \[\[WP:MST]\]";

      $edit_summary = "Redirect from \[\[$from\]\] to \[\[$to\]\]. "
	 . "This is a user-supervized edit";
      
      &submit_file_nosave($from . ".wiki", $edit_summary, "#redirect \[\[$to\]\]", 3, 1);
	           
    }


    sleep 5;
  }
  
  
}   


