#!/usr/bin/perl
use strict;          # 'strict' insists that all variables be declared
use diagnostics;     # 'diagnostics' expands the cryptic warnings
use open 'utf8';

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/perlwikipedia_utils.pl'; # Needed to get things to and from Wikipedia.
undef $/; # undefines the separator. Can read one whole file in one scalar.

MAIN: {

  my ($sleep, $attempts, $text, $file, $edit_summary, $Editor);

  # Get the text from the server
  #$sleep = 5; $attempts=500; # necessary to fetch data from Wikipedia and submit
  #$Editor=wikipedia_login("Arb stat bot");
  #$file = "Wikipedia:Requests for arbitration/Statistics 2009";
  #$text=wikipedia_fetch($Editor, $file, $attempts, $sleep);  # fetch from Wikipedia

  # Use local copy instead
  $file = "Statistics_2009.txt";
  open(FILE, "<$file"); $text = <FILE>; close(FILE);

  my $beg_tag = "<!-- begin case requests table 2009 only -->";
  my $end_tag = "<!-- end case requests table 2009 only -->";

  $text =~ s/\r//g; # Get rid of Windows carriage return

  my $table_text = get_text_between_tags($text, $beg_tag, $end_tag);
  
  my $table      = parse_wiki_table($table_text);

  my @requests   = find_column_by_name($table, "Request");
  my $num_req    = scalar ( @requests );

  my @days       = find_column_by_name($table, "Days");
  my $average    = find_array_average(@days);
  $average       = round_to_n_digits($average, 1);

  # Count how things were disposed
  my @disp       = find_column_by_name($table, "Disp");
  @disp          = strip_links(@disp);
  my %disp_stats = ("accepted" => 0, "declined" => 0, "motion" => 0, "withdrawn" => 0);
  #%disp_stats = count_values(\@disp, \%disp_stats); # function to be written
  
  print "Number of requests is $num_req\n";
  print "Average is $average\n";
  

  # Code to submit things back to Wikipedia
  # $edit_summary = "A test";
  # wikipedia_submit($Editor, $file, $edit_summary, $text, $attempts, $sleep);
}

sub get_text_between_tags {

  my $text    = shift;
  my $beg_tag = shift;
  my $end_tag = shift;

  if ($text =~ /\Q$beg_tag\E(.*?)\Q$end_tag\E/s){
    return $1;
  }else{
    print "Could not match text between $beg_tag and $end_tag\n";
    return "";
  }
    
}

sub parse_wiki_table {

  # Parse a wikipedia table, store the result in a 2D array, with $table->{$i}->{$j}
  # storing table element (i, j). Indices start from 0. 

  # We assume that the topmost row has the format
  # ! x !! y !! z   

  # We assume other rows have the format
  # | align info | x || y || z
  
  my $text  = shift;

  # Strip non-cell information
  $text =~ s/^.*?\{\|\s*class\s*=.*?\n//igs;
  $text =~ s/(^|\n)\s*\|\+//ig;
  $text =~ s/\|\}.*?$//sg;

  my ($zeroth_row, $other_rows);
  if ($text =~ /(^|\n)(\!.*?)\n(.*?)$/s){
    $zeroth_row = $2; $other_rows = $3;
  }else{
    print "Could not match table row starting with \"\!\"\n";
    exit(0);
  }

  # Zero-th row
  my ($cell, @cells);
  @cells = parse_zeroth_table_row($zeroth_row);

  # Put zero-th row in the table
  my $table = [
               [ @cells ]
              ];

  # Other rows. Rows are separated by "|-".
  my $row;
  my @rows = split("\\|\\-", $other_rows);
  
  foreach $row (@rows){

    $row =~ s/\n//g; # strip newlines
    next unless ($row =~ /^\|/); # rows start with |

    push (@$table, [ parse_other_table_rows($row)] );
  }
  
  return $table;

}

sub parse_zeroth_table_row{

  # Row starts with !. Cells are separated by !!
  my $row = shift;

  if ($row !~ /^\!/){
    print "Can't match table row\n";
    exit(0);
  }

  $row =~ s/^\!\s*//g; # strip first exclamation mark

  return split(/\s*\!\!\s*/, $row);

}

   
sub parse_other_table_rows{

  # Rows are separated by ||. First row may have alignment info which we will strip. 
  my $row = shift;

  if ($row !~ /^\|/){
    print "Can't match table row\n";
    exit(0);
  }

  $row =~ s/^\|.*?\|\s*//g; # strip alignment info

  return split(/\s*\|\|\s*/, $row);
  
}

sub find_column_by_name{

  # Return the column in the table with given name. Skip the top-most
  # cell in the column, that cell's purpose is to name the column.
  
  my $table = shift;
  my $name  = shift;

  my @output_column = ();
  
  if (scalar(@$table) <= 0){
    return @output_column; # empty column
  }

  my $top_row = $table->[0];

  my $cell;
  my $col_count = 0;
  my $success   = 0;
  foreach $cell ( @$top_row ){

    if ($cell eq $name){
      $success = 1;
      last; # found what we needed
    }

    $col_count++;
    
  }

  if (! $success){
    return @output_column; # Failed to find the requested column
  }

  my $row;
  my $row_count = 0;
  foreach $row (@$table){

    if ($row_count != 0){
      # Skip the top-most cell having the name of the column
      push(@output_column, $row->[$col_count]);
    }
    
    $row_count++;
  }
  
  return @output_column;
}

sub find_array_average{

  my $sum   = 0;
  my $count = 0;
  my $val;

  foreach $val (@_){
    $sum = $sum + $val;
    $count++;
  }

  if ($count == 0){
    print "Cannot find the average of an empty array\n";
    return 0.0;
  }

  return $sum/$count;
}

sub round_to_n_digits {

  my $val = shift;
  my $n   = shift;

  my $power = 1;
  my $i;
  for ($i = 0 ; $i < $n ; $i++){
    $power *= 10;
  }

  $val = int($val*$power + 0.5)/$power;

  return $val;
}

sub strip_links {

  # Replace [[A|B]] with plain B
  my $cell;

  foreach $cell (@_){
    $cell =~ s/^.*?\[\[.*?\|(.*?)\]\].*?$/$1/g;
  }

  return @_;
}
   
