#!/usr/bin/perl -w

use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Encode;

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/perlwikipedia_utils.pl'; # my own packages, this and the one below
require 'bin/perlwikipedia_utils.pl';
require 'bin/html_encode_decode_string.pl';
require 'bin/get_html.pl';
undef $/;		      # undefines the separator. Can read one whole file in one scalar.

require $ENV{HOME} . '/public_html/wp/wp10/wp10_routines.pl';

MAIN:{

  $| = 1; # flush the buffer each line
  
  my ($file, @files, $text, $sleep, $attempts, @tmp, $article, $cat, @articles, @red, @archives, @base_cats, @cats);
  my ($blacklist_orig, $blacklist_file, $cats_file, $cats_orig);
     
  my $Editor=wikipedia_login();  $sleep = 5; $attempts=10;
  
  @base_cats=('Category:Complexity classes');

  $text = '
EP Quantum Mechanics
Eclipse cycle
Edge
Effective fitness
Eigenpoll
Einstein-Cartan theory
Elasticity (economics)
Empirical relationship
Enigma machine
Enoch Root
Envelope
Equatorial bulge
Equivilisation
Error-correcting code
Escape velocity
Ethernet flow control
Expensive Desk Calculator
Explicit symmetry breaking
Exposure variable
Extension (semantics)
FNN algorithm
Face validity
Facial symmetry
Falconer\'s formula
Feature space
Fencepost error
Fermi problem
Feshbach-Fano partitioning
Feynman slash notation
Fictitious force
Fine-structure constant
First principles
Fisher\'s fundamental theorem of natural selection
Flight dynamics
Flood fill
Floor effect
Floor numbering
Fluid-structure interaction
Fluxion
Formal semantics of programming languages
Free tree
Frequency
Frequency spectrum
Fresnel zone
Fujiwara\'s function
Full moon cycle
Fundamental unit
Fused multiply-add
Fundamental unit
GNU Scientific Library
';

  push (@articles, split("\n", $text));
  
  foreach $cat( @base_cats){
    &fetch_articles_and_cats($cat, \@cats, \@tmp);
    push (@articles, @tmp);
  }

  $blacklist_file = 'User:Mathbot/Blacklist.wiki';
  open(FILE, "<$blacklist_file"); $blacklist_orig = <FILE>; close(FILE);
  
  open(FILE, ">$blacklist_file");
  print FILE "$blacklist_orig\n";
  foreach $article (@articles){

    next if ($article =~ /^\s*$/);
    print FILE "\[\[$article\]\]\n";
    print "$article\n";
  }
  close(FILE);

  # not very elegant
  system('./update_mathematics_delme.pl');

  # put back the original blacklist
  open(FILE, ">$blacklist_file");
  print FILE "$blacklist_orig";
  close(FILE);

}

