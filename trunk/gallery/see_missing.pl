#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use open 'utf8';
binmode STDOUT, ':utf8';

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/perlwikipedia_utils.pl'; # my own packages, this and the one below
require 'bin/fetch_articles.pl';
require 'bin/html_encode_decode_string.pl';

undef $/; # undefines the separator. Can read one whole file in one scalar.

# necessary to fetch data from Wikipedia and submit
my $Editor;
my $sleep = 1;
my $attempts=500; 

MAIN: {

  my ($user, $edit_summary, $text, $image_list, %blacklisted, $image, $black_list);
  my ($tagged_images, %tagged, $cat, @lines, $line);
  
  $image_list = 'User:Mathbot/Page1.wiki';
  $black_list = 'User:Mathbot/Page2.wiki';
  $tagged_images = 'Tagged_images.txt';
    
  open(FILE, "<$tagged_images");
  $text = <FILE>;
  close(FILE);

  foreach $image (split ("\n", $text)){
    next unless ($image =~ /Image:/);
    $image =~ s/\s*$//g;
    
    print "Tagged: [[$image]]\n";
    $tagged{$image} = 1;
  }

  
  $user = 'Mathbot';
  $Editor = Perlwikipedia->new($user);

  # Turn debugging on, to see what the bot is doing
  $Editor->{debug} = 1;

  # set the wiki path
  $Editor->set_wiki('commons.wikimedia.org','w');

  # Log in. If the language is not set (see below) it defaults to 'en' (English).
  $Editor->login($user, 'torent77');

  $text = wikipedia_fetch($Editor, $black_list, $attempts, $sleep);
  foreach $line (split ("\n", $text)){

    $line =~ s/\|.*?$//g;
    $line =~ s/\]\].*?$//g;
    
    next unless ($line =~ /(Image:.*?)$/);

    $image = $1;
    $blacklisted{$image} = 1;

    print "Blacklisted: [[$image]].\n";
  }

  
  open(FILE, "<Gallery.php.html");  $text=<FILE>; close(FILE);
  @lines = ($text =~ /\<td valign=\'top\' title=\'Thumb\'.*?img src=.*?\?f=(.*?)\&amp;/ig);

  $text = "";
  foreach $image (@lines){
    $image = &html_decode_string($image);
    $image = 'Image:' . $image;
    
    next if (exists $blacklisted{$image});
    next if (exists $tagged{$image});

    $text .= "* [[:$image]]\n";
  }

  $edit_summary = "Add potential images";
  wikipedia_submit($Editor, $image_list, $edit_summary, $text, $attempts, $sleep);

}

