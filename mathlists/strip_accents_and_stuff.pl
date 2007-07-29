require Encode;
use Unicode::Normalize;
use utf8;
use Encode 'from_to';

# will live a string with nothing but letters and digits (unless the number contains no letters and no digits)
sub strip_accents_and_stuff { 

  local $_=shift;

  # the particular case of article title with no alphanumberics in it.
  if (! /[a-zA-Z0-9]/){
    s/([^A-Za-z0-9_\-.:])/sprintf("0 %%%02x",ord($1))/eg; # encode to HTML (thus, ascii only)
    $_ = "0 " . $_; # to sort on top. This is needed in places.
  }
  
  s/\x{2212}/-/g; # make the Unicode minus into a hyphen
  s/\x{2013}/-/g; # make the Unicode ndash into a hyphen
  s/\x{2014}/-/g; # make the Unicode mdash into a hyphen
  s/\x{0398}/theta/g;  # make the Unicode theta into theta
  s/\x{03B8}/theta/g;  # make the Unicode theta into theta
  s/\x{0393}/gamma/g;  
  s/\x{0394}/delta/g;  
  s/\x{03B5}/epsilon/g;
  s/\x{039C}/mu/g;
  s/\x{03BC}/mu/g;
  s/\x{220A}/epsilon/g;
  s/\x{0221E}/infinity/g; # another problem character
  s/\*/star/g; 

  my @letters=split("", $_);
  foreach (@letters){

    ##  convert to Unicode first
    ##  if your data comes in Latin-1, then uncomment:
    #$_ = Encode::decode( 'iso-8859-1', $_ );  

   s/\xe4/a/g;  ##  treat characters \x{00E4} \x{00F1} \x{00F6} \x{00FC} \x{00FF}
   s/\xf1/n/g;  ##  this was wrong in previous version of this doc    
   s/\xf6/o/g;
   s/\xfc/u/g;
   s/\xff/y/g;

   $_ = NFD( $_ );   ##  decompose (Unicode Normalization Form D)
   s/\pM//g;         ##  strip accents

   # additional normalizations:
   s/\x{00df}/ss/g;  ##  German beta \x{201C}\x{00DF}\x{201D} -> \x{201C}ss\x{201D}
   s/\x{00c6}/AE/g;  ##  \x{00C6}
   s/\x{00e6}/ae/g;  ##  \x{00E6}
   s/\x{0132}/IJ/g;  ##  \x{0132}
   s/\x{0133}/ij/g;  ##  \x{0133}
   s/\x{0152}/Oe/g;  ##  \x{0152}
   s/\x{0153}/oe/g;  ##  \x{0153}

   tr/\x{00d0}\x{0110}\x{00f0}\x{0111}\x{0126}\x{0127}/DDddHh/; # \x{00D0}\x{0110}\x{00F0}\x{0111}\x{0126}\x{0127}
   tr/\x{0131}\x{0138}\x{013f}\x{0141}\x{0140}\x{0142}/ikLLll/; # \x{0131}\x{0138}\x{013F}\x{0141}\x{0140}\x{0142}
   tr/\x{014a}\x{0149}\x{014b}\x{00d8}\x{00f8}\x{017f}/NnnOos/; # \x{014A}\x{0149}\x{014B}\x{00D8}\x{00F8}\x{017F}
   tr/\x{00de}\x{0166}\x{00fe}\x{0167}/TTtt/;                   # \x{00DE}\x{0166}\x{00FE}\x{0167}

   s/([^\0-\x80])//g;  ##  strip everything else
   
 }
  
  $_ = join ("", @letters);
  
  s/^-/0  0/g; # the special case of a word starting with a dash (minus). Sort it towards the top.
  s/[_-]/ /g; # spaces
  #  s/[^\w ]//g; # rm nonalphanumeric/nonspace -- this makes different articles appear as if they were same
  s/^[^\w]+/0/g; # replace starting non-alphanumeric with 0

  $_=uc($_); # make all upper case, to identify articles which differ on only case

  return $_; 
}

1;
