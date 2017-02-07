#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings

sub language_definitions {

  my $home = $ENV{'HOME'} || '/data/project/mathbot';
  my $Lang = shift || 'en';

  my %Dictionary;
  $Dictionary{'Credentials'} = "$home/api.credentials";

  # add an if-statement for every language below
  if ($Lang eq 'en' || $Lang eq 'beta'){
    $Dictionary{'Lang'}        = $Lang;
    $Dictionary{'Wikipedia'}   = 'Wikipedia';
    $Dictionary{'Talk'}        = 'Talk';
    $Dictionary{'Category'}    = 'Category';
    $Dictionary{'WikiProject'} = 'WikiProject';
    $Dictionary{'WP'}          = 'WP';  # abbreviations of the word 'Wikipedia' and 'WikiProject'
    $Dictionary{'Domain'}      = $Lang . '.wikipedia.org'; 
  }

 # Special case for the 'beta' Wikipedia
 if ($Lang eq 'beta'){
   $Dictionary{'Domain'}       = 'en.wikipedia.beta.wmflabs.org';
   $Dictionary{'Credentials'} .= '.beta';
 }

  return %Dictionary;
}

# elsif ($Lang eq 'es'){
#   ...
#   $Dictionary{'Talk'}        = 'Discusión';
#   ... 
# }

1;
