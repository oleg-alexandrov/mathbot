#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Encode;
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/wikipedia_login.pl';
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/fetch_articles.pl';
require 'utils/strip_accents_and_stuff.pl';
require 'lists_utils.pl';
require "bin/get_last.pl";
undef $/; # undefines the separator. Can read one whole file in one scalar.

MAIN: {

  $| = 1; # flush the buffer each line

  my (@letters, @cats, @new_cats, @articles, $sleep, $attempts, $cat, $article);
  my ($text, $line, %logicians, %mathematicians);
  
  @letters=("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z");

  #&wikipedia_login();
  $sleep = 5; $attempts=500; 

#   @cats = ("Category:Logicians", "Category:Logicians by nationality", "Category:American logicians", "Category:Austrian logicians", "Category:Brazilian logicians", "Category:British logicians", "Category:Bulgarian logicians", "Category:Chinese logicians", "Category:Czech logicians", "Category:Dutch logicians", "Category:German logicians", "Category:Greek logicians", "Category:Icelandic logicians", "Category:Indian logicians", "Category:Japanese logicians", "Category:Polish logicians", "Category:Russian logicians", "Category:English logicians");
#   &fetch_articles(\@cats, \@articles, \@new_cats);

#   foreach $cat (@new_cats){
# 	print "\"$cat\", ";
#   }
#   print "\n";

#   open(FILE, ">Logicians.txt");
#   foreach $article (@articles){
# 	print FILE "\* \[\[$article\]\]\n";
#   }
#   close(FILE);


  open(FILE, "<Mathematicians.txt");
  $text = <FILE>;
  close(FILE);
  foreach $line (split("\n", $text)){

	next unless ($line =~ /\*\s*\[\[(.*?)\]\]/);
	$article = $1;
	$article =~ s/\|.*?$//g;
	
	$article = &find_last($article);
	
	
	$line =~ s/\[\[([^\]]*?)\|(.*?)\]\]/\[\[$1\]\]/g;
	$mathematicians{$article} = $line; 

# 	print "$article $line\n";

  }

#  exit(0);
  
  open(FILE, "<Logicians.txt");
  $text = <FILE>;
  close(FILE);
  foreach $line (split("\n", $text)){
	next unless ($line =~ /\*\s*\[\[(.*?)\]\]/);
	$article = $1;
	next if ($article =~ /List/);

	$article = &find_last($article);
	
	if (! exists $mathematicians{$article} ){
	  print "Error. $article is not a mathematician.\n";
	  exit(0);
	}
	#$logicians{$article} = $mathematicians{$article};
	
#	print "$article\n";
  }


  open(FILE, "<List_of_logicians.wiki"); $text = <FILE>; close(FILE);
  my ($top, $bot);
  if ($text =~ /^(.*?)(\s*==.*?)(==External links==.*?)$/s){
	$top = $1; $text = $2; $bot = $3;
# 	print "$top\n";
# 	print "$bot\n";
  }else{
	print "Error. Can't match top and bottom.\n";
  }

  foreach $line (split("\n", $text)){
	next unless ($line =~ /\*\s*\[\[(.*?)\]\]/);
	$article = $1;
	$article =~ s/\|.*?$//g;
	
	$article = &find_last($article);

	print "$article\n";
	# overwrite with existing info from the list of logicians
	$logicians{$article} = $line;
#	print "$article\n";
  }

  my (%alpha_hash, $letter);

  foreach $letter (@letters){
	$alpha_hash{$letter} = "\n== $letter ==\n\n";
  }
  
  foreach $article (sort {$a cmp $b} keys %logicians){

	if ($article !~ /^(\w)/){
	  print "$article has an error!\n";
	  exit(0);
	}
	$letter = $1;
	#print "$letter $article\n";

	#$logicians{$article} =~ s/^\*\s*/\* /g; # put a space after the item
	$alpha_hash{$letter} .= $logicians{$article} . "\n";
  }

  open(FILE, ">List_of_logicians2.wiki");
  print FILE "$top\n";
  foreach $letter (@letters){
	print FILE $alpha_hash{$letter};
  }
  print FILE "\n$bot\n";
  close(FILE);
  
  
#   @articles_from_cats=&randomize_array(@articles_from_cats); # to later identify entries differning only by capitals

#   # articles which we will not allow in the math list for various reasons
#   &put_redlinks_on_blacklist($prefix, \@letters, \%blacklist);
#   &put_mathematicians_on_blacklist_and_user_selected_also(\%blacklist);
#   &put_redirects_on_blacklist(\%blacklist, $articles_from_cats_file, \@articles_from_cats);

#   # go letter by letter, and merge the new entries
#   foreach $letter (@letters){
#     $file = "$prefix ($letter).wiki"; 
  
#     $text=&fetch_file_nosave($file, $attempts, $sleep);  # fetch the lists from Wikipedia
#     exit (0) if ($text =~ /^\s*$/);                      # quit if can't get any of the lists 

#     # the heart of the code
#     $text = &merge_new_entries_from_categories($letter, $text, \@articles_from_cats, \%blacklist, \%all_articles);

#     $edit_summary="Daily update. See the log at [[User:Mathbot/Changes to mathlists]].";
#     &submit_file_nosave($file, $edit_summary, $text, $attempts, $sleep);
#   }

#   &post_newly_detected_categories(\@mathematics_categories, \@mathematician_categories, \@other_categories, \@new_categories);

#   # create the log of changes to the math articles. Merge with the changes to mathematician articles. Submit.
#   $todays_log=&process_log_of_todays_changes(\%all_articles, \%blacklist, $all_math_arts_file); # changes to the mathematics articles
#   open(FILE, "<$mathematicians_logfile"); $text=<FILE>; close(FILE);
#   $text =~ s/^==.*?==\s*//g; $text =~ s/(^|\n)(:.)/"$1: Mathematicians" . lc($2)/eg;
#   $todays_log = $todays_log . "----\n" . $text;
#   &merge_logs_and_submit($todays_log, $log_file);
# }

# # articles which we will not allow in the [[list of mathematics articles]]
# sub put_mathematicians_on_blacklist_and_user_selected_also {
#   my $blacklist=shift;
#   my ($line, @lines);

#   # read blacklist from file
#   open (FILE,  '<', "User:Mathbot/Blacklist.wiki");      @lines = split ("\n", <FILE>); close(FILE);
#   foreach $line (@lines) {
#     next unless ($line =~ /\[\[(.*?)\]\]/);
#     $line = $1; $line =~ s/^(.)/uc($1)/eg; # upcase
#     $blacklist->{$line}= '(is in [[User:Mathbot/Blacklist]])';
#   }

#   # blacklist the mathematicians (which already are in the [[list of mathematicians]]) 
#   open (FILE,  '<', "All_mathematicians.txt");  @lines = split ("\n", <FILE>);  close(FILE);
#   foreach $line (@lines) {
#     $blacklist->{$line}= '(is in the [[list of mathematicians]])';
#   }
# }

# # the heart of the code
# sub merge_new_entries_from_categories{

#   my ($link, $link_stripped, @links, %articles);
#   my ($letter, $text, $articles_from_cats, $blacklist, $all_articles)=@_;
#   @links=split("\n", $text); 
#   foreach $link (@links){
#     if ($link =~ /^\[\[(.*?)(\||\]\])/){ # extract the link
#       $link=$1;
#     }else{
#       $link="";
#     }
#   }
#   @links=(@links, @$articles_from_cats); # append the randomized @articles_from_cats to @links
  
#   # put into hash the entries starting with current letter
#   foreach $link (@links){
    
#     next if (exists $blacklist->{$link});  # don't add blacklisted items to the list of topics
#     next if ($link =~ /(talk|wikipedia|template|category|user):/i);  # ignore talk pages, templates, etc
#     next if ($link =~ /List of mathematics articles \(/i); # do not put links to lists themselves, that's stupid
#     next if ($link =~ /^\s*$/); # ignore empty links

#     # Get a copy of the link stripped of accents and non-alphanumberic. Will use it for sorting.
#     $link_stripped=decode("utf8", $link); $link_stripped = &strip_accents_and_stuff ($link_stripped); 
    
#     # now, do not deal with any articles except the current letter
#     if ($letter eq "0-9"){
#       next unless ($link_stripped =~ /^[0-9]/);
#     }else{
#       next unless ($link_stripped =~ /^$letter/i);
#     }
    
#     $articles{$link_stripped} = "\[\[$link\]\] \[\[Talk:$link\| \]\] -- "; # put them all in a hash
#     $all_articles->{$link}=1; # this will be exported out of this function
#   }
  
#   # split into sections and collect all data in $text
#   &split_into_sections (\%articles);
#   $text="__NOTOC__\n{{MathTopicTOC}}\n";
#   foreach (sort { $a cmp $b } keys %articles) {
#     $text = $text . $articles{$_} . "\n";
#   }
#   $text = $text . "\n[[Category:Mathematics-related lists|Mathematics $letter]]\n";
#   return $text;
# }

# sub post_newly_detected_categories {

#   my ($mathematics_categories, $mathematician_categories, $other_categories, $new_categories)=@_;
#   my (%current_categories, $text, $line, $mathematician_cat_list, $sleep, $attempts, $edit_summary, $file);

#   # add to the newly discovered mathematics categories the mathematician categories discovered when running that script
#   $mathematician_cat_list = "New_mathematician_categories.txt";
#   open (FILE, "<", $mathematician_cat_list); $text =  <FILE>; close(FILE);
#   @$new_categories = (@$new_categories, split ("\n", $text));

#   # current categories
#   foreach $line (@$mathematics_categories  ){ $current_categories{$line}=1;  }
#   foreach $line (@$mathematician_categories){ $current_categories{$line}=1;  }
#   foreach $line (@$other_categories        ){ $current_categories{$line}=1;  }

#   # see which of the @$new_categories are trully new
#   $text="";
#   foreach $line (@$new_categories){
#     next if ( exists $current_categories{$line} );
#     next unless ($line =~ /Category:/);
#     $text = $text . "\[\[:$line\]\] -- \n";
#   }

#   $file              = "User:Mathbot/New_math_categories.wiki";
#   $sleep = 5; $attempts=500;  $edit_summary="Today's new math categories.";
#   &submit_file_nosave($file, $edit_summary, $text, $attempts, $sleep);
# }

# sub merge_logs_and_submit{

#   my ($log_file, $todays_log, $combined_log, @days, $sleep, $attempts, $edit_summary);
#   ($todays_log, $log_file)=@_;
  
#   # Read in the log from previous days (from the disk), append to it today's log
#   open (FILE, "<$log_file"); $combined_log=<FILE>; close(FILE);
#   $combined_log =~ s/(^.*?\n)(==.*?)$/$1$todays_log\n$2/sg; # 

#   # keep only the last month or so
#   @days = split ("\n==", $combined_log);
#   @days = splice (@days, 0, 39);
#   $combined_log = join ("\n==", @days);

#   # submit the log file, and write the logfile back to disk (away from wikipedia vandals)
#   $sleep = 5; $attempts=500; $edit_summary="Today's changes to the [[list of mathematics articles]].";
#   &submit_file_nosave($log_file, $edit_summary, $combined_log, $attempts, $sleep);
#   open (FILE, ">$log_file"); print FILE "$combined_log\n"; close(FILE); # write new log to disk
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
  
  $last = decode("utf8", $last);
  $last = &strip_accents_and_stuff($last); # and strip accents
  
  return $last;
}


sub find_last {

  my $article = shift;

  $article =~ s/^.*? of \s*//g;
  $article = &get_last($article);
  $article = &strip_last($article);
  $article=decode("utf8", $article);
  $article = &strip_accents_and_stuff ($article);
  
  return $article;
}
