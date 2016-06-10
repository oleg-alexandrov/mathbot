#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Unicode::Normalize;
require Encode;
use CGI::Carp qw(fatalsToBrowser);
use lib $ENV{HOME} . '/public_html/wp/modules';
require 'bin/wikipedia_login.pl';
require 'bin/wikipedia_fetch_submit.pl';
require 'WWW/Mediawiki/fetch_submit.pm';

use WWW::Mediawiki::Client;    # upload from Wikipedia
use Date::Parse;

chdir $ENV{HOME} . '/public_html/wp/pmstat';

print "Content-type: text/html\n\n"; 

undef $/; # undefines the separator. Can read one whole file in one scalar.
my ($main_file, $main_file_in, $main_file_swap, $file, @files, $title, $line, @entries, $istyle, $maintext, $top, $mid, $bot, $sig, $user, %users_stat, $debug);
my ($nc, $nm, $n, $m, $aa, $rv, $total, $nr, $c)=(0, 0, 0, 0, 0, 0, 0, 0, 0);
my ($nct, $nmt, $nt, $mt, $at, $rvt, $totalt, $nrt, $ct)=(0, 0, 0, 0, 0, 0, 0, 0, 0);

$debug=0; $debug=1 if (@ARGV);

print "<b>Please be patient! This script will work slowly, to not overwhelm the server.</b><br><br>\n";
 &wikipedia_login();


$main_file_in='Wikipedia:WikiProject_Mathematics/PlanetMath_Exchange/Table_of_topics.wiki_base';
$main_file='Wikipedia:WikiProject_Mathematics/PlanetMath_Exchange/Table_of_topics.wiki';
if ($debug){
  open (MAIN_FILE, "<:utf8", $main_file) || print "$main_file is missing.\n";
  $maintext=<MAIN_FILE>;
  close(MAIN_FILE);
  $maintext=&fetch_file($main_file);
}else{
  open (MAIN_FILE, "<:utf8", $main_file_in) || print "$main_file_in is missing.\n";
  $maintext=<MAIN_FILE>;
  close(MAIN_FILE); # never fetch the file, use the local copy.
}

if ($maintext =~ /^(.*?\<\!\-\- begin table \-\-\>.*?\n)(.*?)(\<\!\-\- end table \-\-\>.*?)$/s){
  $top=$1; $mid=$2; $bot=$3;
}else{
  print "Error! Mathbot can't find the markers delimiting the table!\n"; 
  exit (0);
}

if ($debug){
  $main_file='User:Mathbot/Page1.wiki';
  &fetch_file($main_file);
}
$main_file_swap=$main_file . 'x';
open (MAIN_FILE, ">:utf8", $main_file_swap); 

print MAIN_FILE "$top";
print MAIN_FILE '
<!-- begin row -->
|- bgcolor=#E6E699
! Category
! Total
! Rv
! N
! A
! C
! M
! NC
! NM
! Last updated
';

@files= ($mid =~ /(Wikipedia:WikiProject Mathematics\/PlanetMath Exchange\/\d+.*?)\|/g);
foreach $file (@files){

  $file =~ s/ /_/g;
  $file = "$file.wiki";

  open (FILE, "<:utf8", $file) || print "$file is missing.\n";
  $line=<FILE>;
  close(FILE);

  if (! $debug){
    $line=&fetch_file($file);
  }

  $sig = &return_latest_date($line, $file);
  
  ($nc, $nm, $n, $m, $aa, $rv, $total, $nr, $c)=(0, 0, 0, 0, 0, 0, 0, 0, 0);
  $total=0;

  @entries=split("\n\\*", $line);
  foreach (@entries) {

    if (/\{\{Planetmath instructions\|topic=(.*)\}\}/) {
      $title= "|[[Wikipedia:WikiProject Mathematics/PlanetMath Exchange/$1|$1]]\n";
      $title =~ s/(\|\d\d.*?)-xx(.*?)$/$1$2/ig;
    }
    
    next unless (/^\s*PM/);
    
    if (/\[\[\s*User:(.*?)[\[\|\]]/){
      $user="\[\[User:$1\|$1\]\]";
    }else{
      $user=""; 
    }
    
    if (/Status:(.*?)(\n|$)/) {
      $_=$1; s/[^A-Za-z]//g; $_ = uc ($_);

      if (/NC/) {
	++$nc; $nct++; 
      } elsif (/NM/) {
	++$nm; $nmt++;
      } elsif (/C/) {
	++$c; $ct++;
      } elsif (/N/) {
	++$n; $nt++;
      } elsif (/M/) {
	++$m; $mt++;
      } elsif (/A/) {
	++$aa; $at++;
      } else {
	++$nr; $nrt++;
      }			      # not reviewed
      ++$total; $totalt++;

      if (exists $users_stat{ "$user" . "__" . "$_" }){
	$users_stat{ "$user" . "__" . "$_" }++;
      }else{
	$users_stat{ "$user" . "__" . "$_" }=1;
      }

      if (exists $users_stat{"$user"}){
	$users_stat{"$user"}++;
      }else{
	$users_stat{"$user"}=1;
      }

    }
  }
  $rv=$total-$nr;
  $rvt = $totalt - $nrt;

  if ( $n+$m+$aa+$c == $total || $total == 0 ) { #completed FFFFCC
    $istyle= "|- bgcolor=#CCFFCC \n";
  }elsif ($rv == 0 || $rv eq "") {	      #not started
    $istyle= "|- \n";
  } elsif ($rv == $total ) {   #all reviewed E6E6AA
    $istyle= "|- bgcolor=#E6ffCC \n";
  } else {		      #Started FFFFCC
    $istyle= "|- bgcolor=#FFFFCC \n";
  }

  $rv = "" if ($rv == 0);
  $n  = "" if ($n == 0);
  $aa = "" if ($aa == 0);
  $c  = "" if ($c == 0);
  $m  = "" if ($m == 0);
  $nc = "" if ($nc == 0);
  $nm = "" if ($nm == 0);
  
  print MAIN_FILE "\n<!-- begin row -->\n" . "$istyle";
  print MAIN_FILE $title;
  print MAIN_FILE "| $total || $rv || $n || $aa || $c || $m || $nc || $nm \n";
  print MAIN_FILE "|$sig\n";

}

print MAIN_FILE '
<!-- begin row -->
|- bgcolor=#E6E6AA
! Category
! Total
! Rv
! N
! A
! C
! M
! NC
! NM
! Last updated
';


print MAIN_FILE '
<!-- begin row -->
|- bgcolor=#E6E6AA
| Totals: ' . "\n" .
"| $totalt || $rvt || $nt || $at || $ct || $mt || $nct || $nmt \n" . 
'|~~~~ 
';

$rvt = &mypercentage($rvt, $totalt); 
$nt = &mypercentage($nt, $totalt); 
$at = &mypercentage($at, $totalt); 
$ct = &mypercentage($ct, $totalt); 
$mt = &mypercentage($mt, $totalt); 
$nct = &mypercentage($nct, $totalt); 
$nmt = &mypercentage($nmt, $totalt); 
$totalt = '100%';

print MAIN_FILE '
<!-- begin row -->
|- bgcolor=#E6E6AA
| Totals as a percentage:' . "\n" . 
"| $totalt || $rvt || $nt || $at || $ct || $mt || $nct || $nmt \n" . 
'|~~~~' . "\n\n";
   
print MAIN_FILE "$bot";

close (MAIN_FILE);

`rm -fv \"$main_file\"`;
&fetch_file($main_file);
`cp -fv \"$main_file_swap\" \"$main_file\"`;

open (MAIN_FILE, "<:utf8", $main_file) || print "$main_file is missing.\n";
$maintext=<MAIN_FILE>;
close(MAIN_FILE); 

my $attempts=10; my $sleep = 2; 
&wikipedia_submit($main_file, 'Update table', $maintext, $attempts, $sleep);
#&submit_file ($main_file);

#   this is the second of the two tables
$main_file='Wikipedia:WikiProject_Mathematics/PlanetMath_Exchange/Table_of_credits.wiki';
$main_file_swap=$main_file . 'x';

&fetch_file($main_file);

# open again, to deal with the second table
open (MAIN_FILE, "<:utf8", $main_file); 
$maintext = <MAIN_FILE>;
close(MAIN_FILE);

if ($maintext =~ /^(.*?\<\!\-\- begin credits \-\-\>.*?\n)(.*?)(\<\!\-\- end credits \-\-\>.*?)$/s){
  $top=$1; $mid=$2; $bot=$3;
}else{
  print "Error! Mathbot can't find the markers delimiting the credits table!\n"; 
  exit (0);
}

open (MAIN_FILE, ">:utf8", $main_file_swap); 
print MAIN_FILE "$top\n";

print MAIN_FILE "{| class=\"wikitable\"\n";
print MAIN_FILE '
<!-- begin row -->
|- bgcolor=#E6E6AA
! User
! Total
! N
! A
! C
! M
! NC
! NM
';


foreach ( sort {$users_stat{$b} <=> $users_stat{$a} } keys %users_stat){
  next if (/__/);
  next if (/^\s*$/);
  
  ($total, $rv, $n, $aa, $c, $m, $nc, $nm)=("", "", "", "", "", "", "", "");

  $total = $users_stat{$_} if (exists  $users_stat{$_});
  $n =     $users_stat{"$_" . "__" . "N"}  if (exists  $users_stat{$_ . "__" . "N"});
  $aa =    $users_stat{"$_" . "__" . "A"}  if (exists  $users_stat{$_ . "__" . "A"});
  $c =     $users_stat{"$_" . "__" . "C"}  if (exists  $users_stat{$_ . "__" . "C"});
  $m =     $users_stat{"$_" . "__" . "M"}  if (exists  $users_stat{$_ . "__" . "M"});
  $nc =    $users_stat{"$_" . "__" . "NC"} if (exists  $users_stat{$_ . "__" . "NC"});
  $nm =    $users_stat{"$_" . "__" . "NM"} if (exists  $users_stat{$_ . "__" . "NM"});
  
  print MAIN_FILE '
<!-- begin row -->
|- ' . 
"\n| $_ || $total || $n || $aa || $c || $m || $nc || $nm \n"; 
}

print MAIN_FILE "|}\n";
print MAIN_FILE "$bot";
close (MAIN_FILE);

`cp -fv \"$main_file_swap\" \"$main_file\"`;

open (MAIN_FILE, "<:utf8", $main_file) || print "$main_file is missing.\n";
$maintext=<MAIN_FILE>;
close(MAIN_FILE); 

&wikipedia_submit($main_file, 'Update table', $maintext, $attempts, $sleep);
#&submit_file ($main_file);

print '<br>Done! You may go back to <a href="https://en.wikipedia.org/wiki/Wikipedia:WikiProject_Mathematics/PlanetMath_Exchange"> The project page. </a><br>';


#open STDOUT, ">temp.txt";
#my $log_file=$main_file;
#$log_file =~ s/Table.*?$/Log.wiki/g;
#&fetch_file($log_file); &fetch_file($log_file); 
#&do_log($log_file);
#&submit_file($log_file);
#close (STDOUT);

sub mypercentage{

  my $number=shift;
  my $total=shift;

  $total=1 if ($total == 0.0);
  $number = int (100*$number/$total+0.5);
  return $number;
}
				     
sub return_latest_date {

  my ($file, @lines, $text, $users, $date, $user, $time, %hash, $latest);

  $text=shift;
  $text =~ s/\n==/\n\*==/g;

  $file = shift; $file =~ s/\.wiki//g; $file = "[[$file]]"; $file =~ s/_/ /g;
  
  @lines=split("\n\\*", $text);
  foreach (@lines) {
    next unless (/^\s*PM/);
    next unless (/\n([^\n]*?\[\[User:.*?)$/s);
    $_ = $1;
    if (! /\[\[User:(.*?)[\|\]].*\].*?(\d.*?\(UTC\))/) {
      print "\n\n<br><br><b>In $file, the comment line \"$_\" does not have a timestamp. Will be ignored.</b><br><br>\n\n";
      next;
    }
    $user=$1; $date=$2;
    $time = str2time($date);
    $hash{"[[User:$user|$user]] $date"}=$time;
  }

  @lines = sort { $hash{$a} <=> $hash{$b} } keys %hash; 

  if (@lines){
    $latest = $lines[$#lines];
  }else{
   $latest=""; 
  }

  return $latest;
}

sub do_log {
  my $date=`date`;
  my $ip;
  my $logfile=shift;

  if (exists $ENV{REMOTE_ADDR} ){
    $ip=$ENV{REMOTE_ADDR};
    $ip = "Calling ip=" . $ip . "\n" . `nslookup $ip` . "\n" . `host $ip`;
  }else{
    $ip="";
  }

  open (FILEL, ">>$logfile");
  print FILEL "\n\n" . '-' x 100 . "\n\n" . "$date\n$ip\n\n";
  close(FILEL);
}






