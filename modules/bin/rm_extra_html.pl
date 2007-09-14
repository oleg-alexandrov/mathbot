sub rm_extra_html {

  $text = shift;

  $text =~ s/\&amp;/\&/g;
  $text =~ s/\&quot;/\"/g;
  $text =~ s/\&lt;/\</g;
  $text =~ s/\&gt;/\>/g;
  
  return $text;
}

1;
