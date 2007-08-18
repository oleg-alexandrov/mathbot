#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings

use open 'utf8';
undef $/; # undefines the separator. Can read one whole file in one scalar.

my (@lines, %articles, $letter, $link, $name, $name_stripped, %special);
my (%new_blacklist, $counter, %blacklist, %mathematicians);


# articles which we will not allow in the math list
open (FILE,  '<', "User:Mathbot/Blacklist.wiki");
@lines = split ("\n", <FILE>);
close(FILE);

foreach (@lines) {
  next if (/^\s*$/);
  s/\[\[//g;
  s/\]\].*?$//g;
    
  $blacklist{$_}=1;
}

# Articles blacklisted as mathematicians
open (FILE,  '<', "All_mathematicians.txt");
@lines = split ("\n", <FILE>);
close(FILE);

foreach (@lines) {
  next if (/^\s*$/);
  $mathematicians{$_}=1;
}

# now read in the newer articles (some of these might eventually overwrite some of the above)
open (FILE, '<', "All_mathematics_from_cats.txt");
@lines=split("\n", <FILE>);
close(FILE);

open (FILE, '>', "User:Mathbot/Blacklist.wiki");
foreach ( sort {$a cmp $b } @lines){
  s/\[\[//g;
  s/\]\].*?$//g;

  # Mathematicians are taken care of by other means
  next if (exists $mathematicians{$_}); 

  if (exists $blacklist{$_}){
    print FILE "[[$_]] -- \n";
    $new_blacklist{$_} = 1;
  }
}

foreach (keys %blacklist){
  next if (exists $new_blacklist{$_});
  print "[[$_]] removed from the blacklist.\n";
}

close(FILE);
