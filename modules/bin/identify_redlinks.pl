undef $/; # undefines the separator. Can read one whole file in one scalar.

require 'bin/html_encode_decode.pl';
require 'bin/get_html.pl';
require 'bin/rm_extra_html.pl';

# use main to avoid the curse of global variables
sub identify_redlinks {

  my ($article, $redlinks, $bluelinks, $wiki_http, $link, $error, $text, @matches);

  $article = shift; $redlinks = shift; $bluelinks = shift; 
  
  $wiki_http='http://en.wikipedia.org';

  $link = $wiki_http . '/wiki/' . &html_encode ($article);
  print "Identify redlinks/bluelinks in $link\n";
  
  ($text, $error) = &get_html ($link);

  @$bluelinks = ($text =~ /\<a\s+href=\"\/wiki\/[^\>\"]*?\"\s*title=\"([^\>\"]*?)\"/g);

  @$redlinks =
     ($text =~ /\<a\s+href=\"\/w\/index\.php\?title=[^\>\"]*?\&amp;action=edit\"\s*class=\"new\"\s*title=\"([^\>\"]*?)\"/g);

  foreach $link (@$bluelinks){
    $link = &rm_extra_html ($link);
  }

  foreach $link (@$redlinks){
    $link = &rm_extra_html ($link);
  }

  print "Sleep 1\n"; sleep 1;
}

1;
