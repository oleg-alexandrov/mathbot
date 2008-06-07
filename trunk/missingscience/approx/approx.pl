#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use Encode;
use String::Approx qw(amatch);

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';

undef $/;		      # undefines the separator. Can read one whole file in one scalar.

# use main to avoid the curse of global variables
MAIN: {

  my ($wget, $text, @red, $misses, $prefix, $i, $file, $link, @lines, @miss, $line, $blue, $log, $logtext, $logtext2);
  my (@possib, $letter, %done, @letters, %pos, $count, @bad, %blacklist, $redirect, $redir_file);
  @letters=("0", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",  "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",  "X", "Y", "Z");

  open (FILE, "<", "Blacklisted_redirects.txt");
  foreach (split ("\n", <FILE>)){
    next unless (/(\[\[.*?\]\].*?\[\[.*?\]\])/);
    $_=$1;
    $blacklist{$_}=1;
  }
  
  
  $redir_file="Possible_redirects.txt";
  open (FILE, ">$redir_file");  print FILE "\n"; close(FILE); # black this file

  foreach $letter (@letters){
  
    print "$letter\n";
    
    open (FILE, "<", "All_possib.txt");  $text = <FILE>;  close (FILE);
    $text =~ s/(\[\[)\s*/$1/g; $text =~ s/\s*(\]\])/$1/g; $text =~ s/(\[\[.)/uc($1)/eg;
    @possib = ($text =~ /\[\[($letter.*?)\]\]/ig);

    %pos=(); # @possib put in a hash
    foreach (@possib){
      $pos{$_}=1;
    }
    
    open (FILE, "<", "All_missing.txt");
    $text = <FILE>;
    close (FILE);
    $text =~ s/(\[\[)\s*/$1/g; $text =~ s/\s*(\]\])/$1/g; $text =~ s/(\[\[.)/uc($1)/eg;
    @miss = ($text =~ /\[\[($letter.*?)\]\]/ig);
    
    open (FILE, ">>$redir_file");
    print FILE "\n==$letter==\n\n";
    foreach $misses (@miss){
      
      next if ($misses =~ /^\s*$/);
      next if (exists $done{$misses});
      $done{$misses}=1;

      $count = 0; 
      foreach (sort {$a cmp $b } keys %pos){
	next if (lc ($misses) eq lc ($_)); # don't look at the case there is equality up to case
	if ( amatch($misses, ["i15%"]) ){ # went from 2% to 5%. Next time go to 10%, see what happens.
	  $redirect="\[\[$misses\]\] -------- \[\[$_\]\]"; # don't modify the amount of dashes here!
	  if (exists $blacklist{$redirect}){
	    next;
	  }
	  print "\* $redirect\n";
	  print FILE "\* $redirect\n";
	  $count++;

	  if ($count >= 10){ # the current $misses has too many matches. Bail out.
	    @bad = (@bad, $misses);
	    last;
	  }
	}
      }  # end of matching of current $misses
      
    }
    close(FILE);
  }

  open(FILE, ">Bad_misses.txt");
  foreach (@bad){
    print FILE "\[\[$_\]\]\n";
  }
  close(FILE);
  
}

