#!/usr/bin/perl

use strict;

eval {
  require '/data/project/mathbot/public_html/wp/modules/bin/perlwikipedia_utils.pl';
}; 
if ($@){
  print "$@\n:";
}

use POSIX qw(locale_h);
use locale;

MAIN: {
  test_cats();

  #test_bot();
  
}

# A routine to test fetching articles and categories in given category
sub test_cats {
  my $cat = "Mathematics";
  my (@cats, @articles);

  fetch_articles_and_cats($cat, \@cats, \@articles);

  print "parent cat is $cat\n";
  foreach my $val (@cats){
    print "1new cat $val\n";
  }

  foreach my $val (@articles){
    print "1new article $val\n";
  }

  my (@new_articles, @new_categories);
  fetch_articles_in_cats(\@cats, \@new_articles, \@new_categories);
  
  foreach my $val (@new_categories){
    print "2new cat $val\n";
  }

  foreach my $val (@new_articles){
    print "2new article $val\n";
  }
}

# A routine testing fetching and submitting text to Wikipedia
sub test_fetch_submit {

  my $editor; # Kept for api compatibility, not used
  my $attempts = 10; 
  my $sleep    = 1;
  my $edit_summary = "test bot";
  my $test_file = "User:Mathbot/sandbox.wiki";
  my $test_text = wikipedia_fetch($editor, $test_file, $attempts, $sleep);
  print "Got the text $test_text\n";

  $test_text .= "Test4.";

  if ($test_text =~ /^.*?(User:Mathbot\/Unicode_.*?)\n/s) {
     $test_file = $1;
     print "Match file: $test_file\n";
  } else {
    print "No match!";
  }
  print "Test file is $test_file\n";

  $edit_summary = "Test4: $test_file";
  print "Edit summary is: $edit_summary\n";
  wikipedia_submit($editor, $test_file, $edit_summary, $test_text, $attempts, $sleep);

  exit(1);
}
