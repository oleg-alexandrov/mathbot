#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
require 'bin/fetch_articles_cats.pl';
undef $/;		      # undefines the separator. Can read one whole file in one scalar.

sub fetch_articles {

  my ($article, @articles, $cat, $cats, $text, %new_article, $cont_cat);
  my (%excluded_cats, %cat_hash, $text_cats, $newcats, @tmp, $newcat, $basecat, $new_articles, %newcat_hash);

  $cats=$_[0];  $new_articles=$_[1];  $newcats=$_[2];
  foreach $cat ( @$cats ){ $cat_hash{$cat}=1; }

  # Start harvesting the articles from these categories
  foreach $cat ( @$cats ) {
    &fetch_articles_cats($cat, \@tmp, \@articles);
    print "<font color=red>Error! No articles in $cat !!!</font><br>\n" unless (@articles);

    foreach $newcat (@tmp) {
      next if ( exists $cat_hash{$newcat} || exists $newcat_hash{$newcat});
      print "Detected new $newcat in $cat<br>\n";
      $newcat_hash{$newcat}=1; 
      push (@$newcats, $newcat);
    }
    
    foreach $article (@articles) {
      next if ($article =~ /:/); # ignore everything outside of the article namespace 
      
      next if ( exists $new_article{$article} );
      $new_article{$article}=1; # discovered new artile
      push (@$new_articles, $article);
    }
  }
}
1;

