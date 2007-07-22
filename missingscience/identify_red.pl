#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
use WWW::Mediawiki::fetch_submit; # my own packages, this and the one below
use WWW::Mediawiki::fetch_submit_nosave; # my own packages, this and the one below
use WWW::Mediawiki::wikipedia_login;
use Encode;
undef $/;		      # undefines the separator. Can read one whole file in one scalar.

sub identify_red {

  my ($text, $red, $blue, $wget, $log, $link, @lines, @reds, %hash, @all);

  $red=shift; $blue = shift; $text = shift;
  $text =~ s/(\[\[.)/uc($1)/eg;
  @all = ($text =~ /\[\[(.*?)\]\]/g);
  
  $wget="wget -q -O - ";
  $log = 'User:Mathbot/Page12.wiki';
  $link='http://en.wikipedia.org/wiki/' . $log; $link =~ s/\.wiki$//g;

  # submit wikicode and get back html source with red and blue links
  &submit_file_nosave($log, "Add links.", $text, 10, 5); 
  $text = `$wget \"$link\"`;
  `sleep 10`;  $text = $text . "\n" . `$wget \"$link\"`; # one more time, to make sure we don't fail
  `sleep 10`;  $text = $text . "\n" . `$wget \"$link\"`; # one more time, to make sure we don't fail
  
  $text =~ s/\s+/ /g;
  @reds = ($text =~ /class\s*=\s*\"new\"\s+title\s*=\s*\"(.*?)\"\s*\>.*?\</ig);

  foreach (@reds) {
    s/\&amp;/\&/g;
    $_=decode("iso-8859-1", $_); 
    s/^(.)/uc($1)/eg; #upper case
    $red->{$_}=1;
  }

  foreach (@all){
    if (! exists $red->{$_}){
      $blue->{$_}=1;
    }
  }
}

1;

