sub add_google_links {
  my ($tag, $wiki, $google, $books, $line, $link);

  $tag='<!-- bottag -->';
  $wiki='http://en.wikipedia.org/wiki/Special:Search?search=';
  $google='http://www.google.com/search?q='; $books='http://books.google.com/books?q=';
  
  $line = shift;
  if ($line !~ /\[\[(.*?)\]\]/){
    return $line;
  }
  $link = $1;
  $link = &html_encode($link);
  $link =~ s/_/\+/g;

  $line =~ s/\s*$tag.*?$//g; # strip earlier tag, if any
  $line = "$line $tag\(\[$wiki$link&go=Go wikisearch]; \[$google$link web\]; \[$books$link books\]\)";
  return $line;
}

1;
