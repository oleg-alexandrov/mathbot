# try to guess the first name and the last name, and then arrange name in order last, first
sub get_last {
  my ($name, $first, $last);
  
  $name = shift;
  $name =~ s/\s*\([A-Za-z ]+\)\s*$//g; # from Oleg A (mathematician), rm the (mathematician) part
  
  return $name if ($name =~ / of /); # this is not a correct last/first combination 
  return $name if ($name !~ / /); # only one word

  # try to guess last name based on nationality
  if ($name =~ /^(.*) (.*?) (Jr\.?)$/){
    $first=$1; $last="$2 $3";                     # Junior
  }elsif ($name =~ /^(.*?) (van .*?)$/){
    $first=$1; $last=$2;                          # dutch
  } elsif ($name =~ /^(.*?) (von .*?)$/){
    $first=$1; $last=$2;                          # german
  } elsif ($name =~ /^(.*?) (de .*?)$/i){
    $first=$1; $last=$2;                          # french
  } elsif ($name =~ /^(.*?) (di .*?)$/){
    $first=$1; $last=$2;                          # italian
  } elsif ($name =~ /^(.*?) (del .*?)$/){
    $first=$1; $last=$2;                          # more italian
  } elsif ($name =~ /^(.*?) (bin .*?)$/){
    $first=$1; $last=$2;                          # arabic 
  } elsif ($name =~ /^(.*?) (ibn .*?)$/){
    $first=$1; $last=$2;                          # arabic 
  }elsif ($name =~  /^(.*?) (Le .*?)$/) {         # French
    $first=$1; $last=$2;
  }elsif ($name =~  /^(.*?) (bar .*?)$/) {         # Jewish
    $first=$1; $last=$2;
  }elsif ($name =~ /^(.*?) ([^ ]*?)$/) {
    $first=$1; $last=$2;
  }
  # if none of those cases are covered, do this
  # transfer von to Neumann
  if ($first =~ /^(.*?) ([a-z]+)$/) {
    $first = $1; $last="$2 $last";
  }
  
#   # works for van der Waerden
  if ($first =~ /^(.*?) ([a-z]+)$/) {
    $first = $1; $last="$2 $last";
  }

  # one more time, just in case
  if ($first =~ /^(.*?) ([a-z]+)$/) {
    $first = $1; $last="$2 $last";
  }
  
  $name = "$last, $first";
  return $name;
}

1;
