#!/usr/bin/perl
use strict;                            # 'strict' insists that all variables be declared
use diagnostics;                       # 'diagnostics' expands the cryptic warnings
use LWP::Simple;
use Carp qw(croak carp confess);
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use WWW::Mediawiki::Client;   # upload from Wikipedia
use WWW::Mediawiki::fetch_submit; # my own packages, this and the one below
use WWW::Mediawiki::fetch_submit_nosave; # my own packages, this and the one below
use WWW::Mediawiki::wikipedia_login;
use open ':utf8';             # input/output in unicode
undef $/;

# add new entries from planetmath
MAIN: {
  
  my ($file, $full_file, %files_hash, %entries, $sep, $file_no, $key, %ids, $overwrite, @old_files, @new_files, $text);
  $sep="___x_p_A___"; # separator
  
  chdir 'data';
  
  # list existing files
  @old_files = split ("\n", `ls [0-9]*wiki`);
  @new_files = split ("\n", `ls [0-9]*wiki_new`);
  
  # map from two digit file number to files
  foreach $file ((@old_files, @new_files)){
    next unless ($file =~ /^(\d+)/);
    $key=$1;
    $files_hash{$key}=$file;
    $files_hash{$key}=~ s/\_new//g;
  }
  
  $overwrite=1; #parse old files
  foreach $file (@old_files){
    open (FILE, "<", "$file"); $text= <FILE>; close(FILE);
    &parse_file($file, $text, $sep, $overwrite, \%entries, \%ids);
  }
  
  $overwrite=0; # merge with new info
  foreach $file (@new_files){
    open (FILE, "<", "$file"); $text= <FILE>; close(FILE);
    &parse_file($file, $text, $sep, $overwrite, \%entries, \%ids);
  }

  # fetch recent copy of the old files, merge again, with overwriting, and submit
  &wikipedia_login();
  $overwrite=1;
  foreach $file_no (sort {$a cmp $b} keys %files_hash){

    next if ($file_no  <= 85);
    
    $file = $files_hash{$file_no};
    $full_file='Wikipedia:WikiProject_Mathematics/PlanetMath_Exchange/' . $file;
    print "$file -- $full_file\n";
    
    $text=&fetch_file_nosave($full_file, 10, 1); # try to fetch 10 times, with 1 second break
    &parse_file($file, $text, $sep, $overwrite, \%entries, \%ids);
    $text = "";
    foreach $key ( sort {$a cmp $b} keys %entries){
      next unless ($key =~ /^$file_no/);
      $text = $text . "\n\n" . $entries{$key};
    }
    $text =~ s/^\s*//g;
    if ($text !~ /^\s*$/){
      &submit_file_nosave($full_file, "Adding new PlanetMath entries.", $text, 10, 10);
    }
    last if ($file_no > 1000);
  }
}

# parse and merge entries.
# sort by $file_no, then by $sec_no, then by $count. Each entry is given its id, even section names and preables
# it is that thing which makes the code a bit harder to understand
sub parse_file{ 
  my ($file, $text, $sep, $overwrite, $entries, $ids)=@_;
  my ($file_no, $sec_no, $line, @lines, $id, $key, $count);

  return unless ($file =~ /^(\d+)/);
  return if ($text =~ /^\s*$/ || (!$text) ); # some problem, if $text is empty
  $file_no=$1;

  # $count = 10000 for old ones, and double for new ones. Old get sorted first.
  $count=(2-$overwrite)*10000;

  # split by section and by entries
  $text =~ s/\n(==[^\=])/$sep$1/g; $text =~ s/\n(\*\s*PM)/$sep$1/g; 
  @lines=split("$sep", $text);

  $sec_no="  00000"; # for the topmost text, before any sections
  foreach $line (@lines) {

    $count++;
    next if ($line =~ /^\s*$/);
    next if ($line =~ /\'\'\'Duplicate\s+entry\'\'\'/i); # ignore duplicates
    $line =~ s/^\s*//g; $line =~ s/\s*$//g; # remove trailing spaces and newlines

    # give id to everything
    if ($line =~ /^==\s*(\d.*?)\s+(.*?)==/) { # section heading
      $sec_no=$1; $id="$1_sec";
    }elsif ( $line =~ /id\s*=\s*(\d+)/){    # article
      $id=$1;
    }elsif ($line =~ /\{\{planetmath[\s_]+instructions/i){ # the topmost text
      $id="$file_no" . "top_level";
    }else{
      next; 
    }
    
    # sort by $file_no, then by $sec_no, then by $count. Each entry is given its id, even section names and preables
    $key = "$file_no" . "$sep" . "$sec_no"  . "$sep" . "$count";

    # mark new articles
    if ( (!exists $ids->{$id}) && (!$overwrite) ){
      $line =~ s/(\s*-[-]+\s*WP)/\<sup\>\<font color=red\>new\!\<\/font\>\<\/sup\>$1/g;
    }
    
    # crucial subtle point: if the current id was not yet encountered, or overwriting is allowed, add to hash. 
    if  (!exists $ids->{$id}) {
      $entries->{$key} = $line;
      $ids->{$id}=$key;
    }elsif ($overwrite) {
#      delete $entries->{$ids->{$id}}; # to avoid duplicates, delete old entry before creating new copy
      $entries->{$ids->{$id}} = $line;
#      $ids->{$id}=$key;
    }
  }
}
 

