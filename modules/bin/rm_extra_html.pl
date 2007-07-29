use Encode;

sub rm_extra_html {

  $link = shift;

  $link =~ s/\&amp;/\&/g;
  $link =~ s/\&quot;/\"/g;
  
  #  $link = decode("iso-8859-1", $link);
  $link = encode('utf8', $link); # Unicode encoding seems to be necessary
  
  return $link;
}

1;
