require 'bin/strip_accents.pl';

# A routine which will take a string and strip accents and everything else,
# leaving only digits and letters. This is needed to sort the math articles.
# The approach I use below is kind of convoluted, but it works. 
sub strip_accents_and_stuff { 

  local $_=shift;

  # The particular case of an article title with no alphanumberics in it.
  # Encode to HTML (thus, ascii only).
  if (! /[a-zA-Z0-9]/){
    s/([^A-Za-z0-9_\-.:])/sprintf("0 %%%02x",ord($1))/eg; 
    $_ = "0 " . $_; # to sort on top. This is needed in places.
  }

  # strip the actual accents
  $_ = strip_accents($_);
  
  # the special case of a word starting with a dash (minus). Sort it towards the top.
  s/^-/0  0/g;

  # replace dashes and underscores with a space
  s/[_-]/ /g; # spaces

  # replace starting non-alphanumeric with 0
  s/^[^\w]+/0/g; 

  # make all upper case, to help with sorting.
  $_=uc($_); 

  return $_; 
}

1;
