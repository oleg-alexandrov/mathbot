#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings

sub language_definitions {

  my $home = $ENV{'HOME'} || '/home/mathbot';
  
  my ($Lang, %Dictionary);

  $Lang='en';

  # add an if-statement for every language below
  if ($Lang eq 'en'){

    $Dictionary{'Lang'}        = $Lang;
    $Dictionary{'Wikipedia'}   = 'Wikipedia';
    $Dictionary{'Talk'}        = 'Talk';
    $Dictionary{'Category'}    = 'Category';
    $Dictionary{'WikiProject'} = 'WikiProject';
    $Dictionary{'WP'}          = 'WP';  # abbreviations of the word 'Wikipedia' and 'WikiProject'
    $Dictionary{'Credentials'} = "$home/api.credentials";
  }

  return %Dictionary;
}

# elsif ($Lang eq 'es'){
#   ...
#   $Dictionary{'Talk'}        = 'Discusi�n';
#   ... 
# }

1;
