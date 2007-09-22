require 'bin/html_encode_decode.pl';
require 'bin/get_html.pl';

sub fetch_articles_cats{

  my ($cat, $cats, $articles, $wiki_http, $text, $error, $tmp, $continue, $link, $count);

  $wiki_http="http://en.wikipedia.org";

  $cat = shift; $cat=&html_encode($cat); # category to search
  $cats=shift; $articles=shift; # the last two are actually arrays, will contain the output artcicles/cats

  @$cats=(); @$articles=();
  $link = "$wiki_http/wiki/$cat";

  $continue=1;
  while ($continue){
     print "Now getting $link<br>\n";

     ($text, $error) = &get_html($link);

    # get categories
    if ($text =~ /\<h2\>Subcategories\<\/h2\>(.*?)\<h2\>\<a name\=\"Pages.in.category/si){
      $tmp=$1;
      @$cats = (@$cats,  ($tmp =~ /\"\s*\/wiki\/(Category:.*?)\"/g));
    }

    # Get articles. If can't detect the text region which should contain articles, bail out
    if ($text =~ /\<h2\>\<a name\=\"Pages.in.category(.*?)Retrieved\s+from/is){
      $tmp = $1;
      @$articles = (@$articles, ($tmp =~ /\/wiki\/(.*?)\s*\"/g));
    }else{ 
      print "Error. The category system is broken! Can't detect pages in categories! Exiting!\n";
      exit (0);
    }

    # See if this category continues on a next page. If so, will get its continuation also
    if ($text =~ /\"\s*(\/w\/index\.php\?title=\Q$cat\E\&amp;from=[^\&]*?)\s*\"/i ) { # continuation of current category
      $link = "$wiki_http$1"; $link =~ s/\&amp;/\&/g; # decode the ampersand
    }else{
     $continue=0; # stop here 
    }

     print "Sleep 1 second\n"; sleep 1;
  }

  # decode from html
  foreach $link (@$articles){   $link = &html_decode($link);  }
  foreach $link (@$cats)    {   $link = &html_decode($link);  }
}

1;

