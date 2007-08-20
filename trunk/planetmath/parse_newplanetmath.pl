#!/usr/bin/perl
use strict;                            # 'strict' insists that all variables be declared
use diagnostics;                       # 'diagnostics' expands the cryptic warnings

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use Encode;

undef $/; #read the whole file in a line
use open 'utf8';             # input/output in unicode

# for each subject in the AMS math subj. class,
# create a list of articles on that subject from PlanetMath

my $base='http://planetmath.org/';

my %ids; # a hash to keep track of the first occurence of an item
my ($code, $top_file, $bot_file, $ncode, $ndomain, $text, $address);
my (@all, $name, $ocode, $id, $wiki_name, $title);

# Go to the working directory
chdir 'data';

@all=split ("\n", `ls`);
foreach $top_file (@all){
  next unless ($top_file =~ /^ZZZ100[0]*browse_objects/); # top of the hierarchy

  # Put/rm underscores where appropriate. Other cleanup.
  $top_file =~ s/ZZZ100[0]*browse_objects_//g; $top_file =~ s/\+/ /g;
  $top_file =~ s/_/ /g; 
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
    
    open (INFILE, "<$bot_file"); $text=<INFILE>; close(INFILE);

    # Clean up. Now this is section title.
    $bot_file =~ s/^.*objects_//g; $bot_file =~ s/\+/ /g; $bot_file =~ s/_/ /g; 
    print OUTFILE "==$bot_file==\n";
    
    $text =~ s/\n//g;
    $text =~ s/\<(tr|td|li).*?\>/\n\n/ig;

    foreach (split ("\n", $text)) {
      
      next unless (/\?op=getobj/);
      next unless (/\<a href=\"\/(.*?)\"\>(.*?)\<\/a\>/i);
      $address=$1; $name=$2;

      next if ($address =~ /^\s*$/ || $name =~ /^\s*$/);
      $name =~ s/\<img.*?alt=\"(.*?)\".*?\>/$1/ig;

      $address=~ /id=(\d+)/;
      $id="id=$1";

      $wiki_name=$name;
      $wiki_name =~ s/\{//g;
      $wiki_name =~ s/\}//g;

      # this line is needed since sometimes same article can show up
      # again in a different file on PlanetMath
      next if (exists $ids{$id});

      print OUTFILE "* PM: [$base$address $name], $id " .
         "-- WP guess: [[$wiki_name]] -- Status:\n\n";
      $ids{$id}=1;
      
    }
  }
  close(OUTFILE);
}
