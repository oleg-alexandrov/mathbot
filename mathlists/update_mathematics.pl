#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use open 'utf8';

require '/data/project/mathbot/public_html/wp/modules/bin/perlwikipedia_utils.pl';
use lib '/data/project/mathbot/public_html/wp/modules';
use lib '/data/project/mathbot/public_html/wp/mathlists';
require 'bin/rm_extra_html.pl';
require 'strip_accents_and_stuff.pl';
require 'lists_utils.pl';

undef $/; # undefines the separator. Can read one whole file in one scalar.

# Collect the mathematics articles from the mathematics categories. Merge them into the [[list of mathematics articles]] on Wikipedia.
# Remove redlinks, redirects, and disambig pages. Submit to Wikipedia the log of changes and newly detected categories. This runs daily.
my $mdash = "\x{2013}";
my $n09 = "0" . $mdash . "9";
MAIN: {

  $| = 1; # flush the buffer each line
  
  my ($line, @lines, %articles, $letter, %blacklist, @articles_from_cats, $text, $file, $sleep, $attempts, $edit_summary, $todays_log);
  my ($list_of_categories, @letters, @mathematics_categories, @mathematician_categories, @other_categories, $log_file, $count);
  my ($articles_from_cats_file, $all_math_arts_file, @new_categories, %current_categories, %all_articles, $mathematicians_logfile, $prefix, $Editor);
  @letters=($n09, "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z");

  # Files involved (they are many).
  $list_of_categories='List_of_mathematics_categories.wiki';
  $log_file="User:Mathbot/Changes_to_mathlists.wiki";

  # The files with the .txt extension are local, they don't get submitted to Wikipedia.
  $articles_from_cats_file='All_mathematics_from_cats.txt';
  $all_math_arts_file='All_mathematics.txt';
  $mathematicians_logfile='Mathematicians_log.txt';

  $prefix = "Wikipedia:WikiProject_Mathematics/List of mathematics articles";
  
  $sleep = 5; $attempts=5; # necessary to fetch data from Wikipedia and submit
  #$Editor=wikipedia_login();

  # Get today's articles found in categories
  print "Read categories from list\n";
  &read_categories_from_list(\@mathematics_categories,\@mathematician_categories,\@other_categories,
			     $list_of_categories);
  print "fetch aricles in cats\n";
  &fetch_articles_in_cats(\@mathematics_categories, \@articles_from_cats, \@new_categories);
  print "randomize\n";
  @articles_from_cats=&randomize_array(@articles_from_cats); # to later identify entries differning only by capitals

  # articles which we will not allow in the math list for various reasons
  &put_redlinks_on_blacklist($prefix, \@letters, \%blacklist);
  &put_mathematicians_on_blacklist_and_user_selected_also(\%blacklist);
  &put_redirects_on_blacklist($Editor, \%blacklist, $articles_from_cats_file, \@articles_from_cats);

  # go letter by letter, and merge the new entries
  foreach $letter (@letters){
    $file = "$prefix ($letter).wiki"; 
  
    $text=wikipedia_fetch($Editor, $file, $attempts, $sleep);  # fetch the lists from Wikipedia
    exit (0) if ($text =~ /^\s*$/);                      # quit if can't get any of the lists 

    # the heart of the code
    $text = &merge_new_entries_from_categories($letter, $text, \@articles_from_cats, \%blacklist, \%all_articles);

    $edit_summary="Daily update. See the log at [[User:Mathbot/Changes to mathlists]].";
    wikipedia_submit($Editor, $file, $edit_summary, $text, $attempts, $sleep);

  }
  &post_newly_detected_categories($Editor, \@mathematics_categories, \@mathematician_categories, \@other_categories, \@new_categories);

  # create the log of changes to the math articles. Merge with the changes to mathematician articles. Submit.
  $todays_log=&process_log_of_todays_changes(\%all_articles, \%blacklist, $all_math_arts_file); # changes to the mathematics articles
  open(FILE, "<$mathematicians_logfile"); $text=<FILE>; close(FILE);
  $text =~ s/^==.*?==\s*//g; $text =~ s/(^|\n)(:.)/"$1: Mathematicians" . lc($2)/eg;
  $todays_log = $todays_log . "----\n" . $text;
  &merge_logs_and_submit($Editor, $todays_log, $log_file);
}

# articles which we will not allow in the [[list of mathematics articles]]
sub put_mathematicians_on_blacklist_and_user_selected_also {
  my $blacklist=shift;
  my ($line, @lines);

  # read blacklist from file
  open (FILE,  '<', "User:Mathbot/Blacklist.wiki");      @lines = split ("\n", <FILE>); close(FILE);
  foreach $line (@lines) {
    next unless ($line =~ /\[\[(.*?)\]\]/);
    $line = $1; $line =~ s/^(.)/uc($1)/eg; # upcase
    $blacklist->{$line}= '(is in [[User:Mathbot/Blacklist]])';
  }

  # blacklist the mathematicians (which already are in the [[list of mathematicians]]) 
  open (FILE,  '<', "All_mathematicians.txt");  @lines = split ("\n", <FILE>);  close(FILE);
  foreach $line (@lines) {
    $blacklist->{$line}= '(is in the [[list of mathematicians]])';
  }
}

# the heart of the code
sub merge_new_entries_from_categories{

  my ($link, $link_stripped, @links, %articles);
  my ($letter, $text, $articles_from_cats, $blacklist, $all_articles)=@_;

  $text = &rm_extra_html($text); # replace &amp; with &, etc. This was needed for one run only I think.

  @links=split("\n", $text); 
  foreach $link (@links){
    if ($link =~ /^\[\[(.*?)(\||\]\])/){ # extract the link
      $link=$1;
    }else{
      $link="";
    }
  }
  @links=(@links, @$articles_from_cats); # append the randomized @articles_from_cats to @links
  
  # put into hash the entries starting with current letter
  foreach $link (@links){
    
    next if (exists $blacklist->{$link});  # don't add blacklisted items to the list of topics
    next if ($link =~ /(talk|wikipedia|template|category|user):/i);  # ignore talk pages, templates, etc
    next if ($link =~ /List of mathematics articles \(/i); # do not put links to lists themselves, that's stupid
    next if ($link =~ /^\s*$/); # ignore empty links

    # Get a copy of the link stripped of accents and non-alphanumberic.
    # Will use it for sorting.
    $link_stripped = &strip_accents_and_stuff ($link); 
    
    # now, do not deal with any articles except the current letter
    if ($letter eq $n09){
      next unless ($link_stripped =~ /^[0-9]/);
    }else{
      next unless ($link_stripped =~ /^$letter/i);
    }
    
    $articles{$link_stripped} = "\[\[$link\]\] \[\[Talk:$link\| \]\] -- "; # put them all in a hash
    $all_articles->{$link}=1; # this will be exported out of this function
  }
  
  # split into sections and collect all data in $text
  &split_into_sections (\%articles);
  $text="__NOTOC__\n{{MathTopicTOC}}\n";
  foreach (sort { $a cmp $b } keys %articles) {
    $text = $text . $articles{$_} . "\n";
  }
  $text = $text . "\n[[Category:WikiProject Mathematics list of articles|$letter]]\n";
  return $text;
}

sub post_newly_detected_categories {

  my ($Editor, $mathematics_categories, $mathematician_categories, $other_categories, $new_categories)=@_;
  my (%current_categories, $text, $line, $mathematician_cat_list, $sleep, $attempts, $edit_summary, $file);

  # add to the newly discovered mathematics categories the mathematician categories discovered when running that script
  $mathematician_cat_list = "New_mathematician_categories.txt";
  open (FILE, "<", $mathematician_cat_list); $text =  <FILE>; close(FILE);
  @$new_categories = (@$new_categories, split ("\n", $text));

  # current categories
  foreach $line (@$mathematics_categories  ){ $current_categories{$line}=1;  }
  foreach $line (@$mathematician_categories){ $current_categories{$line}=1;  }
  foreach $line (@$other_categories        ){ $current_categories{$line}=1;  }

  # see which of the @$new_categories are trully new
  $text="";
  foreach $line (@$new_categories){
    next if ( exists $current_categories{$line} );
    next unless ($line =~ /Category:/);
    $text = $text . "\[\[:$line\]\] -- \n";
  }

  $file              = "User:Mathbot/New_math_categories.wiki";
  $sleep = 5; $attempts=5;  $edit_summary="Today's new math categories.";
  wikipedia_submit($Editor, $file, $edit_summary, $text, $attempts, $sleep);
}

sub merge_logs_and_submit{
  my ($Editor, $todays_log, $log_file)=@_;
  my ($combined_log, @days, $sleep, $attempts, $edit_summary);
  
  # Read in the log from previous days (from the disk), append to it today's log
  open (FILE, "<$log_file"); $combined_log=<FILE>; close(FILE);
  $combined_log =~ s/(^.*?\n)(==.*?)$/$1$todays_log\n$2/sg; # 

  # keep only the last month or so
  @days = split ("\n==", $combined_log);
  @days = splice (@days, 0, 39);
  $combined_log = join ("\n==", @days);

  # submit the log file, and write the logfile back to disk (away from wikipedia vandals)
  $sleep = 5; $attempts=5; $edit_summary="Today's changes to the [[list of mathematics articles]].";
  wikipedia_submit($Editor, $log_file, $edit_summary, $combined_log, $attempts, $sleep);
  open (FILE, ">$log_file"); print FILE "$combined_log\n"; close(FILE); # write new log to disk
}




