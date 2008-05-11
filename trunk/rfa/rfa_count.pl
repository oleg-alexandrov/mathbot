#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules

require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
require $ENV{HOME} . '/public_html/wp/arb/votes_utils.pl';
require $ENV{HOME} . '/public_html/wp/rfa/extract_user.pl';

undef $/; # undefines the separator. Can read one whole file in one scalar.

# compute the percentage of support, both for RfA's which already closed, and for ones still open
MAIN:{

  my ($attempts, $sleep, $nomin, %current_nomins, $text, $supp_no, $opp_no, $percent_supp, $file);
  my (%old_nomins, $old_nomins_file, $data, $edit_summary);
  
  $attempts=3;
  $sleep=1;
  
  chdir $ENV{HOME} . '/public_html/wp/rfa/';
  &wikipedia_login();

  $old_nomins_file = "Old_nominations.txt";
  %old_nomins = &read_old_nominations($old_nomins_file);
  
  $file = 'Wikipedia:Requests for adminship.wiki';
  %current_nomins = &list_current_nominations($file);

  foreach $nomin ( sort {$current_nomins{$a} <=> $current_nomins{$b}} keys %current_nomins){

    print "$nomin\n";
    $text=&fetch_file_nosave($nomin . ".wiki", $attempts, $sleep);
    &extract_support_oppose_percentage($nomin, $text, $data);
    
    $data->{$nomin}->{'order'} = $current_nomins{$nomin};
    $data->{$nomin}->{'status'} = 'Open';
    $data->{$nomin}->{'success'} = ' ';
    
    last if ($current_nomins{$nomin} >= 2);
  }

  $file = "User:Mathbot/RfA table.wiki";
  $text = &print_data ($file, $data);

  print "$text\n";
  exit(0);
#   $attempts = 10; $sleep = 2; $edit_summary = "Update RfA table";
#   &wikipedia_submit($file, $edit_summary, $text, $attempts, $sleep);

  
}


sub list_current_nominations {

  my ($file, $nomin, $text, @local_current_nomins, %current_nomins, $count);

  $file=shift; 
  $text=&fetch_file_nosave($file, 100, 1);
  if ($text =~ /^\s*$/) {
    print "Error! $file can't be empty!\n";
    exit(0);		      # there is some error, this file can't be empty
  }

  $count = 1;
  @local_current_nomins = ($text =~ /\{\{(Wikipedia:Requests?[ _]for[ _](?:adminship)\/.*?)\}\}/ig);

  foreach $nomin (@local_current_nomins) {

    $nomin =~ s/_/ /g; 
    next if ($nomin =~ /Wikipedia:Requests for adminship\/(Front matter|bureaucratship)/i); # not a real admin candidate

    $current_nomins{$nomin} = $count;
    $count++;
  }

  return %current_nomins;

}

sub read_old_nominations{
  
  my ($text, $file, $line, %old_nomins);
  
  $file = shift;
  open(FILE, "<$file"); $text = <FILE>; close(FILE);
  foreach $line (split ("\n", $text) ){
    next unless ($line =~ /^(.*?)\s+(\d+)$/);
    $old_nomins{$1} = $2;
  }
  
  return %old_nomins;
}

sub extract_support_opposes {
     
  my ($text, $support_text, $oppose_text, $supp_no, $opp_no);

  $text = shift;
  if ($text =~ /^.*?\n(?:'''|==+)\s*Support\s*(?:'''|==+)(.*?)\n(?:'''|==+)Oppose\s*(?:'''|==+)(.*?)$/s){
    $support_text=$1; $oppose_text=$2;
    
    if ($oppose_text =~ /^(.*?)\n(?:'''|==+)\s*Neutral/s){
      $oppose_text=$1;
    }

    $supp_no = &calc_votes($support_text);
    $opp_no  = &calc_votes($oppose_text);

  }else{
   $supp_no = "?"; 
   $opp_no = "?"; 
  }

  return ($supp_no, $opp_no);
}

sub extract_support_oppose_percentage {

  my ($nomin, $text, $data, $supp_no, $opp_no, $percent_supp);

  $nomin = shift; $text = shift; $data = shift;
  
  ($supp_no, $opp_no) = &extract_support_opposes($text);
#  print "$supp_no $opp_no\n";
  
  $percent_supp = percent_support_calc($supp_no, $opp_no);
#  print "$percent_supp\n";
  
  $data->{$nomin}->{'supp'} = $supp_no;
  $data->{$nomin}->{'opp'} = $opp_no;
  $data->{$nomin}->{'perc'} = $percent_supp;
}

sub print_data{

  my ($file, $data, $text, $nomin);
  
  $file = shift; $data = shift;
  
  $text = '{| class="wikitable"' . "\n"
     . '! !! Nomin page !! Support !! Oppose !! S% !! Status !! Sucess? ' . "\n" . '|-' . "\n";
  
  foreach $nomin (sort { $data->{$a}->{'order'} <=> $data->{$b}->{'order'} } keys %$data) {
    
    $text .= 
         "\|\| $data->{$nomin}->{'order'} "
       . "\|\| \[\[$nomin\]\] "
       . "\|\| $data->{$nomin}->{'supp'} "
       . "\|\| $data->{$nomin}->{'opp'} "
       . "\|\| $data->{$nomin}->{'perc'}\% "
       . "\|\| $data->{$nomin}->{'status'} "
       . "\|\| $data->{$nomin}->{'success'} "
       . "\n\|-\n";
    
  }
  
  $text .= "\|\}\n";
  $text .= '{{Wikipedia:Bureaucrats\' noticeboard/RfA Report}}';

  return $text;
  
}

