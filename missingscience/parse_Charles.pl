#!/usr/local/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
use WWW::Mediawiki::fetch_submit; # my own packages, this and the one below
use WWW::Mediawiki::fetch_submit_nosave; # my own packages, this and the one below
use WWW::Mediawiki::wikipedia_login;
use utf8;
undef $/;		      # undefines the separator. Can read one whole file in one scalar.

MAIN: {

#    &submit_file_nosave("User:Mathbot/Page$i.wiki", "A list, to test my bot.", $text, 10, 1);

  my ($text, @links, $link);
  $text = &gimme_answer;
  @links = ($text =~ /\[\[\/(.*?)\]\]/ig);

  $text="";
  foreach $link (@links){
    print "$link\n";
    $link = "User:Charles_Matthews/$link.wiki";
    $text = $text . "\n" . &fetch_file_nosave($link, 10, 2);
  }
  $text =~ s/==.*?==\s*\n//g; # strip section names
  
  open (FILE, ">", "Parsed_Charles.txt");
  @links = ($text =~ /\[\[(.*?)\]\]/g);
  foreach $link ( sort {$a cmp $b} @links){
    $link =~ s/^(.)/uc($1)/eg; $link =~ s/_/ /g;
    next if ($link =~ /(Charles.Matthews|Wikipedia)/);
    next if ($link =~ /^\s*$/);
    next if ($link =~ /[A-Z]\.[A-Z ]/); # proper names
    print FILE "\* \[\[$link\]\]\n";
  }
  close(FILE);
  
}
sub gimme_answer {

  return "
==Mathematics==
*[[/red links]]
*[[/MathematicsA]] - [[/MathematicsB]] - [[/MathematicsC]] - [[/MathematicsD]] - [[/MathematicsE]]
*[[/MathematicsF]] - [[/MathematicsG]] - [[/MathematicsH]] - [[/MathematicsI]] -[[/MathematicsJ]]
*[[/MathematicsK]] - [[/MathematicsL]] - [[/MathematicsM]] - [[/MathematicsN]] -[[/MathematicsO]]
*[[/MathematicsP]] - [[/MathematicsQ]] - [[/MathematicsR]] - [[/MathematicsS]] -[[/MathematicsT]]
*[[/MathematicsU]] - [[/MathematicsV]] - [[/MathematicsW]] - [[/MathematicsXYZ]]

*[[/Atiyah]] - [[/AtiyahII]] -
[[/AtiyahVI]] - - [[/GuilleminSternberg]] - - [[/Heegner]] -

   [[/Special_functions_%26_eponyms]]
   ";
}

