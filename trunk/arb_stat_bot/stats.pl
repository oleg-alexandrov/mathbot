#!/usr/bin/perl
use strict;          # 'strict' insists that all variables be declared
use diagnostics;     # 'diagnostics' expands the cryptic warnings
use open 'utf8';

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/perlwikipedia_utils.pl'; # needed to communicate with Wikipedia
undef $/; # undefines the separator. Can read one whole file in one scalar.

MAIN: {

  my ($sleep, $attempts, $text, $file, $local_file1, $local_file2);
  my ($edit_summary, $Editor);

#   # Get the text from the server
#   $sleep = 5; $attempts = 500; # necessary to fetch/submit Wikipedia text
#   $Editor=wikipedia_login("mathbot");
#   $file = "Wikipedia:Requests for arbitration/Statistics 2009";
#   $text=wikipedia_fetch($Editor, $file, $attempts, $sleep); 

  $local_file1 = "Statistics_2009.txt";
#   open(FILE, ">$local_file1"); print FILE $text; close(FILE);
  
  # Use local copy instead
  open(FILE, "<$local_file1"); $text = <FILE>; close(FILE);

  $text =~ s/\r//g; # Get rid of Windows carriage return

  my $years = ["2009 only", "2009 2008", "all"];
  my $types = ["case", "clarification"];
  
  # For each year and each type of table we need to produce a summary

  foreach my $type (@$types){

    my ($beg_table_tags,   $end_table_tags);   # where to read data from 
    my ($beg_summary_tags, $end_summary_tags); # where to write data to

    # Find the tags which mark which table to summarize
    foreach my $year (@$years){
      push (@$beg_table_tags,   "<!-- begin $type requests table $year -->");
      push (@$end_table_tags,   "<!-- end $type requests table $year -->");
      
      push (@$beg_summary_tags, "<!-- begin $type requests summary $year -->");
      push (@$end_summary_tags, "<!-- end $type requests summary $year -->");
    }

    # Things to summarize and their explanation
    my ($disp_names, $disp_legend);
    
    if ($type eq "case"){
      
      $disp_names  = ["accepted", "declined",
                      "motion",   "withdrawn"];
      $disp_legend = ["accepted", "declined",
                      "disposed by motion", "withdrawn"];
      
    }elsif ($type eq "clarification"){
      
      $disp_names  = ["declined", "clarification",
                      "motion",   "withdrawn"];
      $disp_legend = ["declined", "disposed by clarification",
                      "disposed by motion", "withdrawn"];
      
    }else{
      print "Unknown request type\n";
      exit(0);
    }
    
    # text to read data from and write summary to
    $text = 
       complete_table_summaries($text,
                                $beg_table_tags, $end_table_tags,    
                                $beg_summary_tags, $end_summary_tags,
                                $disp_names, $disp_legend    
                               );
    
  }
  
  $local_file2 = "Statistics_2009_proc.txt";
  open(FILE, ">$local_file2");
  print FILE $text . "\n";
  close(FILE);

  # Code to submit things back to Wikipedia
  # $edit_summary = "A test";
  # wikipedia_submit($Editor, $file, $edit_summary, $text, $attempts, $sleep);
}

sub complete_table_summaries {
  
  my $text             = shift; # the big text containing all the tables 
  my $beg_table_tags   = shift; # marks where each table to parse starts
  my $end_table_tags   = shift; # marks where each table to parse ends
  my $beg_summary_tags = shift; # marks where the summary will start
  my $end_summary_tags = shift; # marks where the summary will end
  my $disp_names       = shift; # the types of values to summarize
  my $disp_legend      = shift; # the explanation of each value to summarize

  my $table_text;   # an individual table from the big text

  # There are three summaries to complete: 2009 only ($count == 0),
  # 2009 and 2008 ($count == 1), and the combined one.
  
  for (my $count = 0; $count < 3; $count++){ 

    # Extract the table to summarize
    if ($count != 2){
      $table_text = get_text_between_tags($text, $beg_table_tags->[$count],
                                          $end_table_tags->[$count]);
    }else{
      # for $count == 2 we combine the two individual tables 0 and 1
      $table_text = get_text_between_tags($text, $beg_table_tags->[0],
                                          $end_table_tags->[0])
                  . "\n"
                  . get_text_between_tags($text, $beg_table_tags->[1],
                                             $end_table_tags->[1]);
    }
    my $table      = parse_wiki_table($table_text);

    # Summarize the table
    my $summary    = compute_summary($table, $disp_names, $disp_legend);
    $summary = "\n" . $summary . "\n";

    if ($count == 2){
      # The combined summary is formatted a bit different than
      # the individual summmaries
      $summary =~ s/^\s*/\n\* /g;
      $summary =~ s/\s*$/\.\n/g;
    }

    # Insert the computed summary in the right place
    $text = put_text_between_tags($text, $summary, $beg_summary_tags->[$count],
                                  $end_summary_tags->[$count]);
  }

  return $text;
  
}

sub compute_summary {

  my $table       = shift;
  my $disp_names  = shift;
  my $disp_legend = shift;

  my @requests   = find_column_by_name($table, "Request");
  my $num_req    = scalar ( @requests );

  my @days       = find_column_by_name($table, "Days");
  my $average    = find_array_average(@days);
  $average       = round_to_n_digits($average, 1);

  # Count how things were disposed
  my @disp       = find_column_by_name($table, "Disp");
  @disp          = strip_links(@disp);

  my %disp_count;
  my $total = count_values(\@disp, $disp_names,  # inputs
                           \%disp_count          # output
                          );
  if ($total != $num_req){
    print "Size mis-match\n";
    exit(0);
  }

  my $summary = form_summary($num_req, $average, $total,
                             $disp_names, $disp_legend, \%disp_count);

  return $summary;
}

sub form_summary {

  my $num_req     = shift;
  my $average     = shift;
  my $total       = shift;
  my $disp_names  = shift;
  my $disp_legend = shift;
  my $disp_count  = shift;
  
  my $summary = "Requests: $num_req; average duration: $average days; ";
  for (my $count = 0; $count < scalar(@$disp_names); $count++){

    my $val = $disp_count->{$disp_names->[$count]};
    my $pct = round_to_n_digits(100.0*$val/$total, 0);
    $summary .= $disp_legend->[$count] . ": " . $val . " (" . $pct . "%); ";
    
  }
  
  $summary =~ s/\;\s*$//g;

  return $summary;
}

sub count_values{

  # Given an array $vals having as values elements in $names,
  # see how many times each element in $names occurs in $vals.
  
  my $vals  = shift; # input
  my $names = shift; # input
  
  my $count = shift; # output
  my $total = 0;     # output 
  %$count = ();
  
  foreach my $val (@$vals){

    my $val_lc = lc($val); # lowercase
    if (exists $count->{$val_lc}){
      $count->{$val_lc}++;
    }else{

      $count->{$val_lc} = 1;
    }

  }
  
  foreach my $name (@$names){

    my $name_lc = lc($name);
    if (!exists $count->{$name_lc} ){
      $count->{$name_lc} = 0;
    }

    $total += $count->{$name_lc};     # output
  }

  return $total;
}

sub parse_wiki_table {

  # Parse a wikipedia table, store the result in a 2D array,
  # with $table->{$i}->{$j} storing table element (i, j).
  # Indices start from 0. 

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

  # Rows are separated by ||. First row may have alignment info
  # which we will strip. 
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

sub put_text_between_tags {

  my $text    = shift;
  my $to_put  = shift;
  my $beg_tag = shift;
  my $end_tag = shift;

  if ($text =~ /^(.*?\Q$beg_tag\E).*?(\Q$end_tag\E.*?)$/s){
    return $text = $1 . $to_put . $2;
  }else{
    print "Could not match text between $beg_tag and $end_tag\n";
  }

  return $text;
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

