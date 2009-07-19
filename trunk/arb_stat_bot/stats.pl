#!/usr/bin/perl
use strict;          # 'strict' insists that all variables be declared
use diagnostics;     # 'diagnostics' expands the cryptic warnings
use open 'utf8';

#use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
#require 'bin/perlwikipedia_utils.pl'; # needed to communicate with Wikipedia
undef $/; # undefines the separator. Can read one whole file in one scalar.

MAIN: {

  my ($sleep, $attempts, $text, $file, $local_file1, $local_file2);
  my ($edit_summary, $Editor);

  # Get the text from the server
  #$sleep = 5; $attempts = 500; # necessary to fetch/submit Wikipedia text
  #$Editor=wikipedia_login("Mathbot");
  #$file = "Wikipedia:Requests for arbitration/Statistics 2009";
  #$text=wikipedia_fetch($Editor, $file, $attempts, $sleep); 
  
  $local_file1 = "Statistics_2009.txt";
  #open(FILE, ">$local_file1"); print FILE $text; close(FILE);
  
  # Use local copy instead
  open(FILE, "<$local_file1"); $text = <FILE>; close(FILE);

  $text =~ s/\r//g; # Get rid of Windows carriage return

  my $years = ["2009 only", "2009 2008", "all"];
  my $types = ["case", "clarification"];

  my @tables; # parsed tables
  my $table;

  # For each year and each type of table we need to produce a summary
  # Also store the parsed tables, so that later we can use them
  # to form the arb activity tables.
  
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
      
      $disp_names  = ["Accepted", "Declined",
                      "Motion",   "Withdrawn"];
      $disp_legend = ["accepted", "declined",
                      "disposed by motion", "withdrawn"];
      
    }elsif ($type eq "clarification"){
      
      $disp_names  = ["Declined", "Clarification",
                      "Motion",   "Withdrawn"];
      $disp_legend = ["declined", "disposed by clarification",
                      "disposed by motion", "withdrawn"];
      
    }else{
      print "Unknown request type\n";
      exit(0);
    }
    
    # Parse the tables, complete the summary lines,
    # return the text with the updated summary lines,
    # and return as well the parsed table, we need it
    # to complete the arbitrator activity tables.
    ($text, $table) = 
       parse_complete_table_summaries($text,
                                      $beg_table_tags, $end_table_tags,    
                                      $beg_summary_tags, $end_summary_tags,
                                      $disp_names, $disp_legend,
                                     );

    push(@tables, $table);
  }

  # Now deal with the arb activity tables
  
  # For every year, return a hash containing the arbitrators for that year
  my $arbs_list  = [ get_arbs_list($text, $years) ];
  my $arbs_votes = ["A", "D", "R", "C", , "I", "N", ""];

  # Create the arb activity table and put it in the wiki text
  for (my $year_count = 0; $year_count < 2; $year_count++){

    my $output_table = "\n";
    
    # $year_count == 0 deals with arbs in current year, $year_count == 1
    # deals with arbs departing in current year.
    my $arbs = $arbs_list->[$year_count];

    foreach my $arb (sort { lc($arbs->{$a}) cmp lc($arbs->{$b}) } keys %$arbs){

      my $arb_full = $arbs->{$arb}; # expansion of the abbrev

      # There exist three types of data in the arb activity table
      my $row = "| align=\"left\" | $arb_full \|\| ";
      for (my $type = 0; $type < 3; $type++){
        
        if ($type == 0 || $type == 1){
          $table = $tables[$type];
        }else{
          $table = merge_tables($tables[0], $tables[1]); # grand summary  
        }
        $row .= count_format_arb_activity_data($arb, $arbs_votes,
                                               $table, $type);
      }

      $row =~ s/\|\|\s*$//g; # strip last separator
      $row .= "\n|-\n";     # prepare for new row

      $output_table .= $row;

    } # end dealing with current arbitrator

    $output_table =~ s/\|\-\s*$//g; # strip last "|-"
    
    # Update the appropriate table in the wiki text
    my $beg_tag = '<!-- begin requests activity table '
       . $years->[$year_count] . ' -->';

    my $end_tag = '<!-- end requests activity table '
       . $years->[$year_count] . ' -->';

    $text = put_text_between_tags($text, $output_table, $beg_tag, $end_tag);
    
  } # end going over the years

  $local_file2 = "Statistics_2009_proc.txt";
  open(FILE, ">$local_file2");
  print FILE $text . "\n";
  close(FILE);

  # Code to submit things back to Wikipedia
  # $edit_summary = "A test";
  # wikipedia_submit($Editor, $file, $edit_summary, $text, $attempts, $sleep);
}

sub parse_complete_table_summaries {
  
  my $text             = shift; # the big text containing all the tables 
  my $beg_table_tags   = shift; # marks where each table to parse starts
  my $end_table_tags   = shift; # marks where each table to parse ends
  my $beg_summary_tags = shift; # marks where the summary will start
  my $end_summary_tags = shift; # marks where the summary will end
  my $disp_names       = shift; # the types of values to summarize
  my $disp_legend      = shift; # the explanation of each value to summarize
  
  # There are three summaries to complete: 2009 only ($count == 0),
  # 2009 and 2008 ($count == 1), and the combined one ($count == 2).
  
  my ($table, @tables);
  
  for (my $count = 0; $count < 3; $count++){ 

    # Extract the table to summarize
    if ($count != 2){

      my $table_text = get_text_between_tags($text, $beg_table_tags->[$count],
                                             $end_table_tags->[$count]);
      $table = parse_wiki_table($table_text);
      push(@tables, $table); # we'll need it for $count == 2
      
    }else{
      # for $count == 2 we combine the two individual tables 0 and 1
      $table = merge_tables($tables[0], $tables[1]);
    }
    
    # Summarize the table
    my $summary    = compute_summary($table, $disp_names, $disp_legend);
    $summary = "\n" . $summary . "\n";

    if ($count == 2){
      # The combined summary is formatted a bit different than
      # the individual summmaries
      $summary =~ s/^\s*/\n\* /g;
      $summary =~ s/\s*$/\n/g;
    }

    # Insert the computed summary in the right place
    $text = put_text_between_tags($text, $summary, $beg_summary_tags->[$count],
                                  $end_summary_tags->[$count]);

  }

  return ($text, $table);
}

sub compute_summary {

  my $table       = shift;
  my $disp_names  = shift;
  my $disp_legend = shift;

  my $requests   = $table->{"Request"};
  my $num_req    = scalar ( @$requests );

  my $days       = $table->{"Days"};
  my $average    = find_array_average(@$days);
  $average       = round_ndigits($average, 1);

  # Count how things were disposed
  my $disp       = $table->{"Disp"};
  @$disp         = strip_links(@$disp);

  my %disp_count;
  my $total = count_values($disp, $disp_names,  # inputs
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
    my $pct = round_ndigits(100.0*$val/$total, 0);
    $summary .= $disp_legend->[$count] . ": " . $val . " (" . $pct . "%); ";
    
  }
  
  $summary =~ s/\;\s*$//g; # strip trailing ";"

  return $summary;
}

sub count_format_arb_activity_data {

  my $arb        = shift; # person whose votes to count
  my $arbs_votes = shift; # types of votes to count
  my $table      = shift; # table of votes to count
  my $data_type  = shift; # which data to count
  
  my %count;
  my $total = count_values($table->{$arb}, $arbs_votes,    # inputs
                           \%count                         # output
                          );

  my ($er, $i, $ip, $r, $rp, $v, $vp, $dn, $dnp, $a, $ap, $d, $dp, $c, $cp);
  
  $er = $total - $count{"N"};
  $i  = $count{"I"};             $ip   = percentage( $i,  $er       );
  $r  = $count{"R"};             $rp   = percentage( $r,  $er-$i    );
  $v  = $count{"A"}+$count{"D"}; $vp   = percentage( $v,  $er-$i-$r );
  $dn = $count{""};              $dnp  = percentage( $dn, $er-$i-$r );
  $a  = $count{"A"};             $ap   = percentage( $a,  $v        );
  $d  = $count{"D"};             $dp   = percentage( $d,  $v        );
  $c  = $count{"C"};             $cp   = percentage( $c,  $er-$i-$r );

  my $s = '';
  if ($data_type == 0){
    
    return "$er || $i || $ip || $r || $rp || $v || $vp || $dn || $dnp "
       . "|| $a || $ap || $d || $dp || ";
    
  }elsif ($data_type == 1){
    
    return "$er || $i || $ip || $r || $rp || $c || $cp || $dn || $dnp || ";

  }elsif ($data_type == 2){
    
    return "$er || $i || $ip || $r || $rp || $dn || $dnp || ";

  }else{
    
    print "Unsupported data type\n";
    exit(0);
    
  }
  
}

sub get_arbs_list {

  # Get arbitrators for every year involved
  
  my $text  = shift;
  my $years = shift;
  
  my $beg_tag = '<!-- begin list of arbitrators -->';
  my $end_tag = '<!-- end list of arbitrators -->';

  $text = get_text_between_tags($text, $beg_tag,  $end_tag);

  $text =~ s/\s*\<!\-\-+\s*//g;
  $text =~ s/\s*\-\-+\>\s*//g;

  my @chunks = split (/\n[ \t]*\n/, $text);

  my @arbs_in_year;

  foreach my $year (@$years){

    foreach my $chunk (@chunks){
      next unless ($chunk =~ /^\s*$year\s*(.*?)$/s);
      my $arbs = $1;

      push(@arbs_in_year, parse_legend($arbs));
    }
    
  }

  return @arbs_in_year;
}

sub parse_legend {

  my $text = shift;

  my $vals;
  foreach my $line (split("\n", $text)){

    $line =~ s/\s*$//g;
    $line =~ s/^\s*//g;

    next unless ($line =~ /^\s*(.*)\s+([^\s]*?)$/);

    my $long_name  = $1; 
    my $short_name = $2;

    $long_name =~ s/\s*$//g;
    
    $vals->{$short_name} = $long_name;
  }

  return $vals;
}

sub count_values{

  # Given an array $vals having as values elements in $names,
  # see how many times each element in $names occurs in $vals.
  # Also return the total number of elements in $vals that have values
  # from $names.
  
  my $vals  = shift; # input
  my $names = shift; # input
  
  my $count = shift; # output
  my $total = 0;     # output 
  %$count = ();
  
  foreach my $val (@$vals){

    if (exists $count->{$val}){
      $count->{$val}++;
    }else{

      $count->{$val} = 1;
    }

  }
  
  foreach my $name (@$names){

    if (!exists $count->{$name} ){
      $count->{$name} = 0;
    }

    $total += $count->{$name};     # output
  }

  return $total;
}

sub merge_tables {

  # Given two tables indexed by column, merge them into one table.
  # If the two tables have columns with the same index key,
  # merge those columns into one column in the combined table.
  
  my $merged_table;

  foreach my $table (@_){
    
    foreach my $key (keys %$table){
      
      my $ptr_in  = $table->{$key};
      
      my $ptr_out;
      if (exists $merged_table->{$key}){
        $ptr_out = $merged_table->{$key};
      }else{
        $ptr_out = []; 
      }
      
      push(@$ptr_out, @$ptr_in);
      $merged_table->{$key} = $ptr_out;
      
    }
  }
  
  return $merged_table;
}

sub parse_wiki_table {

  # Parse a wikipedia table. Return a hash of arrays cotaining the
  # table elements. More precisely, return a hash, with the keys of
  # the hash the elements in the topmost row of the table (each such
  # element serves as the name for the column under it). Each value in
  # the hash is an array containing the elements in the correspoinding
  # column in the table.
  
  # We assume that the topmost row has the format
  # ! x !! y !! z   

  # We assume other rows have the format
  # | align info | x || y || z
  
  my $text  = shift;

  # Strip non-cell information
  $text =~ s/^.*?\{\|\s*class\s*=.*?\n//igs;
  $text =~ s/(^|\n)\s*\|\+//ig;
  $text =~ s/\|\}.*?$//sg;

  my ($topmost_row, $other_rows);
  if ($text =~ /(^|\n)(\!.*?)\n(.*?)$/s){
    $topmost_row = $2; $other_rows = $3;
  }else{
    print "Could not match table row starting with \"\!\"\n";
    exit(0);
  }

  # Topmost row, its elements serve as key for the table columns
  my ($key, @keys);
  @keys = parse_topmost_table_row($topmost_row);

  # Initialize the table structure as a hash of empty arrays
  my $table;
  foreach $key (@keys){
    $table->{$key} = [];
  }
  
  # Other rows. Rows are separated by "|-".
  my $row;
  my @rows = split("\\|\\-", $other_rows);

  foreach $row (@rows){

    $row =~ s/\n//g; # strip newlines
    next unless ($row =~ /^\|/); # rows start with |

    my @row_elems = parse_other_table_rows($row);
    
    my $count = 0;
    foreach $key (@keys){

      my $ptr = $table->{$key};
      push( @$ptr, $row_elems[$count] );
      $count++;
      
    }
  }
  
  return $table;

}

sub parse_topmost_table_row{

  # Row starts with !. Cells are separated by !! or by ||
  my $row = shift;

  if ($row !~ /^\!/){
    print "Can't match table row\n";
    exit(0);
  }

  $row =~ s/^\!\s*//g; # strip first exclamation mark

  $row =~ s/\|\|/\!\!/g; # deal with alternative separator
  
  my @cells = split(/\!\!/, $row);
  foreach my $cell (@cells){
    $cell =~ s/^\s*//g;
    $cell =~ s/\s*$//g;
  }
  
  return @cells;
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

  my @cells = split(/\|\|/, $row);
  foreach my $cell (@cells){
    $cell =~ s/^\s*//g;
    $cell =~ s/\s*$//g;
  }
  
  return @cells;
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

sub percentage {

  my $val   = shift;
  my $outOf = shift;

  $outOf = 1 if ($outOf == 0);
  
  return (round_ndigits(100*$val/$outOf, 0)) . "%";
}

sub round_ndigits {

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

