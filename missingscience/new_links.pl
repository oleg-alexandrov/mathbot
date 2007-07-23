#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
undef $/; # undefines the separator. Can read one whole file in one scalar.

# use main to avoid the curse of global variables
MAIN: {

  my (%old, %new);

  &read_data ($ARGV[0], \%new);
  &read_data ($ARGV[1], \%old);

  print '{{col-begin}}
{{col-break}}
';
  &in_notin(\%new, \%old);

  print "{{col-break}}\n";
  &in_notin(\%old, \%new);
  print '{{col-break}}
{{col-end}}
';
}


sub read_data {

  my ($file, $hash) = @_;

  my ($text, $line);
  open(FILE, "<$file"); $text = <FILE>; close(FILE);

  foreach $line (split ("\n", $text)){
    next unless ($line =~ /\[\[(.*?)\]\]/);
    $hash->{$1} = 1;
  }
  
}


sub in_notin {

  my ($h1, $h2) = @_;
  my ($line);

  foreach $line (sort {$a cmp $b} keys %$h1){
    print "# [[$line]]\n" if (! exists $h2->{$line}); 
  }
  
}
