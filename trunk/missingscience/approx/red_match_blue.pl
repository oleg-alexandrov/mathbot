#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use Encode;

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
require "../identify_red.pl";

undef $/;		      # undefines the separator. Can read one whole file in one scalar.

# use main to avoid the curse of global variables
MAIN: {

  my ($file_in, $file_out, $text, %red, %blue, $link, $target, $line, $text_out, $letter, %hash, @entries, $ltext);

  $file_in="Possible_redirects.txt";
  $file_out="User:Mathbot/Page10.wiki";
 
  &wikipedia_login();	
  open(FILE, "<$file_in"); $text = <FILE>; close(FILE);
  
  @entries = ($text =~ /(\[\[.*?\]\])/g);
  foreach (@entries){
    $hash{$_}=1;
  }

  $ltext="";
  foreach (sort {$a cmp $b} keys %hash){
    $ltext = $ltext . $_ . "\n";
  }
  &identify_red(\%red, \%blue, $ltext);

  $text_out="";
  foreach $line ( split ("\n", $text)){
    next unless ( $line =~ /\[\[(.*?)\]\].*?\[\[(.*?)\]\]/);
    $link = $1; $target = $2;
    if (exists $red{$link} && exists $blue{$target} ){
      $text_out = $text_out . $line . "\n";
    }
  }

  #  &fetch_file_nosave($from . ".wiki", 3, 1);
  open (FILE, ">", $file_out);  print FILE "$text_out\n"; close(FILE);
  &submit_file_nosave($file_out, "Possible redirects", $text_out, 5, 5);
}   


