# convert to HTML encoding and the reverse
sub html_encode {

  local $_=$_[0];

  s/ /_/g;
  s/([^A-Za-z0-9_\-.:\/])/sprintf("%%%02x",ord($1))/eg;
  return($_);
}

sub html_decode {
  local $_ = shift;
  s/_/ /g;
  tr/+/ /;
  s/%(..)/pack('C', hex($1))/eg;

  return($_);
}

1;
