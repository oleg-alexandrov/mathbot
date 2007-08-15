#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Unicode::Normalize;
require Encode;

undef $/; # undefines the separator. Can read one whole file in one scalar.
my ($file, @files, $title, $line, @entries, $istyle);
my ($nc, $nm, $n, $m, $a, $rv, $total, $nr, $c)=(0, 0, 0, 0, 0, 0, 0, 0, 0);

@files=<Wikipedia\:WikiProject_Mathematics/PlanetMath_Exchange/*wiki>;
foreach $file (@files){
  open (FILE, "<:utf8", "$file");
  $line=<FILE>;
  close(FILE);

  ($nc, $nm, $n, $m, $a, $rv, $total, $nr, $c)=(0, 0, 0, 0, 0, 0, 0, 0, 0);
  @entries=split("\n", $line);
  foreach (@entries) {

    if (/\{\{Planetmath instructions\|topic=(.*)\}\}/) {
      $title= "|[[Wikipedia:WikiProject Mathematics/PlanetMath Exchange/$1|$1]]\n";
      $title =~ s/(\|\d\d.*?)-xx(.*?)$/$1$2/ig;
    }
  
    if (/Status:(.*?)$/) {
      $_=$1;
      if (/NC/) {
	++$nc;
      } elsif (/NM/) {
	++$nm;
      } elsif (/C/) {
	++$c;
      } elsif (/N/) {
	++$n;
      } elsif (/M/) {
	++$m;
      } elsif (/A/) {
	++$a;
      } else {
	++$nr;
      }			      # not reviewed
      ++$total;   
    }
  }
  $rv=$total-$nr;

  if ($rv == 0) {	      #not started
    $istyle= "\n<!-- begin row -->\n|- \n";
  } elsif ( $n+$m+$a+$c == $total ) { #completed FFFFCC
    $istyle= "\n<!-- begin row -->\n|- bgcolor=#CCFFCC \n";
  } elsif ($rv == $total) {   #all reviewed E6E6AA
    $istyle= "\n<!-- begin row -->\n|- bgcolor=#E6ffCC \n";
  } else {		      #Started FFFFCC
    $istyle= "\n<!-- begin row -->\n|- bgcolor=#FFFFCC \n";
  }

  print $istyle;
  print $title;
  print "| $total || $rv || $n || $a || $c || $m || $nc || $nm \n";
  print "|~~~~\n";

}
