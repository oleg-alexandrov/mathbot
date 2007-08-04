sub rm_extra_html {

  $link = shift;

  $link =~ s/\&amp;/\&/g;
  $link =~ s/\&quot;/\"/g;
  
  return $link;
}

1;
