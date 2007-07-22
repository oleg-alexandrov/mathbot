#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::fetch_submit_nosave; # my own packages, this and the one below
use WWW::Mediawiki::wikipedia_login;
use Encode;
undef $/;		      # undefines the separator. Can read one whole file in one scalar.

require 'merge_bluetext.pl';

# use main to avoid the curse of global variables
MAIN: {

  my ($wget, $text, %reds, $missing_prefix, $i, $file, $link, $log_file, $logtext, $letter, $bluetext);
  my ($redtext, $all_bluetext, $removed_lines, $existing_prefix, $total_reds, $total_blues, $percentage, $index);
  
  $index = 'Wikipedia:Missing_science_topics';
  $missing_prefix = $index . '/Maths';
  &wikipedia_login();
  
  $log_file = 'User:Mathbot/Page9.wiki';
  $wget="wget -q -O - ";
  $total_reds = 0; $all_bluetext = ""; $logtext = "";

  for ($i=1 ; $i <=30 ; $i++){
    $logtext = $logtext  . "\n==Removed from \[\[$missing_prefix$i\]\]==\n";
    
    $link = $missing_prefix . $i; $link =~ s/ /_/g; $link = 'http://en.wikipedia.org/wiki/' . $link;
    $text = `$wget \"$link\"`;
    &identify_redlinks ($text, \%reds);
    
    $file = $missing_prefix . $i . ".wiki";
    $text = &fetch_file_nosave($file, 100, 1);
    ($redtext, $bluetext, $removed_lines, $total_reds) = &separate_redlinks_only_lines($text, \%reds, $total_reds);
    
    # submit $redtext, save $bluetext and $removed_lines for the future
    &submit_file_nosave($file, "Rm existing Wikipedia entries (bluelinks).", $redtext, 10, 5); # 
    $all_bluetext = $all_bluetext . $bluetext . "\n";
    $logtext = $logtext . $removed_lines;
  }
  &submit_file_nosave($log_file, "Removed lines", $logtext, 10, 5);

  $existing_prefix = $index . '/ExistingMath';
  $total_blues = &merge_bluetext_to_existing_bluetext_subpages ($existing_prefix, $all_bluetext);

  &update_stats ($index, $total_reds, $total_blues);
}

sub identify_redlinks {
  
  my ($text, $reds, @red_array, $red_entry);
  $text = shift; $reds=shift; 
  
  $text =~ s/\s+/ /g;
  @red_array = ($text =~ /class\s*=\s*\"new\"\s+title\s*=\s*\"(.*?)\"\s*\>.*?\</g);
  
  foreach $red_entry (@red_array) {
    $red_entry =~ s/\&amp;/\&/g;
    #$red_entry=decode("iso-8859-1", $red_entry); # $red_entry = encode("utf8", $red_entry);
    
    $red_entry =~ s/^(.)/uc($1)/eg; #upper case
    $reds->{$red_entry}=1;
  }
}

sub separate_redlinks_only_lines{
	
  my ($line, $blueline, @lines, $text, $redtext, $bluetext, $removed_lines, $reds, $entry, @entries, $total_reds);

  $text=shift; $reds=shift; $total_reds=shift;
  $redtext=""; $bluetext=""; $removed_lines="";

  @lines = split ("\n", $text);
  foreach $line (@lines){
    next if ($line =~ /^\s*$/); 
    
    $blueline="";
    @entries = ($line =~ /\[\[(.*?)\]\]/g); # all links on this line, if any
    
    #see if current line has blue links
    foreach $entry (@entries){
      $entry =~ s/^(.)/uc($1)/eg; #upper case
      next if (exists $reds->{$entry}); # move on if current link is red, as it should be most of the time
      
      # so, current link is blue
      $blueline  = $blueline . "\[\[$entry\]\], ";
    }
    $blueline =~ s/,\s*$//g; # rm trailing comma
    
    if ($blueline =~ /^\s*$/){ # we found no blue links on this line
      $redtext = $redtext . $line . "\n"; 
      $total_reds++ if ($line =~ /\[\[.*?\]\]/); # if current line actually has links, count them
      
    }else{ # will put $line in $removed_lines, and the bluelinks from it in $bluetext
      
      $removed_lines = $removed_lines . $line . "\n";
      $bluetext = $bluetext . "* " . $blueline . "\n";
    }
  }
  
  return ($redtext, $bluetext, $removed_lines, $total_reds);
}      

sub update_stats {

    my ($index, $total_reds, $total_blues, $big_total, $percentage, $beg_tag, $end_tag, $stats, $no1, $no2, $text, $file);
    $index = shift; $total_reds = shift; $total_blues = shift; 
    
    $big_total = $total_reds + $total_blues; 
    $percentage = 100 * $total_blues / $big_total; $percentage = sprintf("%.2f", $percentage);

    $no1 = $percentage / 100; $no2 = 1 - $no1;
    $beg_tag = '<!-- begin bottag -->'; $end_tag = '<!-- end bottag -->';

    $stats ="
Of the $big_total entries, there are $total_reds remaining. 
{\| style=\"border: 1px solid black\" cellspacing=1 width=75% height=15x align=center
 \|+ <big>'''$percentage%'''</big> completed <small>(estimate)</small>
 \|align=center width=$no1% style=background:#7fff00\|
 \|align=center width=$no2% style=background:#ff7f50\|
 \|}
";

  $file = $index . '.wiki';
  $text = &fetch_file_nosave($file, 100, 1);
  $text =~ s/($beg_tag).*?($end_tag)/$1$stats$2/sg;

  &submit_file_nosave($file, "Update the progress for the math lists", $text, 10, 5); 
}


