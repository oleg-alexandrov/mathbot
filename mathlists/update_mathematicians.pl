#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use open 'utf8';

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use lib '/data/project/mathbot/perl5/lib/perl5/';
use lib '/data/project/mathbot/public_html/wp/modules/lib/perl5/x86_64-linux-gnu-thread-multi';

require 'bin/perlwikipedia_utils.pl'; 
require "strip_accents_and_stuff.pl";
require "bin/fetch_articles.pl";
require "read_from_write_to_disk.pl";
require "bin/get_last.pl";
require 'lists_utils.pl';
undef $/; # undefines the separator. Can read one whole file in one scalar.

MAIN:{

  my $Editor=wikipedia_login();

  my (@names, $dir, $file, $text, $birth, $death, $country, %country2nationality, $last, $name, $name_stripped);
  my ($mathematician_prefix, $countries_file, $all_mathematicians, $mathematicians_logfile, $todays_log, $mathematician_cat_list);
  my ($list_of_categories, @mathematics_categories, @mathematician_categories, @other_categories, @articles_from_cats, @new_categories);
  my (%entries, $line, @lines, %people, $letter, $articles_from_cats_file, $sleep, $attempts,  %blacklist, $ndash, $edit_summary);
  my  @letters=("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z");


  # files to be used
  $countries_file='Countries.txt';
  $mathematician_prefix='List of mathematicians'; # will add later (A), (B), ... 
  $articles_from_cats_file='All_mathematicians_from_cats.txt';
  $all_mathematicians='All_mathematicians.txt';
  $mathematicians_logfile='Mathematicians_log.txt';
  $mathematician_cat_list = "New_mathematician_categories.txt";
  
  $list_of_categories='List_of_mathematics_categories.wiki';
  # Get today's articles found in categories
  &read_categories_from_list(\@mathematics_categories,\@mathematician_categories,\@other_categories, $list_of_categories);
  &fetch_articles(\@mathematician_categories, \@articles_from_cats, \@new_categories);
  open (FILE, ">", $mathematician_cat_list); print FILE join ("\n", @new_categories); close(FILE);

  &put_redirects_on_blacklist ($Editor, \%blacklist, $articles_from_cats_file, \@articles_from_cats);
  &put_redlinks_on_blacklist($mathematician_prefix, \@letters, \%blacklist); 

  @articles_from_cats=&randomize_array(@articles_from_cats); # this has a purpose, to identify entries differning only by capitals
  
  &read_countries ($countries_file, \%country2nationality);
  &parse_new($Editor, \@articles_from_cats, \%country2nationality, \%entries);

  # now, deal with the existing entries in the list of mathematicians
  $sleep = 5; $attempts=100; $text="";
  foreach $letter (@letters){
    $text = $text . "\n" . wikipedia_fetch($Editor, "$mathematician_prefix ($letter).wiki", $attempts, $sleep);
  }
  $text =~ s/\[\[Category:.*?\]\]//g; # rm any categories, those are not mathematicians

  # combine the data from the new list of mathematicians (%entries) and the existing list ($text)
  @lines = split("\n", $text);
  foreach $line (@lines){
    
    next unless ($line =~ /^\s*\*\s*\[\[(.*?)\]\]/);
    $name=$1; 

    # Upcase. Something more robust will need to be put in here.
    $name =~ s/^(.)/uc($1)/eg;
    
    # add last, first if not there yet
    if ($name !~ /\|/ ) { 
      $last = &get_last( $name ); # for a given name, try to guess the first name and the last name
      $line =~ /^\s*\*\s*\[\[(.*?)\]\](.*?)$/;
      $line = "* \[\[$name\|$last\]\]$2"; 
    }
    
    $name =~ s/\|.*?$//g; # strip pipe
    next if (exists $blacklist{$name}); # ignore blacklist, just as above
    
    # reconcile the new $entries{$name} with the old $line
    if ( !exists $entries{$name} ){
      $entries{$name} = "";
    }
    $entries{$name}=&reconcile ($line, $entries{$name}); 

    # Replace [[name|name]] with [[name]]
    if ( $entries{$name} =~ /^(.*?\[\[)(.*?)\|(.*?)(\]\].*?)$/ ){
        my ($a, $b, $c, $d) = ($1, $2, $3, $4);
        $entries{$name} = "$a$b$d" if ( $b eq $c );
    }

  }
  
  # split into a number of hashes, by letter. Those hashes are keyed by an ascii version of the last nime, for sorting. 
  foreach $name (keys %entries ){
    
    # strip the last name of accents and prefixes to be able to sort by it.
    next unless ($entries{$name} =~ /^\s*\*\s*\[\[(.*?)\]\]/);
    $last=$1; $last = &strip_last($last);
    
    next unless ($last =~ /^([a-z])/i);
    $letter=uc($1);
    $people{$letter}->{$last}=$entries{$name};
  }

  foreach $letter (@letters){
    &split_into_sections ($people{$letter});

    $text = "__NOTOC__\n\{\{MathTopicTOC\}\}\n";
    foreach $last ( sort {$a cmp $b} keys %{$people{$letter}} ) {
      $text .= "$people{$letter}->{$last}\n";
    }
    $text .= "\n[[Category:WikiProject Mathematics list of mathematicians|$letter]]";

    # These are groups of people, not individual mathematicians
    $text =~ s/(Bourbaki.*?\(.*?),.*?\n/$1\)\n/g;
    $text =~ s/(Martians.*?\(.*?),.*?\n/$1\)\n/g;
    $text =~ s/(Blanche Descartes.*?\(.*?),.*?\n/$1\)\n/g;

    $edit_summary='Daily update. See [[User:Mathbot/Changes to mathlists]] for changes.';
    wikipedia_submit($Editor, "$mathematician_prefix ($letter).wiki", $edit_summary, $text, $attempts, $sleep);
  }

  # create log and write to disk. Later will integrate with mathematics articles log and submit
  $todays_log=&process_log_of_todays_changes(\%entries, \%blacklist, $all_mathematicians);
  open(FILE, ">$mathematicians_logfile");  print FILE "$todays_log";  close(FILE);
  
}

sub read_countries {
  my (@countries, $countries_file, $country2nationality);
  
  ($countries_file, $country2nationality)=@_;
  
  open (FILE, "<", $countries_file); # map from nationality to country
  @countries=split("\n", <FILE>);
  close(FILE);
  
  foreach (@countries){
    next unless (/^(.*?)\s*-\s*(.*?)\s*$/);
    $country2nationality->{lc($1)}=$2;
  }
  $country2nationality->{"\?"}="\?"; # unknown country
}

sub parse_new {
  my ($name, $text, $country, $birth, $death, $last);
  my ($Editor, $articles_from_cats, $country2nationality, $entries)=@_;

  # go through the articles, read them in and get necessary data. 
  foreach $name (@$articles_from_cats){
    
    next if ($name =~ /mathematicians?$/i); # this is not a person, rather a list, or term
    next if ($name =~ /^List of/i); # this is not a person, rather a term
    next if ($name =~ /^Contributors/i); # this is not a person, rather a list
    next if ($name =~ /^Chief statistician/i); # this is not a person, rather a list
    next if ($name =~ /^logician/i); # this is not a person
    next if ($name =~ /^Association for Women in Mathematics/i); # this is not a person
    next if ($name =~ /^Abel Prize/i); # this is not a person

    $text = &read_from_disk_or_wikipedia($Editor, $name);
    
    # get DOB, country, etc
    ($country, $birth, $death) = &parse_get_data($text, $country2nationality);
    $last = &get_last( $name ); # for a given name, try to guess the first name and the last name
    $entries->{$name}="* \[\[$name|$last\]\] \($country, $birth - $death\)"; # put in a hash

  }
}

sub strip_last {
  my $last=shift;
  
  if ($last =~ /\|(.*?)$/){
    $last=$1;
  }
  
  # this is needed to sort things well
  $last =~ s/^D\'//gi; # D'Alambert, sort by A
  $last =~ s/\'/ /g; # l'Hospital becomes l Hospital
  $last =~ s/^[a-z]+ //g; # rm word not starting with upper case (like "de Vito", sort by V and not d)
  $last =~ s/^[a-z]+ //g; # this will work for van der Waerden
  $last =~ s/^[a-z]+ //g; # one more time just in case
  $last =~ s/^Le //g; # for some French mathematicians
  $last =~ s/^Al[\- ]//ig; # for some French mathematicians
  
  $last = &strip_accents_and_stuff($last); # and strip accents
  
  return $last;
}

sub reconcile {
 my ($old, $oname, $ocountry, $obirth, $odeath, $new, $nname, $ncountry, $nbirth, $ndeath);
 ($old, $new)=@_;
   

   $old =~ s/\&nbsp;/ /g;
   $old =~ s/\&[nm]dash;/-/g;
   $old =~ s/\x{2013}/-/g; # ndash
   $old =~ s/\x{2014}/-/g; # mdash 

 # from new, take the country, birth, death info
 if ($new =~ /^\s*\*\s*\[\[(.*?)\]\]\s*\((.*?),(.*?)-(.*?)\)/){
   $nname=$1; $ncountry=$2; $nbirth=$3; $ndeath=$4;
   $ncountry =~ s/\s*$//g; $ncountry =~ s/^\s*//g;
   $nbirth =~ s/\s*$//g; $nbirth =~ s/^\s*//g;
   $ndeath =~ s/\s*$//g; $ndeath =~ s/^\s*//g;
 }else{
   $nname = ""; 
   $ncountry = "?"; $nbirth = "?"; $ndeath = "";
 }

  # old country
  $ocountry="?"; $obirth="?"; $odeath="";
  if ($old =~ /^\s*\*\s*\[\[(.*?)\]\].*?\((.*?),(.*?)-(.*?)\)/){ $odeath=$4;   }
  if ($old =~ /^\s*\*\s*\[\[(.*?)\]\].*?\((.*?),(.*?)[-\)]/   ){ $obirth=$3;   }
  if ($old =~ /^\s*\*\s*\[\[(.*?)\]\].*?\((.*?),\s*born(.*?)[-\)]/ ){ $obirth=$3;   }
  if ($old =~ /^\s*\*\s*\[\[(.*?)\]\].*?\((.*?)[\),\d]/       ){ $ocountry=$2; }
  if ($old =~ /^\s*\*\s*\[\[(.*?)\]\]/                        ){ $oname=$1;    } 

  # strip space
  $ocountry =~ s/\s*$//g;   $ocountry =~ s/^\s*//g;
  $obirth   =~ s/\s*$//g;   $obirth   =~ s/^\s*//g;
  $odeath   =~ s/\s*$//g;   $odeath   =~ s/^\s*//g;

  # Always keep the the name from the old. For the rest, keep the entry with most info.
  $nname    = $oname     if (                      $oname    =~ /\w/    ); 
  $ncountry = $ocountry  if ($ncountry  !~ /\w/ && $ocountry =~ /\w/    );
  $nbirth   = $obirth    if ($nbirth    !~ /\d/ && $obirth   =~ /[^\?\-]/ ); 
  $ndeath   = $odeath    if ($ndeath    !~ /\d/ && $odeath   =~ /[^\?\-]/ );
  
  if ($ncountry !~ /\w/){ $ncountry = '?'; }
  if ($nbirth   !~ /\d/){ $nbirth   = '?'; }
  if ($ndeath   !~ /\d/){ $ndeath   = '?'; }

  if ($nbirth !~ /\?/ && $ndeath =~ /^[\?\s]*$/){
    return "* [[$nname]] \($ncountry, born $nbirth\)";	  
  }else{
    return "* [[$nname]] \($ncountry, $nbirth\x{2013}$ndeath\)";	  
   }
}

sub parse_get_data {

  my ($country, $birth, $death, @countries, %duplication_tracker, $text, $country2nationality);

  $text=$_[0]; $country2nationality=$_[1];

  $text =~ s/\[\[Category\s*:\s*Ancient\s+mathematicians[^\]\[]*?\]\]//ig; 
  $text =~ s/\[\[Category\s*:[^\]]*?century[^\]\[]*?\]\]//ig; 
  $text =~ s/\[\[Category\s*:[^\]]*?women[^\]\[]*?\]\]//ig; 
  $text =~ s/\[\[Category\s*:\s*Mathematicians[^\]\[]*?\]\]//ig; 
  $text =~ s/\[\[Category\s*:\s*Statisticians[^\]\[]*?\]\]//ig; 
  $text =~ s/\[\[Category\s*:\s*Logicians[^\]\[]*?\]\]//ig; 
  $text =~ s/\[\[Category\s*:\s*Biographies and autobiographies of mathematicians+[^\]\[]*?\]\]//ig; 
  
  @countries=();
  @countries = (@countries, ($text =~ /\[\[Category:\s*([a-z ]*?)\s+mathematicians/ig));
  @countries = (@countries, ($text =~ /\[\[Category:\s*([a-z ]*?)\s+logicians/ig));
  @countries = (@countries, ($text =~ /\[\[Category:\s*([a-z ]*?)\s+statisticians/ig));

  $country=""; 
  foreach (@countries){
    if ( exists $country2nationality->{lc($_)}){
      $_= $country2nationality->{lc($_)};
    }elsif ($_ =~ /^\s*(\w+)\s+(\w.*?)\s*$/ && exists $country2nationality->{lc($2)} ){  
     $_ = $1 . " " . $country2nationality->{lc($2)};      
    }else{
      $_= "";
    }

    if  ( ! exists $duplication_tracker{$_} && $_ !~ /^\s*$/) {
      $country = "$country" . "$_" . "/";
      $duplication_tracker{$_}=1;
    }
  }
  $country =~ s/^\s*\/*\s*//;
  $country =~ s/\s*\/*\s*$//;
  $country = "\?" if ($country =~ /^\s*$/);

  $birth="\?"; # a person must have a date of birth
  my @bmatches = ( $text =~ /\[\[Category:\s*([^\]\[]*?)\s+births/ig );
  foreach my $match (@bmatches){
    if ($match =~ /\d/) { $birth = $match; }
  }

  $death="\?";
  my @dmatches = ( $text =~ /\[\[Category:\s*([^\]\[]*?)\s+deaths/ig );
  foreach my $match (@dmatches){
    if ($match =~ /\d/) { $death = $match; }
  }

  if ($text =~ /\{\{lived\s*\|\s*b=(.*?)\s*\|\s*d=(.*?)\s*[\}\|]/i) { 
    $birth=$1; $death=$2;
  }elsif  ($text =~ /\{\{lived\s*\|\s*b=(.*?)\s*[\|\}]/i){
    $birth=$1;
  }

  return ($country, $birth, $death);
}


  

