#!/usr/local/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings

use Encode;

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
require 'bin/fetch_articles_cats_old.pl';
require 'bin/html_encode_decode.pl';
require 'bin/get_html.pl';
require 'bin/strip_accents.pl';
require 'bin/identify_redlinks.pl';

undef $/;                     # undefines the separator. Can read one whole file in one scalar.

# use main to avoid the curse of global variables
MAIN: {
 
  my ($text, %alternatives, $link, @links, $link1, $link2);
  my ($link3, $hash, $count, $attempts, $sleep, @rl, @bl);
  my (%redlinks, %bluelinks, $page, $page_nowiki, @rtext, $btext, $sep);

  open(FILE, "<All_links.txt"); $text = <FILE>; close(FILE);
  @links = ($text =~ /\[\[(.*?)\]\]/g);

  $count = 0;
  foreach $link (@links){

#    $count++; last if ($count > 10000);
    
    $link1 = $link; $link1 = &strip_accents($link1);
    if ($link ne $link1){
      $alternatives{$link}->{$link}=1;
      $alternatives{$link}->{$link1}=1;
    }

    $link2 = $link; $link2 =~ s/\'s\b//g;
    if ($link ne $link2){
      $alternatives{$link}->{$link}=1;
      $alternatives{$link}->{$link2}=1;

      $link3 = $link2; $link3 = &strip_accents($link3);
      if ($link ne $link3){
	$alternatives{$link}->{$link}=1;
	$alternatives{$link}->{$link3}=1;
      }
      
    }
  }

  $text = "";
  foreach $link (sort {$a cmp $b} keys %alternatives){

    $hash = $alternatives{$link};
    $text .= "# ";
    foreach $link2 (keys %$hash ){
      $text .= " [[$link2]] -- ";
    }
    $text .= "\n";
  }
  
  &wikipedia_login();
  $attempts = 1; $sleep = 1; $page = "User:Mathbot/Page5.wiki";	
  &wikipedia_submit($page, "Some links", $text, $attempts, $sleep);

  $page_nowiki = $page; $page_nowiki =~ s/\.wiki$//g;

  for ($count=0 ; $count < 5 ; $count++){
    print "i=$count\n";
    &identify_redlinks($page_nowiki, \@rl, \@bl);
    foreach $link (@rl){ $redlinks{$link}  = 1; }
    foreach $link (@bl){ $bluelinks{$link} = 1; }
    sleep 5;
  }


  $text = ""; $sep = " -------- ";
  foreach $link (sort {$a cmp $b} keys %alternatives){
    
    $hash = $alternatives{$link};
    @rtext = (); $btext = "";
    foreach $link2 (keys %$hash ){
      $btext .= "[[$link2]]" if ( (!exists $redlinks{$link2}) && $btext =~ /^\s*$/);
      push (@rtext, "[[$link2]]") if (exists $redlinks {$link2});
    }

    next unless ($btext && @rtext);
    foreach $link2 (@rtext){
      $text .= "# " . $link2 . $sep . $btext . "\n";
    }
    
  }

  &wikipedia_submit("User:Mathbot/Page3.wiki", "Some links", $text, $attempts, $sleep);
  
}

