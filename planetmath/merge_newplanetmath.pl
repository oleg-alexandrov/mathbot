#!/usr/bin/perl
use strict;                            # 'strict' insists that all variables be declared
use diagnostics;                       # 'diagnostics' expands the cryptic warnings

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/perlwikipedia_utils.pl'; # my own packages, this and the one below
require 'bin/perlwikipedia_utils.pl';

undef $/; # undefines the separator. Can read one whole file in one scalar.
use open 'utf8';             # input/output in unicode

# Merge new entries from PlanetMath
MAIN: {
  
  my ($file, $full_file, %files_hash, %entries, $file_no, $key, %ids);
  my ($overwrite, @old_files, @new_files, $text, $sleep, $attempts, $Editor);
  my ($edit_summary, $path, $new_tag);
  
  $sleep = 5; $attempts=500; # necessary to fetch data from Wikipedia and submit
  $Editor=wikipedia_login();

  $path = 'Wikipedia:WikiProject_Mathematics/PlanetMath_Exchange/';
  $new_tag = "\<sup\>\<font color=red\>new\!\<\/font\>\<\/sup\>";
  
  # Go to the working directory
  chdir 'data';
  
  # list existing files
  @old_files = split ("\n", `ls [0-9]*wiki`);
  @new_files = split ("\n", `ls [0-9]*wiki_new`);
  
  # map from two digit file number to files
  foreach $file ((@old_files, @new_files)){
    next unless ($file =~ /^(\d+)/);
    $key=$1;
    
    $files_hash{$key}=$file;
    $files_hash{$key}=~ s/\_new$//g;
  }

  #parse old files
  $overwrite=1; 
  foreach $file (@old_files){
    open (FILE, "<$file"); $text = <FILE>; close(FILE);
    $text =~ s/$new_tag//g; # no longer new
    &parse_file($file, $text, $overwrite, $new_tag, \%entries, \%ids);
  }

  # merge with new files
  $overwrite=0; 
  foreach $file (@new_files){
    open (FILE, "<$file"); $text= <FILE>; close(FILE);
    &parse_file($file, $text, $overwrite, $new_tag, \%entries, \%ids);
  }

  # Fetch recent copy of the old files, fetch and merge again, with overwriting, and submit.
  # This step is not absolutely necessary, but is better to take to avoid edit conflicts
  # with the people who may have edited those files in the meantime. 
  $overwrite=1;
  foreach $file_no (sort {$a <=> $b} keys %files_hash){

    next if ($file_no le '08');
    print "\n\n$file_no\n";

    $file = $files_hash{$file_no};
    $full_file= $path . $file;
    print "$file -- $full_file\n";
    
    $text=wikipedia_fetch($Editor, $full_file, $attempts, $sleep); 
    $text =~ s/$new_tag//g; # no longer new
    &parse_file($file, $text, $overwrite, $new_tag, \%entries, \%ids);

    $text = "";
    foreach $key ( sort {$a cmp $b} keys %entries){
      next unless ($key =~ /^$file_no/);
      $text = $text . "\n\n" . $entries{$key};
    }
    $text =~ s/^\s*//g;
    
    if ($text !~ /^\s*$/){
      $edit_summary = "Adding new PlanetMath entries.";
      wikipedia_submit($Editor, $full_file, $edit_summary, $text, $attempts, $sleep);
    }

  }
}

# Parse and merge entries.
# Sort by $file_no, then by $sec_no, then by $count.
# Each entry is given its id, even section names and preambles.
# It is that thing which makes the code a bit harder to understand.

sub parse_file{ 
  my ($file, $text, $overwrite, $new_tag, $entries, $ids)=@_;
  my ($file_no, $sec_no, $line, @lines, $id, $key, $count, $sep);

  $sep="___x_p_A___"; # separator

  return unless ($file =~ /^(\d+)/);
  $file_no=$1;
  return if ($text =~ /^\s*$/ || (!$text) ); # some problem, if $text is empty

  # $count = 100000 for old ones, and double for new ones. This is so
  # that all the new articles get sorted under the existing articles in
  # each section. 
  $count=(2-$overwrite)*100000;

  # split by section and by entries
  $text =~ s/\n(==[^\=])/$sep$1/g; $text =~ s/\n(\*\s*PM)/$sep$1/g; 
  @lines=split("$sep", $text);

  $sec_no="  00000"; # for the topmost text, before any sections
  foreach $line (@lines) {

    $count++;
    
    next if ($line =~ /^\s*$/);
    $line =~ s/^\s*//g; $line =~ s/\s*$//g; # remove trailing spaces and newlines

    # Each entry is given an id, even section names and preables.
    # Each entry has also a $key. 

    # $id will uniquely identify articles, but $id
    # is same for old and new articles. That's why use $key.
    # $key is also used for sorting. We sort
    # first by $file_no, then by $sec_no, then by $count.
    # A map from id to key will be defined below. 
    if ($line =~ /^==\s*(\d.*?)\s+(.*?)==/) { # section heading
      $sec_no = $1; $id = $sec_no . "_sec";
    }elsif ( $line =~ /id\s*=\s*(\d+)/){    # article
      $id=$1;
    }elsif ($line =~ /\{\{planetmath[\s_]+instructions/i){ # the topmost text
      $id="$file_no" . "top_level";
    }else{
      next; 
    }
    $key = "$file_no" . "$sep" . "$sec_no"  . "$sep" . "$count";

    # mark new articles 
    if ( (!exists $ids->{$id}) && (!$overwrite) ){
      $line =~ s/(\s*-[-]+\s*WP)/$new_tag$1/g;
    }
    
    # Crucial subtle point: if the current id was not yet encountered,
    # or overwriting is allowed, add to the hash. 
    if  (!exists $ids->{$id}) {
      
      $ids->{$id} = $key;
      $entries->{$key} = $line;
      
    }elsif ($overwrite) {

      # Note that we use the old $key here, so that we overwrite rather than
      # add a new entry.
      $key = $ids->{$id};
      $entries->{$key} = $line;
    }
  }
}
 

