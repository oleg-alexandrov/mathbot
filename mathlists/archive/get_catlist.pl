#!/usr/bin/perl
use strict;                            # 'strict' insists that all variables be declared
use diagnostics;                       # 'diagnostics' expands the cryptic warnings
use LWP::Simple;

undef $/;

# find all math categories by crawling up from [[Category:Mathematics]]

my (@stuff, $level, $cat, $newcat, @cats, $text, $wget, %old, %new, %newnew, $slevel, @toc_cats, $url, $url_short);
$url="https://en.wikipedia.org/wiki";
$url_short="https://en.wikipedia.org";
$wget="wget -q -O - ";

open (FILE, ">Categories.txt");

# read initilalization from file
@stuff = split("\n", <>);
foreach (@stuff){

  next if (/^\s*$/); # ignore empty lines
  s/\s*$//g; # remove trailing whitespace
  
  if (/^-/){ # these are the cats we will ignore in the future
    s/^.*?\s+//g; # remove whatever numbering was there
    $old{$_}=1;

    print "Ignore $_.\n";

  }else{
    s/^.*?\s+//g; # remove whatever numbering was there
    $new{$_}=1;

    print "Use $_\n";
    print FILE "$_\n";
  }
}


for ($level=1 ; $level < 100 ; $level++){

  # go through each category just discovered but not yet visited
  foreach $newcat (keys %new){
    
    print "sleep 5\n";
    `sleep 5`;
    
    # don't look in the old categories (they also contain categories I want to avoid)
    next if (exists $old{$newcat}); 
    
    $old{$newcat}=1; # downgrade current category right away to "old".
    delete $new{$newcat}; # and remove from "new"

    # links to categories can have three types:
    if ($newcat =~ /^http/){
      print "Now in $newcat\n";
      $text=`$wget "$newcat"`;

    }elsif ($newcat =~ /^\/w\//){
      print "Now in $url_short$newcat\n";
      $text=`$wget "$url_short$newcat"`;
      
    }else{
      print "Now in $url/$newcat\n";
      $text=`$wget $url/$newcat`;
    }

    # this shows up when categories have lots of entries and tables of contents
    $text =~ s/\&amp;/\&/g; # convert to plain &
    @toc_cats = ($text =~ /(http[^\s]*?$newcat\&from[^\<]*?)\"/g);
    @toc_cats = (@toc_cats, ($text =~ /\"(\/w\/index.php\?title=$newcat\&from[^\<]*?)\"/g));

    # cut down on false positives
    if ($text =~ /subcategor\w+ to this category(.*?)articl\w+ in this category/s){
      $text = $1;
    }else{
     $text=""; 
    }

    # all categories in this category are in @cats
    @cats = (@toc_cats, $text =~ /\"\/wiki\/(Category:.*?)\"/g);
    foreach $cat (@cats){
      
      if ( (!exists $old{$cat}) && (!exists $new{$cat}) && (!exists $newnew{$cat}) ){
	$newnew{$cat}=1; # discovered new category

	print "$level: $cat\n";
	print FILE "$level: $cat\n";
      }
    }
  }

  # downgrade from newnew to just new
  foreach $newcat (keys %newnew){
    $new{$newcat}=1;
    delete $newnew{$newcat}; 
  }
}

close(FILE);


