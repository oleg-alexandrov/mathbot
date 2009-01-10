require 'bin/html_encode_decode_string.pl';
require 'bin/get_html.pl';
require 'bin/rm_extra_html.pl';

sub identify_redlinks {

  my ($article, $redlinks, $bluelinks, $wiki_http, $link, $error, $text, @matches);

  $article = shift; $redlinks = shift; $bluelinks = shift; 
  
  $wiki_http='http://en.wikipedia.org';

  $link = $wiki_http . '/wiki/' . &html_encode_string ($article);
  print "Identify redlinks/bluelinks in $link\n";
  
  ($text, $error) = &get_html ($link);

  @$bluelinks = ($text =~ /\<a\s+href=\"\/wiki\/[^\>\"]*?\"\s*title=\"([^\>\"]*?)\"/g);

  # Careful here. The redlinks regexp should be pretty strict, otherwise it will have
  # a huge number of false positives.
  @$redlinks =
     ($text =~ /\<a\s+href=\"\/w\/index\.php\?title=([^\<\>\"]*?)\&amp;action=edit\&amp;redlink=1\"/ig);

  foreach $link (@$bluelinks){
    $link = &rm_extra_html ($link);
  }

  foreach $link (@$redlinks){
    $link = &rm_extra_html ($link);
    $link = &html_decode_string($link); # this is not necessary for bluelinks
  }

  print "Sleep 1\n"; sleep 1;
}

1;
