#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules

require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';

my $work_dir = $ENV{HOME} . '/public_html/wp/arb';
@INC = ($work_dir, @INC);
require 'votes_utils.pl';

undef $/; # undefines the separator. Can read one whole file in one scalar.

MAIN:{
  my ($file, $text, $user, $sorting, $i, $success, $counter, $base, $count, $edit_summary);
  my (@nomins, $nomin, $nomin_text, $beg, $end, $tag, %done, $key, $suptext, $optext, %support, %oppose, %percent_support, $no, $attempts, $sleep);

  $attempts=1;
  $sleep=1;
  $success=0;
  
  chdir $work_dir;
  &wikipedia_login();
  
  $file='Wikipedia:Arbitration_Committee_Elections_December_2007/Vote.wiki';
  $text=&wikipedia_fetch($file, $attempts, $sleep);
  $text =~ s/_/ /g;
  
  @nomins = ($text =~ /\{\{Wikipedia:Arbitration Committee Elections December 2007\/Candidate statements\/(.*?)\}\}/g);
  foreach $nomin (@nomins){
    $support{$nomin} = 0;
    $oppose{$nomin} = 0;
    $percent_support {$nomin}=0;
  }
  
  $count=0;
  foreach $nomin (@nomins){
    $count++;
    
    $file = "Wikipedia:Arbitration Committee Elections December 2007\/Vote\/$nomin.wiki";
    print "$file\n";
    print "$nomin\n";
    $text=&wikipedia_fetch($file, $attempts, $sleep);
    
    next unless ($text =~ /^.*?\n==\s*Support\s*==(.*?)\n==\s*Oppose\s*==(.*?)$/s);
    $suptext=$1; $optext=$2;
    
    if ($optext =~ /^(.*?\n)==\s*Neutral/s){
      $optext=$1;
    }
    
    $support{$nomin} =         &calc_votes($suptext);   print "$support{$nomin} supports for $nomin\n";

    $oppose{$nomin} =          &calc_votes($optext);    print "$oppose{$nomin} opposes for $nomin\n";

    $percent_support{$nomin} = &percent_support_calc ($support{$nomin}, $oppose{$nomin});

    print "sleeping 1\n"; sleep 1;
  }
  
  $file="User:Mathbot\/ArbCom Election December 2007.wiki";
  $text = &wikipedia_fetch($file, $attempts, $sleep);
  my $bot_tag = '<!-- bot tag, don\'t modify it or below-->';
  if ($text =~ /(^.*?\Q$bot_tag\E)/s){
    $text = $1;
  }else{
    $text=$bot_tag;
  }	 

  $text = $text . "\n" . "\* This table is updated twice per hour. Last update at  ~~~~~ by ~~~.\n"
        . "\* For comparison, the time now is \{\{CURRENTTIME\}\}, \{\{CURRENTMONTHNAME\}\} \{\{CURRENTDAY\}\}, \{\{CURRENTYEAR\}\} \(UTC\).\n"
#	. "\* See also [[User:Gurch/Reports/ArbComElections]] for another table.\n"
  . "\{\| class=\"wikitable\"\n"
  . "\|\n\|Name\n\|Support\n\|Oppose\n\|Support\/Total in percent\n\|-\n";

  $count=0;
  foreach $nomin (sort { $percent_support{$b} <=> $percent_support{$a} } keys %support) {
  
    $count++;
    
    $text = $text 
          . "\|$count\n"
          . "\|\[\[Wikipedia:Arbitration Committee Elections December 2007\/Vote\/$nomin\|$nomin\]\]\n"
          . "\| $support{$nomin}\n"
          . "\| $oppose{$nomin}\n"
          . "\| " . int ( 100 * $percent_support{$nomin} + 0.5)/100 . "\%\n"
          . "\|-\n";
    
  }
  
  $text = $text . "\|\}\n";
  
  $edit_summary = "Results of the arbcom elections so far";
  &wikipedia_submit($file, $edit_summary, $text, $attempts, $sleep);
  
}

