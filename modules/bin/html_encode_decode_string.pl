# convert to HTML encoding and the reverse
use Encode;

sub html_encode_string {

  local $_=$_[0];

  # encode to Unicode first
  $_ = Encode::encode('utf8', $_);
  
  s/ /_/g;
  s/([^A-Za-z0-9_\-.:\/])/sprintf("%%%02x",ord($1))/eg;
  return($_);
}

sub html_decode_string {
  local $_ = shift;
  s/_/ /g;
  tr/+/ /;
  s/%(..)/pack('C', hex($1))/eg;

  # decode from Unicode
  $_ = Encode::decode('utf8', $_);

  return($_);
}

1;
