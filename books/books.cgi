#!/usr/bin/perl

use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Unicode::Normalize;
use LWP::Simple;
use CGI::Carp qw(fatalsToBrowser);
use lib '/u/cedar/h1/afa/aoleg/public_html/wp/modules'; # path to perl modules

require Encode;
require 'cgi-lib.pl';
require 'bin/get_html.pl';
require 'bin/get_last.pl'; # guess the last name of a person

undef $/; # undefines the separator. Can read one whole file in one scalar.

my %input;

MAIN: {
  
  my ($isbn, $main_author, $title, $edition, $publisher, $isbn2, $url);

  $| = 1; # flush the buffer each line
  
  # Print the header
  print "Content-type: text/html\n\n";
  &print_head();

  # Read in all the variables set by the form
  &ReadParse(\%input);

  $isbn = $input{'isbn'};
  $isbn = shift @ARGV if (@ARGV); # for debugging
  $isbn =~ s/\s*//g; $isbn =~ s/[\:\-\_]//g; $isbn =~ s/isbn//ig;
  print "Input ISBN: <b>$isbn</b>\n<hr>\n";
  
  ($url, $main_author, $title, $edition, $publisher, $isbn2) = &parse_libcongress ($isbn);
  &process_bibliographic_data ($main_author, $title, $edition, $publisher, $isbn2);
  
  ($url, $main_author, $title, $edition, $publisher, $isbn2)=&parse_copac ($isbn);  
  &process_bibliographic_data ($main_author, $title, $edition, $publisher, $isbn2);

  print_foot();
}

sub process_bibliographic_data {

  my ($main_author, $title, $edition, $publisher, $isbn2) = @_;
  my ($main_author_fl, $coauthors, $year, $isbn, $all_authors, $editor);
  
  $main_author =~ s/\s*\(.*?$//g;

  if ($main_author =~ /^(.*?)\s*,\s*(.*?)\s*$/){
    $main_author_fl = "$2 $1";
  }else{
    $main_author_fl = $main_author;
  }

  if ($title =~ /^(.*?)\s*\/\s*(.*?)$/){
    $title = $1; $coauthors = $2;
    $coauthors = "" if ($main_author_fl eq $coauthors);
    $coauthors =~ s/^.*?,\s*//g if ($main_author); # strip first author
  }else{
   $coauthors = ""; 
  }

  # if one could not find the main author, then get one of the coauthors instead

  # the special case of an editor
  if (!$main_author || $main_author =~ /^\s*$/){
    if ($coauthors =~ /^([^\,]*?),\s*(book editor)/){

      $main_author = $1; $editor = $2; $coauthors = "";
      $main_author = &get_last ($main_author);
      $main_author = $main_author . ', ' . $editor;
      
    }elsif ($coauthors =~ /^(.*?),\s*(.*?)$/){
      $main_author = $1; $coauthors = $2;
    }else{
     $main_author = $coauthors; $coauthors ="";  
    }
  }

  $edition = $edition . '.' if ($edition =~ /\bed$/);
  if ($edition  && $edition !~ /^\s*$/){
    $title = $title . ', ' . $edition;
  }
  
  if ($publisher =~ /^(.*?),?\s*c?(\d\d\d\d)\s*$/){
    $publisher = $1;
    $year = $2;
  }else{
   $year = ""; 
  }

  $all_authors = &parse_authors ($main_author, $coauthors);

  &print_citation ($all_authors, $title, $publisher, $year, $isbn2);
}

sub parse_libcongress {
  my ($isbn, $isbn2, $text, $base, $url, $title, $main_author, $author, $authors, $edition, $publisher, $date, $error, $tag, $main_author_fl); 

  $isbn = shift;
  $url = 'http://catalog.loc.gov/cgi-bin/Pwebrecon.cgi?DB=local&CNT=25+records+per+page&CMD=isbn+' . $isbn;
  print "<a href=\"$url\">Library of Congress data</a>\n";

  ($text, $error) = &get_html ($url);

  $text = &strip_html_tags_and_format ($text);
  
  if ($text =~ /\nPersonal Name:\s*(.*?)\s*?\.?\s*?\n/){
    $main_author = $1;
  }else{
    $main_author ="";
  }
  
  if ($text =~ /\nMain Title:\s*(.*?)\s*?\.?\s*?\n/){
    $title = $1;
  }else{
    print "Error! Most likely the book is not available at the Library of Congress!\n";
    return;
  }

  if ($text =~ /\nEdition Information:\s*(.*?)\s*?\.?\s*?\n/){
    $edition = $1;
  }else{
    $edition = "";
  }
  
  if ($text =~ /\nPublished\/Created:\s*(.*?)\s*?-?\s*?\.?\s*?\n/){
    $publisher = $1;
  }else{
    print "Can't match publisher\n"; 
  }

  if ($text =~ /\nISBN:\s*(.*?\s*?\n(?:\s*\d\d.*?\n|))/){
    $isbn2 = $1;
    $isbn2 =~ s/\s*$//g;
    $isbn2 =~ s/\s+/ /g;
  }else{
   print "Can't match isbn\n"; 
  }

  return ($url, $main_author, $title, $edition, $publisher, $isbn2);
}

sub parse_copac{
  my ($isbn, $isbn2, $text, $base, $url, $title, $edition, $main_author, $author, $authors, $publisher, $date, $error, $tag, $main_author_fl); 

  $isbn  = shift;

  # must go through two urls to get the result
  $base='http://copac.ac.uk';
  $url = $base . '/wzgw?fs=Search&form=A%2FT&au=&cau=&ti=&pub=&isn=+' . $isbn . '&date=&lang=';
  ($text, $error) = &get_html ($url);

  if ($text =~ /\<a\s+href=\"([^\"]*?)\"\s+title=\"Link to full record\"/){
    $url =  $base . $1;
    $url =~ s/\&amp;/\&/g;
  }else{
    print "Error! Most likely the book is not available at <a href=\"$base\">Copac</a>!<br>\n";
    return;
  }

  print "<a href=\"$url\">COPAC data</a>\n";
  ($text, $error) = &get_html ($url);

  $text = &strip_html_tags_and_format($text);

  if ($text =~ /\nMain Author:\s*(.*?)\s*?\n/){
    $main_author = $1;
  }else{
    $main_author = "";
  }

  if ($text =~ /\nTitle Details:(.*?)\s*?\n/){
    $title = $1;
    if ($title =~ /^(.*?)\s*\/\s*(.*?)\s*;\s*(.*?)$/){
      $title = "$1: $3\/ $2"; #fix some weird formatting
    }
  }else{
    print "Can't match authors!<br>\n";
    return;
  }

  if ($text =~ /\nEdition:(.*?)\s*?\n/){
    $edition = $1;
  }else{
    $edition =""; 
  }
  
  if ($text =~ /\nPublisher:\s*(.*?)\s*?\n/){
    $publisher = $1; 
  }else{
    print "Can't match publisher!<br>\n";
    return;
  }

  if ($text =~ /\nISBN\/ISSN:\s*(.*?)\n/){
    $isbn2 = $1;
  }else{
    print "Can't match ISBN!<br>\n";
    return;
  }

  return ($url, $main_author, $title, $edition, $publisher, $isbn2);
}

sub parse_authors {
  my ($first_author, $last_name, $first_name, $coauthors);

  $first_author = shift; $coauthors = shift;
  
  $coauthors =~ s/\s+/ /g;
  $first_author = &get_last ($first_author) unless ($first_author =~ /,/);
  
  if ($first_author =~ /^(.*?),\s*(.*?)$/){
    $last_name = $1; $first_name=$2;
    $first_author = ' | last       = ' . $last_name . "\n" . ' | first      = ' . $first_name;
  }else{
    $first_author = ' | author     = ' .  $first_author;
  }

  if ($coauthors){
    $coauthors = "\n" . ' | coauthors  = ' . $coauthors;
  }else{
    $coauthors = ""; 
  }

  return $first_author . $coauthors;
}

sub print_citation {
  my ($authors, $title, $publisher, $date, $isbn) = @_;
  print '<pre>
*{{cite book
' . $authors    . '
 | title      = ' . $title     . '
 | publisher  = ' . $publisher . '
 | date       = ' . $date      . '
 | pages      = '              . '
 | isbn       = ' . $isbn .      '
}}
</pre>
<hr>';
}

sub strip_html_tags_and_format {
  my $text = shift; 

  $text =~ s/\&nbsp;/ /g;
  $text =~ s/[\t ]+/ /g;

  $text =~ s/\n//g;

  $text =~ s/\<tr.*?\>/\n/ig;
  $text =~ s/\<.*?\>//g;

  $text =~ s/\s*(;|:)/$1/g;

  return $text;
}

sub print_head {
    print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" dir="ltr" lang="en"><head>
<!-- <meta http-equiv="Content-Type" content="text/html; charset=utf-8"> -->
    
<body>

';
}

sub print_foot {

  print 
'<ul>
<li>Please <font color=red><font size=+2>check</font></font> if this output is accurate,
for example by following the links above.</li>
<li>Please make adjustments if necessary to make sure the data is <b>well-formatted</b>.
</ul>

<hr>
<a href="http://en.wikipedia.org/wiki/User_talk:Oleg_Alexandrov">Feedback?</a>

</body></html>
';
}


