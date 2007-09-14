use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings

sub rm_extra_html {

  my $text = shift;

  $text =~ s/\&amp;/\&/g;
  $text =~ s/\&quot;/\"/g;
  $text =~ s/\&lt;/\</g;
  $text =~ s/\&gt;/\>/g;
  
  return $text;
}

1;
