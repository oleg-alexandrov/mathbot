# make a string acceptable in an URL
sub escape_things {

  # This is used a lot in fetch_articles_cats. Make sure
  # any changes here don't affect that code. 
  my $link = shift;
  $link =~ s/ /\+/g; 
  $link =~ s/\&/%26/g; 
  $link =~ s/\"/\&quot;/g;

  return $link;
}

1;
