#!/usr/bin/perl
use strict;                            # 'strict' insists that all variables be declared
use diagnostics;                       # 'diagnostics' expands the cryptic warnings
use LWP::Simple;

# for each subject in the AMS math subj. class., create a list of articles on that subject from PlanetMath
my $base='http://planetmath.org/';

undef $/; #read the whole file in a line
my @all=split ("\n", `ls`);
my %ids; # a hash to keep track of the first occurence of an item
my ($code, $top_file, $bot_file, $ncode, $ndomain, $text, $address, $name, $ocode, $id, $wiki_name, $title);

foreach $top_file (@all){
  next unless ($top_file =~ /^ZZZ100[0]*browse_objects/); # top of the hierarchy
 
  $top_file =~ s/ZZZ100[0]*browse_objects_//g; $top_file =~ s/\+/ /g; $top_file =~ s/_/ /g; # cleanup 
  $title=$top_file; 
  $top_file =~ s/ /_/g; $top_file = "$top_file.wiki_new";
  
  print "Printing to $top_file\n";
  open (OUTFILE, ">$top_file");
  print OUTFILE "__NOTOC__\n";
  print OUTFILE "{{Planetmath instructions|topic=$title}}\n";

  $top_file =~ /^(\d+)/;
  $code=$1; 
  foreach $bot_file (@all) {
    next unless ($bot_file =~ /^ZZZ[2-9]000browse_objects_$code/);
    #next if ($bot_file =~ /xx_/); # look only at the files at the very bottom of the hierarchy
    
    open (INFILE, "<$bot_file");
    $text=<INFILE>;
    close(INFILE);

    $bot_file =~ s/^.*objects_//g; $bot_file =~ s/\+/ /g; $bot_file =~ s/_/ /g; # Clean up. Now this is section title.
    print OUTFILE "==$bot_file==\n";
    
    $text =~ s/\n//g;
    $text =~ s/\<tr/---\n\n/g;
    $text =~ s/\<td/---\n\n/g;
    $text =~ s/\<li/---\n\n/g;

    foreach (split ("\n", $text)) {
      next unless (/\?op=getobj/);
      next unless (/\<a href=\"\/(.*?)\"\>(.*?)\<\/a\>/);
      $address=$1; $name=$2;
      next if ($address =~ /^\s*$/ || $name =~ /^\s*$/);
      $name =~ s/\<img.*?alt=\"(.*?)\".*?\>/$1/g;

      $address=~ /id=(\d+)/;
      $id="id=$1";

      $wiki_name=$name;
      $wiki_name =~ s/\{//g;
      $wiki_name =~ s/\}//g;
      if (! exists $ids{$id}){
        print OUTFILE "* PM: [$base$address $name], $id -- WP guess: [[$wiki_name]] -- Status:\n\n";
        $ids{$id}="* PM: [$base$address $name], $id -- '''Duplicate entry'''.\n:See [[Wikipedia:WikiProject Mathematics/PlanetMath Exchange/$top_file#$bot_file|$bot_file]]\n\n";
      }else{
        #print OUTFILE "$ids{$id}";
        #print "$ids{$id}";
      }
    }
  }
  close(OUTFILE);
}
