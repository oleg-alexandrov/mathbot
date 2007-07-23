#!/usr/local/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
use WWW::Mediawiki::fetch_submit; # my own packages, this and the one below
use WWW::Mediawiki::wikipedia_login;
use LWP::Simple;
use LWP::UserAgent;
use Encode;
require "identify_red.pl";
undef $/;		      # undefines the separator. Can read one whole file in one scalar.

MAIN: {

  my ($file, @files, $text, @lines, $line, $link, %links, %blacklist, %red, %blue);

  open (FILE, "<:utf8", 'Wikipedia:Missing_science_topics/Blacklisted.wiki');
  @lines = split ("\n", <FILE>);
  close(FILE);
  foreach (@lines){
    next unless (/\[\[(.*?)\]\]/);
    $blacklist{$1}=1;
  }
  
  $text="";
  #  @files=</u/cedar/h1/afa/aoleg/public_html/wp/pmstat/Wikipedia:WikiProject_Mathematics/PlanetMath_Exchange/[0-9]*.wiki>;
  @files = ('Fetched_planetmath.txt');
  foreach $file (@files){
    open (FILE, "<:utf8", "$file");
    $text = $text . "\n" . <FILE>;
    close(FILE);
  }

  $text =~ s/\&\#(\d+);/chr($1)/eg;
  @lines = split("\n", $text);
  foreach $line (@lines){
    next unless ($line =~ /WP\s*(guess|)\s*:?\s*\[\[(.*?)\]\]\s*/);
    $link = $2;
    $link =~ s/_/ /g;
    $link =~ s/\s+/ /g;
    $link =~ s/^\s*//g;
    $link =~ s/^(.)/uc($1)/eg;
    $link =~ s/\#.*?$//g;
    $link =~ s/\s*-+\s*/-/g;
    next if ($link =~ /(\\|\^|\/|\$|\{|\})/); # TeX, etc
    next if  ($link =~ /^proof/i); # proofs
    next if  ($link =~ /^properties/i); # proofs
    next if  ($link =~ /^property/i); # proofs
    next if  ($link =~ /\bexamples?\b/i); # examples
    next if  ($link =~ /\bbibliograph\w+\b/i); # examples
    next if  ($link =~ /\bcorollary\b/i); # examples
    next if  ($link =~ /\bderivation of\b/i); # examples
    next if  ($link =~ /\bis\b/i); # "is" statements
    next if  ($link =~ /\bare\b/i); # "is" statements
    next if  ($link =~ /\bdigital library\b/i); # "is" statements
    next if  ($link =~ /\bhas\b/i); # "is" statements
    next if  ($link =~ /\bhave\b/i); # "is" statements
    next if  ($link =~ /\bproofs?\b/i); # "is" statements
    next if  ($link =~ /\bplanetmath\b/i); # "is" statements
    next if  ($link =~ /\bexample\b/i); # "is" statements
    next if  ($link =~ /^a\s/i); # "is" statements
    next if  ($link =~ /^alternat/i); # 
    next if  ($link =~ /^bibliograph/i); # 
    next if  ($link =~ /^biograph/i); # 
    next if  ($link =~ /^concept/i); # 
    next if  ($link =~ /^continuity/i); # 
    next if  ($link =~ /^more\b/i); # 
    next if  ($link =~ /^taking\b/i); # 
    next if  ($link =~ /Euler-Fermat theorem\)/i); # incorrect link
    next if  ($link =~ /User:/i); # no users please
    next if  ($link =~ /Hahn-Banach theorem\(geometric form\)/i); # incorrect link
    next if ($link =~ /^\s*$/);
    next if (length ($link) >= 40); # ignore the way too long entries
    next if (exists $blacklist{$link});

    $links{$link}=1;
  }

  $text="";
  foreach $link ( sort {$a cmp $b} keys %links){
    $text = $text .  "\* \[\[$link\]\]\n";
  }

  open (FILE, ">:utf8", "Parsed_planetmath.txt");
  print FILE "$text\n";
  close(FILE);

  exit(0); # stop here if we want both the blue and the red links
  &identify_red(\%red, \%blue, $text); # problem! This code may cause trouble if server is down!!!!!!!!!

  $text="";
  foreach $link ( sort {$a cmp $b} keys %links){
    next unless (exists $red{$link});
    $text = $text .  "\* \[\[$link\]\]\n";
  }

  &submit_file_nosave("User:Mathbot/Page3.wiki", "Planetmath redlinks.", $text, 10, 2);

  open (FILE, ">", "Parsed_planetmath.txt");
  print FILE "$text\n";
  close(FILE);

}

