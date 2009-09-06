#!/usr/bin/perl
use strict;          # 'strict' insists that all variables be declared
use diagnostics;     # 'diagnostics' expands the cryptic warnings
use open 'utf8';
undef $/; # undefines the separator. Can read one whole file in one scalar.

use lib $ENV{HOME} . '/public_html/cgi-bin/wp/modules'; 
use lib '/home/mathbot/public_html/cgi-bin/wp/modules'; 
use lib '../wp/modules'; 
require 'bin/perlwikipedia_utils.pl'; # needed to communicate with Wikipedia

my $uniqueTag = "_2nd"; # Make a row with "Z", "Z", into "Z", "Z_2nd", for unqueness.

MAIN: {

  my ($sleep, $attempts, $text, $file, $local_file_in, $local_file_out);
  my ($edit_summary, $Editor, $use_local);

  print "Content-type: text/html\n\n"; # first line to print in a cgi script
  $| = 1; # flush the buffer each line

  # If this function called with no arguments, read from and submit to
  # Wikipedia. Else, read from/write to write on disk. The second
  # option is useful for debugging purposes.
  $use_local = scalar(@ARGV); 
  $local_file_in = "Statistics_2009.txt";

  if (!$use_local){
    
    # Get the text from the Wikipedia server
    $sleep  = 5; $attempts = 500; # necessary to fetch/submit Wikipedia text
    $Editor = wikipedia_login("Mathbot");
    $file   = "Wikipedia:Requests for arbitration/Statistics 2009";
    $text   = wikipedia_fetch($Editor, $file, $attempts, $sleep); 
    open(FILE, ">$local_file_in"); print FILE $text; close(FILE);

  }else{
    open(FILE, "<$local_file_in"); $text = <FILE>; close(FILE); # local copy
  }
  
  $text = gen_all_stats($text);

  if (!$use_local){
    
    $edit_summary = "Bot update";
    wikipedia_submit($Editor, $file, $edit_summary, $text, $attempts, $sleep);
    
  }else{
    
    $local_file_out = "Statistics_2009_proc.txt";
    open(FILE, ">$local_file_out"); print FILE $text . "\n"; close(FILE);

  }
  
}

sub gen_all_stats{

  my $text = shift;
  
  $text =~ s/\r//g; # Get rid of Windows carriage return

  my $years      = ["2009 only", "2009 2008", "all"];
  my $arbs_list  = [ get_arbs_list($text, $years) ];

  # Section 1: the requests stats
  $text = gen_requests_stats($text, $years, $arbs_list);

  # Section 2: the motions stats
  $text = gen_motions_stats($text, $years, $arbs_list);

  my ($arbs_votes, $type);
  
  # Section 3: the cases stats
  $arbs_votes = ["R", "I", "N", ""];   # How arbitrators can vote
  $text = gen_cases_stats($text, $years, $arbs_list, $arbs_votes);

  # Section 4: the proposals stats
  $arbs_votes = ["A", "R", "I", "N", "O", "S", "S1", ""]; # How arbitrators can vote
  $text = gen_proposals_stats($text, $years, $arbs_list, $arbs_votes);

  return $text;
}

sub gen_requests_stats{

  my $text      = shift; # text to parse and put the stats into
  my $years     = shift; # years to parse
  my $arbs_list = shift; # list of arbitrators
  
  # types of requests
  my $types = ["case", "clarification"];

  # how the arbs can vote for these requests
  my $arbs_votes = ["A", "D", "R", "C", "I", "N", ""];

  my @tables; # parsed tables
  my $table;  # one of the tables

  # For each year and each type of table we need to produce a summary
  # Also store the parsed tables, so that later we can use them
  # to form the arb stats tables.
  
  foreach my $type (@$types){

    my ($beg_table_tags,   $end_table_tags);   # where to read data from 
    my ($beg_summary_tags, $end_summary_tags); # where to write data to

    # Find the tags which mark which table to summarize
    foreach my $year (@$years){
      push(@$beg_table_tags,   "<!-- begin $type requests table $year -->");
      push(@$end_table_tags,   "<!-- end $type requests table $year -->");
      
      push(@$beg_summary_tags, "<!-- begin $type requests summary $year -->");
      push(@$end_summary_tags, "<!-- end $type requests summary $year -->");
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
    # to complete the arbitrator stats tables.
    ($text, $table) = 
       parse_complete_requests_table_summaries
          ($text,
           $beg_table_tags, $end_table_tags,    
           $beg_summary_tags, $end_summary_tags,
           $disp_names, $disp_legend,
          );

    push(@tables, $table);
  }

  # Now deal with the arb stats tables
  
  # For every year, return a hash containing the arbitrators for that year

  # Create the arb stats table and put it in the wiki text
  for (my $year_count = 0; $year_count < 2; $year_count++){

    # $year_count == 0 deals with arbs in current year, $year_count == 1
    # deals with arbs departing in current year.
    my $arbs = $arbs_list->[$year_count];

    my $output_table = "\n";
    
    foreach my $arb (sort { lc($arbs->{$a}) cmp lc($arbs->{$b}) }
                     keys %$arbs){

      my $arb_full = $arbs->{$arb}; # expansion of the abbrev

      # There exist three types of data in the arb stats table
      my $row = "| align=\"left\" | $arb_full \|\| ";
      for (my $type = 0; $type < 3; $type++){
        
        if ($type == 0 || $type == 1){
          $table = $tables[$type];
        }else{
          $table = merge_tables($tables[0], $tables[1]); # grand summary  
        }
        $row .= compute_requests_stats($arb, $arbs_votes, $table, $type);
      }

      $row =~ s/\s*\|\|\s*$//g; # strip last separator
      $row .= "\n|-\n";     # prepare for new row

      $output_table .= $row;

    } # end dealing with current arbitrator

    $output_table =~ s/\|\-\s*$//g; # strip last "|-"
    
    # Update the appropriate table in the wiki text
    my $beg_tag = '<!-- begin requests stats '
       . $years->[$year_count] . ' -->';

    my $end_tag = '<!-- end requests stats '
       . $years->[$year_count] . ' -->';

    $text = put_text_between_tags($text, $output_table, $beg_tag, $end_tag);
    
  } # end going over the years

  return $text;
}

sub gen_motions_stats{

  my $text      = shift; # text to parse and put the stats into
  my $years     = shift; # years to parse
  my $arbs_list = shift; # list of arbitrators

  my $year_count = 0; # look only at the most recent year
  my $year       = $years->[0]; 
  my $arbs       = $arbs_list->[$year_count];
  
  # How the arbs can vote here
  my $arbs_votes = ["S", "O", "A", "R", "I", "N", ""];

  # Get the data from between these tags
  my $beg_table_tag = "<!-- begin motions table $year -->";
  my $end_table_tag = "<!-- end motions table $year -->";

  my $table_text = get_text_between_tags($text, $beg_table_tag,
                                         $end_table_tag);

  # This table has a funny entry of "Failed*" where it should be "Failed".
  # That confuses the bot.
  $table_text =~ s/Failed\*/Failed/g;
  
  my $table = parse_wiki_table($table_text);

  my $offeredCol = $table->{"Offered"};
  my $Offered; # how many times an arbitrator shows up in the "offered" column
  foreach my $arb (@$offeredCol){
    $Offered->{$arb}++;
  }
  
  my $output_table = "\n";
  
  foreach my $arb (sort { lc($arbs->{$a}) cmp lc($arbs->{$b}) } keys %$arbs){
    
    my $arb_full = $arbs->{$arb}; # expansion of the abbrev

    my $row  = "| align=\"left\" | $arb_full \|\| ";
    $row    .= compute_motions_stats($arb, $arbs_votes, $table, $Offered);
    $output_table .= $row;
  }
  
  $output_table =~ s/\|\-\s*$//g; # strip last "|-"

  # put the data between these tags
  my $beg_stats_tag = "<!-- begin motions stats $year -->";
  my $end_stats_tag = "<!-- end motions stats $year -->";
  
  $text = put_text_between_tags($text, $output_table,
                                $beg_stats_tag, $end_stats_tag);

  # Compute the summary as well
  $text = compute_motions_summary($table, $text);
  
  return $text;
}

sub gen_cases_stats{

  my $text       = shift; # text to parse and put the stats into
  my $years      = shift; # years to parse
  my $arbs_list  = shift; # list of arbitrators
  my $arbs_votes = shift;

  my $type       = "cases";
  
  my $table   = {};
  my $Drafted = {}; # how many times an arbitrator drafted a case

  # Iterate over the years and combine the tables for those years
  for (my $year_count = 0; $year_count < 2; $year_count++){

    my $year          = $years->[$year_count];
    my $beg_table_tag = "<!-- begin $type table $year -->";
    my $end_table_tag = "<!-- end $type table $year -->";

    my $table_text = get_text_between_tags($text, $beg_table_tag,
                                           $end_table_tag);

    $table = merge_tables( $table,                       # tables so far
                           parse_wiki_table($table_text) # current table
                         );
  }

  my $draftedCol = $table->{"Drafter"};
  foreach my $arb (@$draftedCol){
    $Drafted->{$arb}++;
  }
  
  for (my $year_count = 0; $year_count < 2; $year_count++){

    my $year = $years->[$year_count];
    my $arbs = $arbs_list->[$year_count];

    my $output_table = "\n";
  
    foreach my $arb (sort { lc($arbs->{$a}) cmp lc($arbs->{$b}) }
                     keys %$arbs){
      
      my $arb_full = $arbs->{$arb}; # expansion of the abbrev

      my $row = "| align=\"left\" | $arb_full \|\| ";
      $row   .= compute_cases_stats($arb, $arbs_votes, $table, $Drafted);
      $output_table .= $row;
      
    } # End iterating over arbitrators

    $output_table =~ s/\|\-\s*$//g; # strip last "|-"
    
    my $beg_stats_tag = "<!-- begin $type stats $year -->";
    my $end_stats_tag = "<!-- end $type stats $year -->";
  
    $text = put_text_between_tags($text, $output_table,
                                  $beg_stats_tag, $end_stats_tag);
  
  } # End iterating over years

  # Compute the summary as well
  $text = compute_cases_summary($table, $text);
  
  return $text;
}

sub gen_proposals_stats{

  my $text       = shift; # text to parse and put the stats into
  my $years      = shift; # years to parse
  my $arbs_list  = shift; # list of arbitrators
  my $arbs_votes = shift;

  my $type       = "proposals";
  
  my $table   = {};

  # Iterate over the years and combine the tables for those years
  for (my $year_count = 0; $year_count < 2; $year_count++){

    my $year          = $years->[$year_count];
    my $beg_table_tag = "<!-- begin $type table $year -->";
    my $end_table_tag = "<!-- end $type table $year -->";

    my $table_text = get_text_between_tags($text, $beg_table_tag,
                                           $end_table_tag);

    # Fix odd stuff in this table before proceeding
    $table_text =~
       s/(\!\s*colspan\s*=\s*2.*?)(\n)/proc_proposals_description($1) . $2/eg;

    $table = merge_tables( $table,                       # tables so far
                           parse_wiki_table($table_text) # current table
                         );
  }

  for (my $year_count = 0; $year_count < 2; $year_count++){

    my $year = $years->[$year_count];
    my $arbs = $arbs_list->[$year_count];

    my $output_table = "\n";
  
    foreach my $arb (sort { lc($arbs->{$a}) cmp lc($arbs->{$b}) }
                     keys %$arbs){
      
      my $arb_full = $arbs->{$arb}; # expansion of the abbrev

      my $row = "| align=\"left\" | $arb_full \|\| ";
      $row   .= compute_proposals_stats($arb, $arbs_votes, $table);
      $output_table .= $row;
      
    } # End iterating over arbitrators

    $output_table =~ s/\|\-\s*$//g; # strip last "|-"
    
    my $beg_stats_tag = "<!-- begin $type stats $year -->";
    my $end_stats_tag = "<!-- end $type stats $year -->";
  
    $text = put_text_between_tags($text, $output_table,
                                  $beg_stats_tag, $end_stats_tag);
  
  } # End iterating over years

  # Compute the summary as well
  #$text = compute_proposals_summary($table, $text);
  
  return $text;
}

sub proc_proposals_description {

  # This table has artifacts which choke the code. Deal with them.

  my $text = shift;

  # colspan artifact, break a cell with colspan into two sells
  $text =~ s/\!\s*colspan\s*=\s*2\s*\|\s*/\! alignInfoDummy \| DummyCell \|\| /g;

  # The tag shows twice in a column. This makes it impossible to
  # identify the column by the tag. To fix that, append a suffix to
  # the second occurence of a tag, to make each tag unque. Later, wen
  # doing statistics, we'll need the information in the second
  # occurence of the tag.
  while ($text =~ s/\b(\w+)\b(.*?)\b(\1)\b/$1 . $2 . $3 . $uniqueTag/eg) {}
  
  return $text;
}

sub parse_complete_requests_table_summaries {
  
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
    my $summary = compute_requests_summary($table, $disp_names, $disp_legend);
    $summary    = "\n" . $summary . "\n";

    if ($count == 2){
      # The combined summary is formatted a bit different than
      # the individual summmaries
      $summary =~ s/^\s*/\n\* /g;
      $summary =~ s/\s*\.*\s*$//g;
      $summary .= ".\n";
    }

    # Insert the computed summary in the right place
    $text = put_text_between_tags($text, $summary,
                                  $beg_summary_tags->[$count],
                                  $end_summary_tags->[$count]);
  }

  return ($text, $table);
}

sub compute_requests_summary {

  my $table       = shift;
  my $disp_names  = shift;
  my $disp_legend = shift;

  my $requests   = $table->{"Request"};
  my $num_req    = scalar ( @$requests );

  my $days       = $table->{"Days"};
  my $average    = find_average(@$days);
  $average       = round_ndigits($average, 1);

  # Count how things were disposed
  my $disp       = $table->{"Disp"};
  @$disp         = strip_links(@$disp);

  my %disp_count;
  my $total = count_values($disp, $disp_names,  # inputs
                           \%disp_count          # output
                          );
 
  my $summary = form_requests_summary($total, $average, $total,
                                      $disp_names, $disp_legend, \%disp_count);

  return $summary;
}

sub form_requests_summary {

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

sub compute_requests_stats {

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

sub compute_motions_stats {
  
  my $arb        = shift; # person whose votes to count
  my $arbs_votes = shift; # types of votes to count
  my $table      = shift; # table of votes to count
  my $Offered    = shift; # how many times an arb offered a motion
  
  my %count;
  my $total =
     count_values($table->{$arb},
                  $arbs_votes,    # inputs
                  \%count                         # output
                 );
  
  my ($em, $i, $ip, $r, $rp, $v, $vp, $dn, $dnp, $a, $ap, $s, $sp,
      $o, $op, $offered, $offeredp);
  
  $em = $total - $count{"N"};
  $i  = $count{"I"};             $ip   = percentage( $i,  $em       );
  $r  = $count{"R"};             $rp   = percentage( $r,  $em-$i    );
  $v  = $count{"S"}+$count{"O"}; $vp   = percentage( $v,  $em-$i-$r );
  $a  = $count{"A"};             $ap   = percentage( $a,  $em-$i-$r );
  $dn = $count{""};              $dnp  = percentage( $dn, $em-$i-$r );
  $s  = $count{"S"};             $sp   = percentage( $s,  $v        );
  $o  = $count{"O"};             $op   = percentage( $o,  $v        );
  
  if (exists $Offered->{$arb}){
    $offered  = $Offered->{$arb};
  }else{
    $offered  = 0; 
  }
  $offeredp = percentage( $offered,  $total );
  
  my $row = "$em $i $ip $r $rp $v $vp $a $ap $dn $dnp $s $sp $o $op ";
  $row .=   "$offered $offeredp\n";
  $row  =~   s/ / \|\| /g;
  $row .= "|-\n";     # prepare for new row

  return $row;
}

sub compute_cases_stats {
  
  my $arb        = shift; # person whose votes to count
  my $arbs_votes = shift; # types of votes to count
  my $table      = shift; # table of votes to count
  my $Drafted    = shift; # how many times an arb offered a motion
  my $type       = shift;
  
  my %count;
  my $total = count_values($table->{$arb}, $arbs_votes,  # inputs
                           \%count                       # output
                          );
  
  my ($e, $i, $ip, $r, $rp, $v, $vp, $dn, $dnp, $a, $ap, $s, $sp,
      $o, $op, $drafted, $draftedp);
  
  my $row = "";

  $e = $total - $count{"N"};
  $i  = $count{"I"};             $ip   = percentage( $i,  $e       );
  $r  = $count{"R"};             $rp   = percentage( $r,  $e-$i    );
  
  if (exists $Drafted->{$arb}){
    $drafted  = $Drafted->{$arb};
  }else{
    $drafted   = 0; 
  }
  $draftedp = percentage( $drafted,  $e );
  
  $row  =  "$e $i $ip $r $rp $drafted $draftedp\n";
  
  $row  =~ s/ / \|\| /g;
  $row .=  "|-\n";     # prepare for new row
  
  return $row;
}

sub compute_proposals_stats {

  my $arb        = shift; # person whose votes to count
  my $arbs_votes = shift; # types of votes to count
  my $table      = shift; # table of votes to count

  my %count;
  my $total = count_values($table->{$arb}, $arbs_votes,  # inputs
                           \%count                       # output
                          );
  
  my ($e, $i, $ip, $r, $rp, $v, $vp, $dn, $dnp, $a, $ap, $s, $sp,
      $fs, $fsp, $o, $op, $at, $mt);
  
  my $row = "";
  $e  = $total - $count{"N"};
  $i  = $count{"I"};                           $ip   = percentage( $i,  $e       ); 
  $r  = $count{"R"};                           $rp   = percentage( $r,  $e-$i    );
  $v  = $count{"S"}+$count{"S1"}+$count{"O"};  $vp   = percentage( $v,  $e-$i-$r );
  $a  = $count{"A"};                           $ap   = percentage( $a,  $e-$i-$r );
  $dn = $count{""};                            $dnp  = percentage( $dn, $e-$i-$r );
  $s  = $count{"S"}+$count{"S1"};              $sp   = percentage( $s,  $v       );
  $fs = $count{"S1"};                          $fsp  = percentage( $fs, $e       );
  $o  = $count{"O"};                           $op   = percentage( $o,  $v       );

  my $arb2 = $arb . $uniqueTag; # access some other stats for this arb
  my $col = $table->{$arb2};

  $at = avg_of_nonempty_entries($col);
  $at = round_ndigits($at, 1);
  $at = add_dot0($at);
  
  $mt = median_of_nonempty_vals($col);
  $mt = round_ndigits($mt, 1);
  $mt = add_dot0($mt);
  
  my @vals = ($e, $i, $ip, $r, $rp, $v, $vp, $a, $ap, $dn, $dnp,
              $s, $sp, $o, $op, $fs, $fsp, $at, $mt); 

  $row  =  join (' || ', @vals) . "\n";
  $row .=  "|-\n";     # prepare for new row

  # Tag2
  #print "$arb $row";

  return $row;

}

sub compute_motions_summary{

  my $table = shift;
  my $text  = shift;
  
  my $beg_sum_tag = "<!-- begin motions summary all -->";
  my $end_sum_tag = "<!-- end motions summary all -->";

  my $motions     = $table->{"Motion"};
  my $nMotions    = scalar(@$motions);

  my $days        = $table->{"Days"};
  my $average     = find_average(@$days);
  $average        = round_ndigits($average, 1);

  my %disp_count;
  my $disp        = $table->{"Disp"};
  my $disp_names  = ["Passed", "Failed"];
  my $total       = count_values($disp, $disp_names,   # inputs
                                \%disp_count          # output
                                );
  
  my $p  = $disp_count{"Passed"}; my $pp = percentage( $p,  $nMotions);
  my $f  = $disp_count{"Failed"}; my $fp = percentage( $f,  $nMotions);
  
  my $summary =
     "\n* Publicly offered motions: $nMotions; " 
        . "average duration: $average days; " 
           . "passed: $p ($pp); failed: $f ($fp).\n"; 

  $text = put_text_between_tags($text, $summary,
                                $beg_sum_tag, $end_sum_tag);
  
  return $text;
}

sub compute_cases_summary{

  my $table = shift;
  my $text  = shift;
  
  my $beg_sum_tag = "<!-- begin cases summary all -->";
  my $end_sum_tag = "<!-- end cases summary all -->";

  my $cases     = $table->{"Case"};
  my $nCases    = scalar(@$cases);

  my $days        = $table->{"Days Open"};
  my $average     = find_average(@$days);
  $average        = round_ndigits($average, 1);

  my $summary =
     "\n* Publicly heard cases: $nCases; " 
        . "average duration: $average days.\n"; 

  $text = put_text_between_tags($text, $summary,
                                $beg_sum_tag, $end_sum_tag);

  return $text;
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
  %$count = ();

  my %names_hash;
  my $all_names = "";
  foreach my $name (@$names){
    $names_hash{$name} = 1;
    $all_names .= ' \'' . $name . '\'';
  }

  # We expect all the elements to be from @$names
  my $err_flag = 0;
  
  foreach my $val (@$vals){

    if (!exists $names_hash{$val}){
      print "<br><font color=red>Error: found element '$val' "
         .  "where we expected values from among $all_names</font><br>\n";
      $err_flag = 1;
    }

    if (exists $count->{$val}){
      $count->{$val}++;
    }else{

      $count->{$val} = 1;
    }

  }
  
  my $total = 0;     # output 
  foreach my $name (@$names){

    if (!exists $count->{$name} ){
      $count->{$name} = 0;
    }

    $total += $count->{$name};     # output
  }

  # A sanity check: unless there was an error
  # the total number of counted elements must
  # equal the total number of elements
  if (!$err_flag && $total != scalar(@$vals)){
    print "<font color=red>Error: Could not count some elements properly.\n";
    exit(0);
  }
  
  if ($err_flag){
    return 0; # Mark that we encountered unexpected elements
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

sub find_average{

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

sub find_median{

  my $array = shift;
  my $len = scalar(@$array);

  if ($len <= 0){
    print "Cannot find the median of an empty set of values\n";;
    return 0;
  }

  my $sorted = [ sort {$a <=> $b} @$array ];

  my ($l, $r);
  
  $l = int( ($len-1)/2.0 );
  $l = 0 if ($l <= 0);
  
  $r = int( ($len-0)/2.0 );

  return ($sorted->[$l] + $sorted->[$r] )/2.0;
}

sub percentage {

  my $val   = shift;
  my $outOf = shift;

  return "" if ( $val =~ /^\s*$/ || $outOf == 0 );
  
  return (round_ndigits(100*$val/$outOf, 0)) . "%";
}

sub round_ndigits {

  my $val = shift;
  my $n   = shift;

  if ($val =~ /^\s*$/){
    return "";
  }
  
  my $power = 1;
  my $i;
  for ($i = 0 ; $i < $n ; $i++){
    $power *= 10;
  }

  $val = int($val*$power + 0.5)/$power;

  return $val;
}

sub find_nonempty_vals{

  my $array = shift;

  my $valid = [];

  foreach my $val (@$array){
    
    my $copy = $val; # to avoid modifying the original array
    $copy =~ s/^\s*//g;
    $copy =~ s/\s*$//g;
    next if ($copy =~ /^\s*$/);
    push (@$valid, $copy);
    
  }
  
  return $valid;
}

sub avg_of_nonempty_entries{

  # Given a set of values, ignore those which are empty spaces
  # and find the average of the remaining ones.
  
  my $array = shift;

  my $valid = find_nonempty_vals($array);
  
  if (scalar(@$valid) == 0){
    return "";
  }

  return find_average(@$valid);
}

sub median_of_nonempty_vals {

  my $array = shift;

  my $valid = find_nonempty_vals($array);
  
  if ( scalar(@$valid) == 0 ){
    return "";
  }

  return find_median ($valid);
}

sub add_dot0{

  # Make 6 into 6.0
  
  my $val = shift;
  if ($val =~ /^\d+$/){
    $val = $val . ".0";
  }

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

