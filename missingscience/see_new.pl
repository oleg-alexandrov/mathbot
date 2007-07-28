#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
undef $/; # undefines the separator. Can read one whole file in one scalar.

# See what articles exist in New.txt which do not exist
# either as redlinks or as blue links on WP:MST
MAIN: {

  my ($old_text, $new_text, $iter, $prefix, $blacklist);
  my (%old, %new);

  $prefix='Wikipedia:Missing science topics/';
  $blacklist='Wikipedia:Missing science topics/Blacklisted.wiki';
  
  # read the articles currently in WP:MST from disk
  $old_text = "";
  for ($iter=1 ; $iter <=30  ; $iter++){

    open(FILE, '<', $prefix . 'Maths' . $iter . '.wiki');
    $old_text .= <FILE> . "\n";
    close(FILE);
  }

  for ($iter='A' ; $iter ne 'AA'  ; $iter++){
    open(FILE, '<', $prefix . 'ExistingMath' . $iter . '.wiki');
    $old_text .= <FILE> . "\n";
    close(FILE);
  }

  open(FILE, '<', $prefix . 'ExistingMath' . '0' . '.wiki');
  $old_text .= <FILE> . "\n";
  close(FILE);

  open(FILE, "<$blacklist"); $old_text .= <FILE> . "\n"; close(FILE);
    
  # the new articles
  open(FILE, "<New.txt");
  $new_text = <FILE>; close(FILE);
  
  &parse_to_hash ($old_text, \%old);
  &parse_to_hash ($new_text, \%new);

  print "New articles:\n";
   &in_notin(\%new, \%old);
}


sub parse_to_hash {

  my ($text, $hash) = @_;

  my $line;
  foreach $line (split ("\n", $text)){
    next unless ($line =~ /\[\[(.*?)\]\]/);
    $hash->{lc($1)} = $1;
  }
  
}


sub in_notin {

  my ($h1, $h2) = @_;
  my ($line);

  foreach $line (sort {$a cmp $b} keys %$h1){
    print "* [[" . $h1->{$line} . "]]\n" if (! exists $h2->{$line}); 
  }
  
}
