#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Encode;
undef $/; # undefines the separator. Can read one whole file in one scalar.

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/wikipedia_login.pl';
require 'bin/wikipedia_fetch_submit.pl'; 
require 'bin/identify_redlinks.pl';
require 'utils/strip_accents_and_stuff.pl';

MAIN:{
  my (%links, $html_data, $letter, $count, @reds, @blues, $stripped_link, $link, %pages, %all_links_freq);
  my ($file_encoded, $file, $red, $red_stripped, $text, $bot_page, $bot_link, $sleep, $attempts, %redlinks_freq);

  &wikipedia_login(); $sleep = 2;
  $attempts = 100; # make $attempts large, it is surprising how often commits fail
  $bot_page = 'User:Mathbot/Page2';

  # read into a hash
  $count=0;
  open (FILE, "<", "Links.txt"); $text=<FILE>; close(FILE);
  foreach $link (split ("\n", $text)){

    next unless ($link =~ /^\[\[\s*(.*?)\s*\]\]\s+-*\s+(\d+)/);
    $link=$1; $all_links_freq{$link} = $2;
    
    # strip accents 
    $stripped_link = decode("utf8", $link);
    $stripped_link=  &strip_accents_and_stuff ($stripped_link);
  
    # sort alphabetically, without overwriting items differing by accents
    $count++;
    $links{$link}= "$stripped_link $count"; 

    # The line below is useful for debugging. Don't remove. 
    #last if ($count > 1000);
  }
  print "Done reading the hash\n";

  # split into subpages, by first letter
  foreach $link (sort {$links{$a} cmp $links{$b}} keys %links){
    
    next unless ($links{$link} =~ /^(.)/);
    $letter = uc($1);
    $letter = "0-9" if ($letter =~ /[^A-Z]/i); # collapse non-alphabetic in one list
    
    $pages{$letter}= "" unless (exists $pages{$letter});
    $pages{$letter} = $pages{$letter} . "\[\[$link\]\]\n";

  }

  #identify redlinks
  foreach $letter (sort {$a cmp $b} keys %pages){
    print "$letter\n";

    # submit to server several times, and wait a while,
    # otherwise the page on the server is not always updated
    for (my $repeat = 0; $repeat <= 2; $repeat++){
      &wikipedia_submit($bot_page . '.wiki', "Add links, both blue and red",
			$pages{$letter}, $attempts, $sleep);
       print "Sleep 20\n"; sleep 20; 
    }
    
    &identify_redlinks($bot_page, \@reds, \@blues);
    
    $text="__NOTOC__\n{{User:Mathbot/Redlinks/TOC}}\n";
    $text = $text . &create_sectioned_list (\@reds);
  
    $file = "User:Mathbot/List_of_mathematical_redlinks_($letter).wiki";
    &wikipedia_submit($file, "Update the list of redlinks", $text, $attempts, $sleep);  

    # store the redlinks by frequency
    foreach $link (@reds){
      if (exists $all_links_freq{$link}){
	$redlinks_freq{$link} = $all_links_freq{$link};
      }
    }
    #last;
  }

  # submit the most wanted links
  my $most_wanted = 'User:Mathbot/Most wanted redlinks.wiki';
  $text = "";
  foreach $link (sort {$redlinks_freq{$b} <=> $redlinks_freq{$a} } keys %redlinks_freq){
    
    last if ($redlinks_freq {$link} <= 1);
    $text .=  "\* \[\[$link\]\] -- $redlinks_freq{$link}\n";

  }
  &wikipedia_submit($most_wanted, "Update this list", $text, $attempts, $sleep);
    
}

sub create_sectioned_list {

  my ($red, $red_stripped, $reds, $count, $text);

  $reds = shift;

  $count=1000;
  $text = "";
  foreach $red (@$reds){
    if ($count > 51){

      $red_stripped = decode("utf8", $red);
      $red_stripped = &strip_accents_and_stuff($red_stripped);

      #print "==$red_stripped==\n";
      $red_stripped = substr($red_stripped, 0, 2);
      $text = $text . "==$red_stripped==\n";
      $count=0;
    }

    #	print "$red\n";
    $text = $text . "\[\[$red\]\] -- \n";
    
    $count++;
  }

  return $text;
}

