#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use open 'utf8';
binmode STDOUT, ':utf8';

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/perlwikipedia_utils.pl'; # my own packages, this and the one below
require 'bin/fetch_articles.pl';
undef $/; # undefines the separator. Can read one whole file in one scalar.


# necessary to fetch data from Wikipedia and submit
my $Editor;
my $sleep = 5;
my $attempts=500; 

MAIN: {

  my ($user, $edit_summary, $text, $image_list, %images, $image, $black_list);
  my ($tagged_images, %tagged, $cat, $line);
  
  $image_list = 'User:Mathbot/Page1.wiki';
  $black_list = 'User:Mathbot/Page2.wiki';
  $tagged_images = 'Tagged_images.txt';
  $cat = 'Category:Files by User:Oleg Alexandrov from en.wikipedia';
    
  open(FILE, "<$tagged_images");
  $text = <FILE>;
  close(FILE);

  foreach $image (split ("\n", $text)){
    next unless ($image =~ /Image:/);
    $image =~ s/\s*$//g;
    print "Tagged: $image\n";
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

  $text = wikipedia_fetch($Editor, $image_list, $attempts, $sleep);
  foreach $line (split ("\n", $text)){

    $line =~ s/\|.*?$//g;
    $line =~ s/\]\].*?$//g;
    $line =~ s/\s*$//g;
    
    next unless ($line =~ /(Image:.*?)$/);

    $image = $1;
    $images{$image} = 1;

    print "Will work on $image.\n";
  }

  #&parse_upload_log($black_list, \%images);
  
  foreach $image ( keys %images ){

    if (exists $tagged{$image}){
      print "Tagged: $image\n";
      next;
    }

    print "$image\n";
    $text = wikipedia_fetch($Editor, $image, $attempts, $sleep);

    if ($text =~ /$cat/){
      print "$image already is in $cat\n";
      next;
    }

    if ($text !~ /Oleg Alexandrov/){
      print "Error! My name is not in $image!!!\n";
#       exit(0);
    }


    $text .= "\n\[\[$cat\]\]\n";
    $edit_summary = "Adding current image to \[\[$cat\]\].";
    wikipedia_submit($Editor, $image, $edit_summary, $text, $attempts, $sleep);

    $tagged{$image} = 1;
    open(FILE, ">>$tagged_images");
    print FILE "$image\n";
    close(FILE);

  }

}

sub parse_upload_log {


  my ($text, $line, @lines, $black_list, %blacklisted, $images, $image);

  $black_list = shift;
  $images = shift;
  
  $text=wikipedia_fetch($Editor, $black_list, $attempts, $sleep);
  open(FILE, ">$black_list");
  print FILE "$text\n";
  close(FILE);

  foreach $line (split ("\n", $text)){
    next unless ($line =~ /\[\[:(Image:.*?)\]\]/);

    $image = $1;
    $blacklisted{$image} = 1;
  }
  
  open(FILE, "<upload_log.html");
  $text = <FILE>;
  close(FILE);

  @lines = split("\n", $text);
  foreach $line (@lines){

    next unless ($line =~ /uploaded \"<a href=\".*?\".*?title=\"(.*?)\"/i);

    $image = $1;
    next if (exists $blacklisted{$image});
    next if (exists $images->{$image});
    $images->{$image} = 1;

  }
}
