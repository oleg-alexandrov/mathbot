#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use LWP::Simple;

undef $/;

# find all math categories by crawling up from [[Category:Mathematics]]
my ($article, @articles, $cat, @cats, $text, $wget, %new, $counter, $url, $url_short);
$url="https://en.wikipedia.org/wiki";
$url_short="https://en.wikipedia.org";
$wget="wget -q -O - ";

open (FILE, "<Categories.txt");
@cats=split("\n", <FILE>);
close(FILE);

$counter=0;
open (FILE, ">Articles_shortened_list.txt");
foreach $cat (@cats) {
  
  next if ($cat =~ /^-/);	      # ignore certain categories, flagged by a minus
  $cat =~ s/^.*?\s//g;		      # remove some numbering
  $counter++; print "Now we are in category: $counter/527\n";
  print "sleep 5\n";
  `sleep 5`;

  if ($cat =~ /^http/){
    print "Now in \"$cat\n\"";
    $text=`$wget "$cat"`;
    
  }elsif ($cat =~ /^\/w\//){
    print "Now in $url_short$cat\n";
    $text=`$wget "$url_short$cat"`;
    
  }else{
    print "Now in \"$url/$cat\"\n";
    $text=`$wget "$url/$cat"`;
  }
  
  if ($text =~ /Articl\w+\s+in\s+category(.*?)Retrieved\s+from/s) {
    $text = $1;
    
    @articles = ($text =~ /\/wiki\/(.*?)\"/g);
    foreach $article (@articles) {

      # ignore certain types of articles (well pretty much anything having a colon)
      next if ($article =~ /\//); 
      next if ($article =~ /^Template:/); 
      next if ($article =~ /^User:/);
      next if ($article =~ /^Wikipedia:/);
      next if ($article =~ /^Image:/);
      next if ($article =~ /^Category:/);
      next if ($article =~ /^Talk:/);
      next if ($article =~ /^\w+[_\s]*talk:/i);
      
      if ( !exists $new{$article} ) {
	$new{$article}=1;     # discovered new article
	print FILE "$article\n";
	print "$article\n";
      }
    }

  }else{
   print "Error! No articles in $url/$cat !!!\n"; 
  }
}
  
close(FILE);
