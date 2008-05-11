#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
undef $/; # undefines the separator. Can read one whole file in one scalar.

# Replace Mathbot's login and password by some obfuscation
MAIN: {

  my $file = 'wikipedia_perl_bot/bin/perlwikipedia_utils.pl';
  open(FILE, "<$file");
  my $text = <FILE>;
  close(FILE);

  $text =~ s/Mathbot/DefaultBot/g;
  $text =~ s/(\$pass\s*=\s*)\'\w+\'/$1\'DefaultPassword'/g;

  open(FILE, ">$file");
  print FILE "$text";
  close(FILE);
  
}
