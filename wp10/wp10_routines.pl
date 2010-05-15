#!/usr/bin/perl -w

use lib $ENV{HOME} . '/public_html/cgi-bin/wp/modules'; # path to perl modules

use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Encode;
#use Perlwikipedia;
use HTML::Entities;

use Data::Dumper;

use lib '/home/oleg/public_html/cgi-bin/wp/wp10';
use lib '/home/oleg/public_html/cgi-bin/modules';

require 'bin/fetch_articles_cats2.pl';  # Most of the API interface is here
require 'bin/html_encode_decode_string.pl';
require 'bin/get_html2.pl';              # Should be reworked
require 'bin/language_definitions.pl';
require 'bin/rm_extra_html.pl';
require 'bin/wikipedia_submit.pl';
require 'bin/watchdog_file.pl';

undef $/;      # undefines the separator. Can read one whole file in one scalar.

###
# Make STDOUT unbuffered and encoded in utf8
select STDOUT;
$| = 1;
binmode STDOUT, ":utf8"; 

# debugging variable
my $fetchedNames = 0;

# Global variables, to not carry them around all over the place.
# Notice the convention, all global variables start with a CAPITAL letter.

# Language specific stuff. See the module "bin/language_definitions.pl"
# These definitions will be helpful for any Wikipedia project, not just for Wikipedia 1.0
my %Dictionary   = &language_definitions();
my $Lang         = $Dictionary{'Lang'};
my $Talk         = $Dictionary{'Talk'}; 
my $Category     = $Dictionary{'Category'};
my $Wikipedia    = $Dictionary{'Wikipedia'};
my $WikiProject  = $Dictionary{'WikiProject'};
my $WP           = $Dictionary{'WP'};
my $Wiki_http    = 'http://' . $Lang . '.wikipedia.org';

# More language specific stuff. These are keywords for this particular Wikipedia 1.0 script
# that's why they are not in the module "bin/language_definitions.pl"
# which is only for general keywords

# all the categories the bot will search will be subcategories of the the category below
my $Root_category= $Category . ':' . $Wikipedia . ' 1.0 assessments'; 

# all bot pages will be subpages of the page below
my $Editorial_team = $Wikipedia . ':Version 1.0 Editorial Team';

my $Index = 'Index';

# The bot will write an index of all generated lists to $Index_file
my $Index_file= $Editorial_team . '/' . $Index . '.wiki';

# a keyword used quite often below
my $Bot_tag='<!-- bottag-->';

# Other words which need translation
my $Statistics = 'Statistics';
my $Log = 'Log';
my $By_quality = 'by quality';
my $By_importance = 'by importance';
my $Comments = 'Comments';
my $With_comments = 'with comments';
my $Edit_comment = 'edit comment';
my $See_also = "See also";
my $Total = 'Total';
my $No_changes_message = ":'''(No changes today)'''"; # in the log
my $All_projects = 'All projects';
my $Quality_word = 'Quality'; # so that it does not conflict with %Quality below
my $Importance_word = 'Importance'; # so that it does not conflict with %Importance below

my $Class = 'Class';
my $No_Class = 'No-Class';
my $Unassessed_Class = 'Unassessed-Class';
my $Assessed_Class = 'Assessed-Class';

# The quality and importance ratings.
# The two hashes below must have different keys!

my %Quality=('FA-Class' => 1, 'FL-Class' => 2, 'A-Class' => 3, 'GA-Class' => 4, 'B-Class' => 5,
             'C-Class' => 6, 'Start-Class'=>7, 'Stub-Class' => 8, 'List-Class' => 9, $Assessed_Class => 10,
             $Unassessed_Class => 11); # If update here, also update &extra_categorizations below

#my %Quality=('FA-Class' => 1, 'A-Class' => 2, 'GA-Class' => 3, 'B-Class' => 4,
#             'Start-Class' => 5, 'Stub-Class' => 6, $Assessed_Class => 7, 'List-Class' => 8,
#             $Unassessed_Class => 9); # If update here, also update &extra_categorizations below

my %Importance=('Top-Class' => 1, 'High-Class' => 2, 'Mid-Class' => 3,
	       'Low-Class' => 4, $No_Class => 5); # If update here, also update &extra_categorizations below

my  @Months=("January", "February", "March", "April", "May", "June",
	     "July", "August",  "September", "October", "November", "December");


# Constants needed to fetch from server and submit back
my $Sleep_fetch  = 1;
my $Sleep_submit = 5;
my $Attempts     = 1000;

# A directory on disk where the bot will store a list of all assessed
# articles together with their ratings and revision ids. This is
# needed for backup purposes and to calculate the statistics (see more
# below). Create this directory or else the bot will refuse to run.
my $Storage_dir;

# Continued from the previous paragraph, if an article went missing
# from the list of assessed articles, keep its info on disk for
# $Number_of_days. This makes it possible to recover that article if
# the reason it went missing was because of vandalism or due to the
# bot mal-functioning.
my $Number_of_days = 9; 

# The information stored in $Storage_dir is used to compute the global
# stats. As such, the stats computed this way will be a bit larger
# than it should be, since it will also count articles which may have
# been removed on Wikipedia in the last $Number_of_days.

my $Separator = ' -;;- '; # Used to separate fields in lines in many places


## Used to keep track of elapsed running time; timestamp when script starts
my $Init_time = time();


######################################################################

sub main_wp10_routine {
  
  my (@projects, @articles, $text, $file, $project_category, $edit_summary);
  my (%old_arts, %new_arts, $art, %wikiprojects, $art_name, $date, $dir);
  my (%stats, %logs, %lists);
  my (@breakpoints, $todays_log, $front_matter, %repeats, %version_hash);
  my ($run_one_project_only, %map_qual_imp_to_cats, $stats_file);
  my (%project_stats, %global_stats, $global_flag, $done_projects_file);

  create_watchdog_file();
  
  if ($ENV{HOME}){
     $Storage_dir = $ENV{HOME} . "/wp10.b/";
  }else{
    $Storage_dir = "/tmp/wp10/"; 
  }
  print "<br/><br/>\n\nWill back up the data in $Storage_dir<br/><br/>\n\n";

  # go to the working directory
  $dir=$0; $dir =~ s/\/[^\/]*$/\//g; chdir $dir;

  if ( -e '/home/oleg/run/stop') {
    print "<font color=red>Bot down for maintanance for half a day. Please come back later. </font>\n"; exit(0);
  }


  # see if to run just one project or all of them
  $run_one_project_only=""; if (@_) { $run_one_project_only = shift};

  # base-most stuff
  &fetch_quality_categories(\@projects);
  &update_index(\@projects, \%lists, \%logs, \%stats, \%wikiprojects);

  # Go through @projects in the order of projects not done for a while get done first
  print "Now in $dir\n";
  $done_projects_file='Done_projects.txt'; 
  
  &decide_order_of_running_projects(\@projects, $done_projects_file);
     
  if ($Lang eq 'en'){
    # need this because the biography project takes much, much more time than others
    &put_biography_project_last (\@projects);
  }

  # go through a few categories containing version information (optional)
  &read_version (\%version_hash);

  # Go through all projects, search the categories in there,
  # and merge with existing information.

  my $t = scalar @projects;
  my $i = 0;
  foreach $project_category ( @projects ){

    if ( ! $run_one_project_only) { 
      $i++;
      print "<br/>\n<br/>\n";
      print   "---------------- $project_category <br/>\n";
      print   "---------------- $i/$t <br/>\n";
      printf  "---------------- Elapsed %2.2f hours <br/>\n",  
                                        (time() - $Init_time) / 3600;
      print "<br/>\n<br/>\n";
    } 

    # if told to run just one project, ignore the others
    next if ($run_one_project_only && 
             $project_category !~ /\Q$run_one_project_only\E/i);

    # Exit if for some reason the routine reading categories fails.
    # This is basically a hack.
    if ($Lang eq 'en'){
      &check_for_errors_reading_cats();
    }

    $date=&current_date();
    
    # read existing lists into %old_arts
    $file = $lists{$project_category};
    print "File: '$file'\n";
    die if ( ! defined $file);
    ($text, $front_matter)=&fetch_list_subpages($file, \@breakpoints);
    &extract_assessments ($project_category, $text, \%old_arts); 

    # Collect new articles from categories, in %new_arts.
    &collect_new_from_categories ($project_category, $date, \%new_arts,
                                  \%map_qual_imp_to_cats); 

    # Calculate the statistics and print the results in a table.
    # The calculation must happen before merging below,
    # as there unassessed biography articles will be removed.
    $file=$stats{$project_category};
    $global_flag = 0; # Here, calc the stats for current project only, not the global stats
    &calc_stats(\%new_arts, \%project_stats, $global_flag, \%repeats);
    $text = &print_stats($project_category, \%map_qual_imp_to_cats, \%project_stats)
       . &print_current_category($project_category);
    &wikipedia_submit2($file, "$Statistics for $date (test code)", $text);

    # the heart of the code, compare %old_arts and %new_arts, merge some info
    # from old into new, and generate a log
    $file = $lists{$project_category};
    $todays_log = &compare_merge_and_log_diffs($date, $file, $project_category,
                                               \%old_arts, \%new_arts, \%version_hash);

    # Submit the collected information to update the relevant Wikipedia pages
    &split_into_subpages_maybe_and_submit ($file, $project_category, $front_matter,
              $wikiprojects{$project_category}, $date, \@breakpoints, \%new_arts);

    &process_submit_log($logs{$project_category}, $todays_log, $project_category, $date);

    &mark_project_as_done($project_category, $done_projects_file);

    open DEBUG, ">>/home/oleg/wp10.b/Debug.$$";
    print DEBUG "\n\n----- ads243 $project_category\n";
    print DEBUG "---- old_arts\n";
    print DEBUG Dumper(%old_arts);
    print DEBUG "\n---- new_arts\n";
    print DEBUG Dumper(%new_arts);
    close DEBUG;

  }

  # don't compute the total stats if the script was called just for one project
  return if ($run_one_project_only);

  # Calc the global stats (reading from disk is not the only way, see inside the code below).
  &calc_global_stats_by_reading_from_disk (\@projects, \%lists, \%global_stats);
  $stats_file = $Editorial_team . '/' . $Statistics . '.wiki';
  &submit_global_stats ($stats_file, \%global_stats, $date, $All_projects);
  
  # Make Category:FA-Class physics articles a subcat in Category:FA-Class articles
  # if not there yet, and so on. Do this only in the English Wikipedia
  # (this function is not that necessary and will be hard to adapt to non-English)
  if ($Lang eq 'en'){
    &extra_categorizations();
  }

  print "\n";
  print   "--------------- Finished.<br/>\n";
  printf  "--------------- Running time: %2.2f hours <br/>\n",  
                                       (time() - $Init_time) / 3600;

  remove_watchdog_file();
}

######################################################################
sub fetch_quality_categories{

  my ($projects, $cat, @tmp_cats, @tmp_articles);
  
  $projects = shift;

  # fetch all the subcategories of $Root_category
  &fetch_articles_cats($Root_category, \@tmp_cats, \@tmp_articles);

  # put in @$projects only the categories by quality
  @$projects=(); 
  foreach $cat (sort {$a cmp $b}  @tmp_cats){
    next unless ($cat =~ /^(.*?) \Q$By_quality\E/);

    if ($Lang eq 'en'){
      next if ($cat =~ /\Q$Category\E:Articles \Q$By_quality\E/); # silly meta category
    }
    
    push (@$projects, $cat);
  }
}

######################################################################
# Create a hash of hashes containing the files the bot will write to, and some
# other information. Keep that hash of hashes on Wikipedia as an index.
sub update_index{

  my ($category, $text, $text2, $file, $line, $list, $stat, $log, $short_list, $preamble, $bottom);
  my ($wikiproject, $count, %sort_order, $iter);
  my ($projects, $lists, $logs, $stats, $wikiprojects)=@_;

  # will split the index into two pages, as it is too big currently
  my $index2 = $Index_file;
  $index2 =~ s/Index/Index2/i;

  # fetch existing index, read the wikiprojects from there (need that as names of wikiprojects can't be generated)

  # save preamble for the future
  $text = wikipedia_fetch2($Index_file, $Attempts, $Sleep_fetch);

  if ($text =~ /^(.*?$Bot_tag.*?\n)(.*?)($Bot_tag.*?)$/s){
    $preamble=$1; $text=$2; $bottom=$3;
  } else{
    $preamble = $Bot_tag; $bottom = $Bot_tag; 
  }

  $text = $text . "\n" . wikipedia_fetch2($index2, $Attempts, $Sleep_fetch);

  foreach $line (split ("\n", $text) ){
    next unless ($line =~ /\[\[:(\Q$Category\E:.*?)\|.*?\[\[(\Q$Wikipedia\E:.*?)\|/);
    $wikiprojects->{$1}=$2;
  }

  # generate names for the files the bot will write to
  foreach $category (@$projects){

    $file =$category; $file =~ s/^\Q$Category\E://ig; $file = $Editorial_team . '/' . $file . '.wiki';
    $lists->{$category}=$file;

    $file =~ s/\.wiki/" " .  lc($Statistics) . ".wiki"/eg;     $stats->{$category}=$file;
    $file =~ s/\Q$Statistics\E\.wiki/lc($Log) . ".wiki"/eig;   $logs->{$category}=$file;

    $wikiprojects->{$category}=&get_wikiproject($category) unless (exists $wikiprojects->{$category});

    if ($Lang eq 'en'){
      $file =~ s/^.*?\///g; $file =~ s/^The\s+//ig; # sort by ignoring leading "The"
    }
    $sort_order{$category}=$file;
  }

  # put that data in a index of projects and submit to Wikipedia.
  $text = "";
  $text2 = ""; 
  $iter = 0;

  foreach $category (sort {$sort_order{$a} cmp $sort_order{$b}} keys %sort_order){
    
    $list        = $lists->{$category};         $list =~ s/\.wiki//g; $list =~ s/_/ /g;
    $stat        = $stats->{$category};         $stat =~ s/\.wiki//g; $stat =~ s/_/ /g;
    $log         = $logs->{$category};          $log  =~ s/\.wiki//g; $log  =~ s/_/ /g;
    $wikiproject = $wikiprojects->{$category};
       
    $short_list = $list; $short_list =~ s/^.*\///g; 
    $line = "\| \[\[$list\|$short_list\]\] \|\| "
       . "\(\[\[$stat\|" . lc($Statistics) . "\]\], \[\[$log\|" . lc($Log) . "\]\], "
          . "\[\[:$category\|" . lc($Category) . "\]\], \[\[$wikiproject\|" . lc($WikiProject) . "\]\]\)\n\|\-\n";

    $iter ++;
    if ($iter < 800){ # put a bunch of projects in first page, and the rest in second page
       $text = $text . $line;
    }else{
       $text2 = $text2 . $line;
    }

#    $text = $text . "\| \[\[$list\|$short_list\]\] \|\| "
#       . "\(\[\[$stat\|" . lc($Statistics) . "\]\], \[\[$log\|" . lc($Log) . "\]\], "
#	  . "\[\[:$category\|" . lc($Category) . "\]\], \[\[$wikiproject\|" . lc($WikiProject) . "\]\]\)\n\|\-\n";
  }

  my $index_strip = $Index_file; $index_strip  =~ s/\.wiki//; # rm extension
  my $index2_strip = $index2;    $index2_strip =~ s/\.wiki//; # rm extension
  $count=scalar @$projects;

  $text = $preamble 
	. "Currently, there are $count participating projects.\n\n" 
        . "\{\| class=\"wikitable\"\n"
        . $text . "\|\}\n"
        . "Index continued at [[$index2_strip]].\n"  
	. $bottom;

  $text2 = "Index continued from [[$index_strip]].\n"  
        . "\{\| class=\"wikitable\"\n"
        . $text2 . "\|\}\n";

  &wikipedia_submit2($Index_file, "Update index (test code)", $text);
  &wikipedia_submit2($index2, "Update second part of index (test code)", $text2, $Attempts, $Sleep_submit);

#  exit;
}

######################################################################
sub read_version{

  print "<font color=red>I have to read <b>all</b> version 0.5 and 1.0 "
      . "articles before proceeding with your request. Be patient. </font><br/><br/>\n";

  my ($version_hash, %cats_hash, $cat, $subcat, @subcats, @all_subcats, $article, @articles);
  $version_hash = shift;

  # this may not be necessary on non-English Wikipedias, at least not to start with.
  # The bot will just ignore these categories if they don't exist.
  %cats_hash=($Category  . ":Version 0.5 Nominees"              => "0.5 nom",
	      $Category  . ":Wikipedia Version 0.5"             => "0.5",
	      $Category  . ":Wikipedia Version 1.0"             => "1.0",
	      #$Category . ":Wikipedia:Version 1.0 Nominations" => "1.0 nom"
	     );

  # go through all categories in %cats_hash and do threee things:
  # 1. collect all subcategories
  # 2. Let each subcategory inherit the version from the parent category.
  # 3. Same for each article
  
  foreach $cat (keys %cats_hash){
    &fetch_articles_cats($cat, \@subcats, \@articles);
    
    push (@all_subcats, @subcats);
    
    foreach $subcat (@subcats){
      $cats_hash{$subcat} = $cats_hash{$cat} if ( exists $cats_hash {$cat} ); # inherit parent's version
    }

    foreach $article (@articles){
      next unless ($article =~ /^\Q$Talk\E:(.*?)$/);
      $article = $1;
      $version_hash->{$article} = $cats_hash{$cat} if ( exists $cats_hash {$cat} ); # inherit parent's version
    }
  }

  # one more level, let the articles in the subcats also inherit the version
  foreach $cat (@all_subcats){
    
    &fetch_articles_cats($cat, \@subcats, \@articles);
    
    foreach $article (@articles){
      next unless ($article =~ /^\Q$Talk\E:(.*?)$/);
      $article = $1;
      $version_hash->{$article} = $cats_hash{$cat} if ( exists $cats_hash {$cat} ); # inherit parent's version 
    }
  }

  print "<font color=red>Done reading all version articles. Will proceed to your request.</font><br/><br/>\n";

}

######################################################################
# fetch given list. If it has subpages, fetch those too. Put into one big $text variable.
sub fetch_list_subpages{

  my ($file, $breakpoints, $text, $front_matter, $base_page, @subpages, $subpage, $subpage_text, $line);

  $file=shift; $breakpoints=shift; 

  @$breakpoints=();

  $text = wikipedia_fetch2($file, $Attempts, $Sleep_fetch);
 
  if ($text =~ /^(.*?$Bot_tag.*?\n)/s){
    $front_matter=$1;
  }else{
    $front_matter  =""; # will fill it in later
  }

  $base_page=$file; $base_page =~ s/\.wiki//g;
  @subpages = ($text =~ /\[\[(\Q$base_page\E\/\d+)[\|\]]/g); #must use \Q and \E since $base_page can have special chars

  if ( scalar @subpages > 0) { 
    print "Getting source code for " . (scalar @subpages) . " pages\n";
    my $data = fetch_content(\@subpages);

    foreach $subpage (@subpages){ 
      $text = $text . "\n" . $data->{$subpage};
    
      if ($data->{$subpage} =~ /^.*\{\{assessment\s*\|\s*page\s*=\s*\[\[(.*?)\]\]/s){
        push (@$breakpoints, $1); # will need the breakpoints when updating the subpages.
      }
    }
  }
  return ($text, $front_matter);
}

######################################################################
# given the $text read from the list and it subpages, parse it and put the info in a hash
sub extract_assessments{

  my ($project_category, $arts, $line, $art, $file, $text, $talkpage);
  $project_category=shift; $text = shift; $arts = shift; 
  
  %$arts=(); # blank the hash, and populate it
  foreach $line (split ("\n", $text)) {

    next unless ($line =~
  		 /\{\{assessment\s*\|\s*page=(.*?)\s*\|\s*importance=(.*?)\s*\|\s*date=(.*?)\s*\|\s*class=\{\{(.*?)\}\}\s*\|\s*version=(.*?)\s*\|\s*comments=(.*)\s*\}\}/i); # MUST have a greedy regex at comments!
    
    $art = article_assesment->new();
    $art->{'name'}=$1;
    $art->{'importance'}=$2;
    $art->{'date'}=$3;
    $art->{'quality'}=$4;
    $art->{'version'}=$5;
    $art->{'comments'}=$6;

    $art->{'quality'} = $Unassessed_Class if ( !exists $Quality{ $art->{'quality'} } ); # default

    $art->{'importance'} =~ s/\{\{(.*?)\}\}/$1/g; # rm braces, if any
    $art->{'importance'} = $No_Class if ( !exists $Importance{ $art->{'importance'} } ); # default value
    
    $art->{'date'} =~ s/[\[\]]//g; # rm links from dates

    # this is necessary as some articles may also have an external link next to them, pointing to a specific version
    if ($art->{'name'} =~ /\[\[(.*?)\]\]\s*\[(http:\/\/.*?)\s*\]/){
      $art->{'name'}=$1;
      $art->{'hist_link'}=$2;
    }else{
      $art->{'name'} =~ s/^\s*\[\[(.*?)\s*\]\].*?$/$1/g; # [[name]] -> name
      $art->{'hist_link'}="";
    }
    
    next if ($art->{'name'} =~ /^\s*$/);
    $arts->{$art->{'name'}}=$art;
  }
}

######################################################################
# Read the quality, importance, and comments categories into %$new_arts. 
# Later that will be merged with the info already in the lists
sub collect_new_from_categories {

  my (@cats, @dummy, @articles, $article, $wikiproject, $new_arts, $art, $cat, @tmp, $counter);
  my ($project_category, $importance_category, $date, $qual, $imp, $comments_category, $map_qual_imp_to_cats);

  $project_category=shift; $date = shift; $new_arts=shift; $map_qual_imp_to_cats = shift;

  # blank two hashes before using them
  %$new_arts = (); 
  %$map_qual_imp_to_cats = (); 
  
  # $project_category (e.g., "Chemistry articicles by quality") contains subcategories of each quality.
  # Read them and the articles categorized in them.  
  &fetch_articles_cats($project_category, \@cats, \@articles); 

  # go through each of the FA-Class, A-Class, etc. categories and read their articles
  foreach $cat (@cats) {

    next unless ($cat =~ /\Q$Category\E:(\w+)[\- ]/);
    $qual=$1 . '-' . $Class; # e.g., FA-Class

    # ignore categories which do not correspond to any quality rating
    next unless (exists $Quality{$qual});

    # will need this map when counting how many articles of each type we have
    $map_qual_imp_to_cats->{$qual} = $cat;

#    open DEBUG, ">>Data";
#    binmode DEBUG, ":utf8";

    # collect the articles
    &fetch_articles_cats($cat, \@dummy, \@articles); 
    foreach $article (@articles) {
#      print DEBUG "$cat -- $article \n";
      next unless ($article =~ /^\Q$Talk\E:(.*?)$/i);
      $article = $1;
#      print DEBUG "\t$article \n";

      # store all the data in an an object
      $new_arts->{$article}=article_assesment->new();

      $new_arts->{$article}->{'name'}=$article;
      $new_arts->{$article}->{'date'}=$date;
      $new_arts->{$article}->{'quality'}=$qual;
    }
  }

#  close DEBUG;

  # look in $importance_category, e.g., "Chemistry articles by importance", read its subcategories,
  # for example, "Top chemistry articles", etc.
  $importance_category=$project_category; $importance_category =~ s/\Q$By_quality\E/$By_importance/g;
  &fetch_articles_cats($importance_category, \@cats, \@articles); 

  # for political reasons, the "by importance" category is called "by priority" by some projects,
  # so check for this alternative name if the above &fetch_articles_cats returned empty cats
  if ( $Lang eq 'en' && (!@cats) ){
    $importance_category =~ s/ \Q$By_importance\E/ by priority/g;
    &fetch_articles_cats($importance_category, \@tmp, \@articles); 
    @cats = (@cats, @tmp);
  }

  # go through all the importance categories thus found
  foreach $cat (@cats){

    next unless ($cat =~ /\Q$Category\E:(\w+)[\- ]/);
    $imp=$1 . '-' . $Class; # e.g., Top-Class

    # alternative name for the unassessed importance articles, only on the English Wikipedia
    if ($Lang eq 'en'){
      $imp = $No_Class if ($imp eq 'Unknown-Class' || $imp eq $Unassessed_Class ||  $imp eq 'Unassigned-Class');
    }

    # ignore categories which do not correspond to any quality rating
    next unless (exists $Importance{$imp});
    
    # will need this map when counting how many articles of each type we have
    $map_qual_imp_to_cats->{$imp} = $cat;

    # No point in fetching the contents of the unassessed importance categories.
    # That's because the articles have unassessed importance by default anyway.
    next if ($imp eq $No_Class);

    # collect the importance ratings
    &fetch_articles_cats($cat, \@dummy, \@articles); 
    foreach $article (@articles){
      next unless ($article =~ /^\Q$Talk\E:(.*?)$/i);
      $article = $1;
      
      next unless exists ($new_arts->{$article}); # if an article's quality was not defined, ignore it
      $new_arts->{$article}->{'importance'}=$imp;
    }
  }
  
  # Fill in the comment field, for articles which are in a category meant
  # to show that there is a comments subpage
  $comments_category=$project_category;
  $comments_category =~ s/\Q$By_quality\E/$With_comments/g;
  &fetch_articles_cats($comments_category, \@cats, \@articles); 
  
  foreach $article (@articles) {
    next unless ($article =~ /^\Q$Talk\E:(.*?)$/);
    $article = $1;
    
    next unless exists ($new_arts->{$article}); # guards against strange undefined things
    
    $new_arts->{$article}->{'comments'}= '{{' . $Talk . ':' . $article . '/' . $Comments . '}}' 
       . ' ([' . $Wiki_http . '/w/index.php?title=' . $Talk . ':'
	  . &html_encode_string($article) . '/' . $Comments. '&action=edit ' . $Edit_comment . '])';
  }
}

######################################################################
# the heart of the code
sub compare_merge_and_log_diffs {

  my ($date, $list_name, $project_category, $old_arts, $new_arts, $version_hash) =@_;
  my ($log_text, $line, $art, $article, $latest_old_ids, $sep, $old_ids_on_disk);
  my ($old_ids_file_name, $text, $new_name);

  # the big loop to collect the data and the logs
  $log_text="===$date===\n";

  # Read old_ids from disk. That info also exists in the Wikipedia lists themselves,
  # but if the bot misbehaved or if the server had problems, or if there was vandalism,
  # all in the last few days, it may have been lost. 
  $sep = ' ;; ';
  $old_ids_on_disk = {}; # empty hash for now

  $old_ids_file_name = &list_name_to_file_name ($list_name);
  &read_old_ids_from_disk ($old_ids_on_disk, $old_ids_file_name, $sep);
  
  # identify entries which were removed from categories
  # (entries in $old_arts which are not in $new_arts)
  foreach $article ( sort { &cmp_arts($old_arts->{$a}, $old_arts->{$b}) } keys %$old_arts) {
    if (! exists $new_arts->{$article}) {

      # see if perhaps the article got moved, in that case,
      # transfer the info and note this in the log
      $new_name = &hist_link_to_article_name ($old_arts->{$article}->{'hist_link'});

      if ($new_name !~ /^\s*$/ && ( !exists $old_arts->{$new_name} ) && ( exists $new_arts->{$new_name}) ){
        
        # so, it appears indeed that the article got moved
        
        # Pretend that $new_name exited before, so that later the info
        # of $old_arts->{$article} may be copied to $new_arts->{$new_name}
        $old_arts->{$new_name} = $old_arts->{$article};
        
        # replace the title in the hist_link (this has no effect on the validity
        # of the hist_link, it looks better to humans though)
        if ($old_arts->{$new_name}->{'hist_link'}
            =~ /^(.*?\/w\/index\.php\?title=).*?(\&oldid=.*?)$/i) {
          
          $old_arts->{$new_name}->{'hist_link'}
             =  $1 .  &html_encode_string($new_name) . $2;
        }
        
        #note the move in the log
        $line = "\* '''" . &arttalk ($old_arts->{$article})
           . " renamed to \[\[" . $new_name . "\]\]'''\n";
        $log_text = $log_text . $line;
        
      }else{

        # So it was not a move, but a plain removal. Record that in the log.
        $line = "\* '''" . &arttalk ($old_arts->{$article}) . " removed.'''\n";
        $log_text = $log_text . $line; 
      }
    }
  }
  
  # identify entries which were added, copy some info from old to new, and log all changes
  foreach $article ( sort { &cmp_arts($new_arts->{$a}, $new_arts->{$b}) } keys %$new_arts){

    # a dirty trick needed only on the English Wikipedia
    if ($Lang eq 'en'){

      # This is making the code a bit more complicated, but is necessary.
      # Count (done already), but do not list unassessed biography articles,
      # as they are just too many (over 400,000).
      if ($project_category eq "Category:Biography articles by quality"
          && $new_arts->{$article}->{'quality'} eq $Unassessed_Class){
        delete $new_arts->{$article};
        next;
      }
    }
    
    # add version information (0.5, 0.5 nom, 1.0, or 1.0 nom)
    $new_arts->{$article}->{'version'} = $version_hash->{$article}
       if (exists $version_hash->{$article});

    # Found a new article. deal with its old_id, and record its appearance in the log
    if (! exists $old_arts->{$article}) {

      # If the old_id of the current article exists on disk, it means that the current
      # article is not truly new, it was in the list in the last few days and then
      # it vanished for some reason (bot or server problems).
      # So recover its hist_link and date from its old_id stored on disk
      # assuming that its quality did not change in between.
      
      if (  exists $old_ids_on_disk->{$article}->{'old_id'} 
	   && $old_ids_on_disk->{$article}->{'quality'} eq $new_arts->{$article}->{'quality'} ){

        # the hist_link is obtained from old_id by completing the URL
        $new_arts->{$article}->{'hist_link'} =
           &old_id_to_hist_link ($old_ids_on_disk->{$article}->{'old_id'}, $article);
        
        # and copy the date too
        $new_arts->{$article}->{'date'} = $old_ids_on_disk->{$article}->{'date'};
        
      }else{
        # If the new article is truly new, we need to do a query to get its hist_link.
        # Do it later for a chunck of articles at once, it is faster that way.
        # So, add it in the pipeline $latest_old_ids
        $latest_old_ids->{$article} = "";
      }
      
      # Note in the log that the article was added
      $line = "\* " . &arttalk($new_arts->{$article}) . " added.\n";
      $log_text = $log_text . $line;
      next;
    }
    
    # From here on we assume that the article is not new, but its info may have changed.
    # Copy as much as possible from $old_arts and update some things.

    # copy the hist link
    $new_arts->{$article}->{'hist_link'}=$old_arts->{$article}->{'hist_link'}
       if ($old_arts->{$article}->{'hist_link'});
    
    # If Assessment did not change, then no log. Just copy the old date and move on.
    if ($new_arts->{$article}->{'quality'} eq $old_arts->{$article}->{'quality'}
	&& $new_arts->{$article}->{'importance'} eq $old_arts->{$article}->{'importance'}) {
      
      $new_arts->{$article}->{'date'}=$old_arts->{$article}->{'date'};  
      next;
    }
    
    # copy the old date if just importance changed
    if ($new_arts->{$article}->{'quality'} eq $old_arts->{$article}->{'quality'}){
      $new_arts->{$article}->{'date'}=$old_arts->{$article}->{'date'};
    }
    
    # if the article quality improved (smaller quality value), link to the latest entry in history
    if ($Quality{$new_arts->{$article}->{'quality'}} < $Quality{$old_arts->{$article}->{'quality'}}) {
      print "Assesment improved for \[\[$article\]\].<br/>\n";
      $latest_old_ids->{$article} = ""; # will fill that in later
    }

    # create a line to record the change to the article
    $line = "\[\[$article\]\] reassessed from "
       . "$old_arts->{$article}->{'quality'} \($old_arts->{$article}->{'importance'}\) "
	  . "to $new_arts->{$article}->{'quality'} \($new_arts->{$article}->{'importance'}\)";

    # if the article quality changed a lot, boldify $line 
    if ($Quality{$old_arts->{$article}->{'quality'}} - $Quality{$new_arts->{$article}->{'quality'}} > 1  ||
	$Quality{$old_arts->{$article}->{'quality'}} - $Quality{$new_arts->{$article}->{'quality'}} < -1 ||
	$Importance{$old_arts->{$article}->{'importance'}} - $Importance{$new_arts->{$article}->{'importance'}} > 1  ||
	$Importance{$old_arts->{$article}->{'importance'}} - $Importance{$new_arts->{$article}->{'importance'}} < -1 ){

      $line = "\'\'\'" . $line . "\'\'\'";
    }

    #add $line to the log
    $line = "* " . $line . "\n";
    $log_text = $log_text . $line;
  }

  # fill in the most recent history link for articles which are new 
  # or changed the assessment for the better
  &most_recent_history_links_query ($new_arts, $latest_old_ids);

  # Merge info from $new_arts to $old_ids_on_disk, and write to disk.
  # That info may be used if articles together
  # with the old_ids vanish from Wikipedia lists
  # in the next few days due to bot or server problems
  &write_old_ids_on_disk($new_arts, $old_ids_on_disk, $old_ids_file_name, $sep);

  return $log_text;
}

######################################################################
# Create the name of a file where will store information. 
# See the top of the code for why.
sub list_name_to_file_name {

  my $file_name = shift;
  
  $file_name =~ s/^.*\///g;
  
  # html_encode_decode string, among other things, converts slashes (/) to stuff like %22.
  # This avoids the creation of a subdirectory
  $file_name = &html_encode_string ($file_name);

  $file_name = $Storage_dir . $file_name;
  $file_name =~ s/\.wiki$//g; 
  $file_name = $file_name . "_old_ids";

  return $file_name;
}  

######################################################################
sub split_into_subpages_maybe_and_submit {

  my ($global_count, @count, $subpage_no, $subpage_file, @lines, $line);
  my ($subpage_frontmatter, @subpages, $re_login_flag, $edit_sum);
  my ($max_pagesize, $min_pagesize, $name, $mx, $mn, $base_page, $i, $iplus, $text);
  my ($file, $project_category, $front_matter, $wikiproject, $date, $breakpoints,
      $new_arts)=@_;

  $max_pagesize=500; $min_pagesize=400;
  $base_page=$file; $base_page =~ s/\.wiki//g;
  $front_matter=&print_main_front_matter() if (!$front_matter || $front_matter =~ /^\s*$/);
  
  # lots of things to initialize
  $global_count=0; $subpage_no=0; @count=(0); 
  @$breakpoints=(@$breakpoints, "", ""); # don't complain about not beining initialized

  # @subpages will be an array of array references. 
  # Each $subpages[$i] is an array of text lines that get catenated to page that subpage
  @subpages=( [] );   
  
  # Sort the articles at the start, to avoid redundant sorts later
  my @list = sort { &cmp_arts($new_arts->{$a}, $new_arts->{$b}) } keys %$new_arts;

  # see if to split into subpages at all, and if current breakpoints
  # still make the pages small
  foreach $name ( @list) {
    $line=&print_object_data ($new_arts->{$name});
    next unless ($line =~ /\{\{assessment\s*\|\s*page\s*=\s*\[\[.+?\]\]/);

    push @{$subpages[$subpage_no]}, $line;
    $global_count++; 
    $count[$subpage_no]++; # increment all

    if ($breakpoints->[$subpage_no] eq $name){ # reached a breakpoint, create a new subpage
      $subpage_no++; 
      push @subpages, [];
      push @count, 0;
    }
  }

  $edit_sum = "Update for $date (test code)";

  # if decided not to split into subpages, just submit the text and return 
  if ($global_count <= $max_pagesize){ #don't split into subpages
    print "Only $global_count articles. Won't split into subpages!<br/>\n";
   
    $text = "";
    for ( $i = 0; $i < scalar @subpages; $i++) { 
      $text .= join "", @{$subpages[$i]};
    }

    $text = $front_matter
       . &print_table_header($project_category, $wikiproject)
	   . $text
	   . &print_table_footer($date, $project_category)
	   . &print_current_category ($project_category);

    &wikipedia_submit2($file, $edit_sum, $text);
    return;
  }


  print "Subpage count: $subpage_no\n";

  # see what is the smallest number of entries in a subpage
  # (not counting the last one which may be small)
  $mn=$min_pagesize;
  for ($i=0 ; $i <=$subpage_no-2 ; $i++){
    $mn = $count[$i] if ($mn > $count[$i]);
  }
  
  # see if it is possible to add the last subpage to the one before it
  # (the last subpage may be small)
  if ($subpage_no >= 1 
       && $count[$subpage_no-1] + $count[$subpage_no] <= $max_pagesize 
       && $count[$subpage_no] > 0) {

    print "Add last subpage to previous one...\n";

    $subpages[$subpage_no-1] = 
        [ @{$subpages[$subpage_no-1]} , @{$subpages[$subpage_no]}];
    $subpages[$subpage_no]= [];

    $count[$subpage_no-1]    = $count[$subpage_no-1]+$count[$subpage_no];
    $count[$subpage_no]=0;    

    $subpage_no--;
  }

  print "Last size: " . $count[$subpage_no] . "\n";
  if ( $count[$subpage_no] == 0) { 
    print "Last subpage is empty!\n";
    $subpage_no--;
  }

  for ($i = 0; $i < scalar @subpages; $i++) { 
    print "Subpage $i " .  (scalar @{$subpages[$i]}) . "\n";
  }

  # see what is the largest number of entries in a subpage (counting the last one)
  $mx=0;
  for ($i=0 ; $i <=$subpage_no ; $i++){
    $mx = $count[$i] if ($mx < $count[$i]);
  }

  if ($mn < $min_pagesize - 100 || $mx > $max_pagesize){
    if ($mn < $min_pagesize - 100){
      print "There are subpages with under $mn articles. Will resplit!<br/>\n";
    }elsif ($mx > $max_pagesize){
      print "There are subpages with more than $mx articles. Will split!</br/>\n";
    }
    
    # have to resplit into subpages, as some are either too big or too small
    $subpage_no=0; 
    @count=(0); 

    @subpages=([]);

    foreach $name ( @list )  {

      $line=&print_object_data ($new_arts->{$name}); # and append this entry
      push @{$subpages[$subpage_no]}, $line;
      $count[$subpage_no]++; # increment all
      
      if ($count[$subpage_no] >= $min_pagesize){ # make a new subpage
        $subpage_no++; 
        push @subpages, []; 
        push(@count, 0);
      }
    }

    # don't let the last subpage be empty
    $subpage_no-- if (scalar @{$subpages[$subpage_no]} == 0); 
    print "After resplitting, there are " . ($subpage_no + 1) . " subpages<br/>\n";
  }

  # Generate the index, and print header and footer to subpages. Submit
  $text = $front_matter .  &print_index_header($project_category, $wikiproject);

  my @subpage_texts;

  $re_login_flag = 1;
  for ($i=0 ; $i <= $subpage_no; $i++){
    if ( ! defined $subpages[$i] ) { 
      print "Not defined\n";
      next;
    }	

    $iplus=$i+1;

    $text = $text . "\* \[\[$base_page\/" . $iplus . "\]\] \($count[$i] articles\)\n";

    # print a subpage. Note in line 4 the date field is empty,
    # to not update a page if only the date changed
    my $empty_date="";
    $subpage_texts[$i] =   &print_navigation_bar($base_page, $iplus, $subpage_no+1)
                         . &print_table_header($project_category, $wikiproject)
                         . (join "", @{$subpages[$i]} )      
                         . &print_table_footer($empty_date, $project_category) 
                         . &print_navigation_bar($base_page, $iplus, $subpage_no+1);

    $subpage_file = $base_page . "\/" . $iplus . ".wiki";

    &wikipedia_submit2($subpage_file, $edit_sum, $subpage_texts[$i]);

  }
  $text = $text . &print_index_footer($date, $project_category) . &print_current_category ($project_category);
  
  # submit the index of subpages
  &wikipedia_submit2($file, $edit_sum, $text);
}


######################################################################
sub process_submit_log {

  my ($todays_log, $combined_log, $date, @logs, %log_hash, $entry, $heading, $body);
  my (%order, $count, $project_category, $file);
  
  $file = shift; $todays_log = shift; $project_category = shift; $date = shift;

  # fetch the log from server, strip data before first section, and prepend today's log to it
  $combined_log=wikipedia_fetch2($file, $Attempts, $Sleep_fetch);
  $combined_log =~ s/^.*?(===)/$1/sg;
  $combined_log = $todays_log . "\n" . $combined_log;

  # split the logs in a hash, using look-ahead grouping, to not make the splitting pattern go away
  @logs=split ("(?=\n===)", $combined_log);

  # put the logs in a hash, in order
  $count=0;
  foreach $entry ( @logs ){

    next unless ($entry =~ /\s*===(.*?)===\s*(.*?)\s*$/s);
    $heading = $1;
    $body = $2;

    $order{$heading}=$count++;

    # wipe the $No_changes_message message for now (will add it later again if necessary -- this avoids duplicates)
    $body =~ s/\Q$No_changes_message\E//g;

    # if there are two logs for one day, merge them
    if (exists $log_hash{$heading}){
      $log_hash{$heading} = $log_hash{$heading} . "\n" . $body;
      $log_hash{$heading} =~ s/^\s*(.*?)\s*$/$1/s; # strip extraneous newlines introduced above if any
    }else{
      $log_hash{$heading} = $body; 
    }
  }

  # put back into a piece of text to return, keep only log for the last month or so
  $count=0; $combined_log=""; 
  foreach $heading (sort {$order{$a} <=> $order{$b}} keys %log_hash){
    $count++; last if ($count > 32);

    $body = $log_hash{$heading};
    $body = $No_changes_message if ($body =~ /^\s*$/); # if empty, no change
    
    $combined_log .= "===$heading===\n$body\n";
  }
  
  # truncate the log if too big
  $combined_log = &truncate_log($combined_log, 250000); # truncate log to 250K

  # categorize the logs, and put a message on top
  $combined_log  =  '{{Log}}' . "\n" . &print_current_category($project_category) . $combined_log;

  &wikipedia_submit2($file, "$Log for $date (test code)", $combined_log);
}

######################################################################
sub truncate_log {

  my ($log, $max_length) = @_;

  if (length ($log) > $max_length ) {
    $log = substr ($log, 0, $max_length);
    $log =~ s/^(.*)\n[^\n]*?$/$1/sg;  # strip last broken line
    $log = $log . "\n" . "<b><font color=red>Log truncated as it is too huge!</font></b>\n";
  }

  return $log;
}

######################################################################
sub calc_stats {

  my ($article, $qual, $imp);
  my ($articles, $stats, $global_flag, $repeats)=@_;

  # If not doing the global stats (where results for all the projects are aggregated)
  # then blank this hash
  %$stats = () unless ($global_flag);

  print "Calculating statistics for " . (scalar keys %$articles)
                                      . " articles<br/>\n";

  # count by quality and importance
  foreach $article (keys %$articles){
    # When doing the global stats, make sure don't count each article more than once.
    # This is needed since the same article can show up in many projects.
    if ($global_flag){
      next if (exists $repeats->{$article});
      $repeats->{$article}=1; 
    }

    $qual = $articles->{$article}->{'quality'};

    if (exists $articles->{$article}->{'importance'}){
      $imp = $articles->{$article}->{'importance'};
    }else{
      $imp = $No_Class;
    }
    
    $stats->{$qual}->{$imp}++;
    $stats->{$Total}->{$imp}++;
    $stats->{$qual}->{$Total}++;
    $stats->{$Total}->{$Total}++;
    
  }

  # subtract from the totals the unassessed articles to get the assessed articles
  foreach $imp ( (sort {$Importance{$a} <=> $Importance{$b} } keys %Importance), $Total){

    # first make sure that subtraction is well-defined
    $stats->{$Total}->{$imp} = 0
       unless (exists $stats->{$Total}->{$imp});
    $stats->{$Unassessed_Class}->{$imp} = 0
       unless (exists $stats->{$Unassessed_Class}->{$imp});

    # do the subtraction
    $stats->{$Assessed_Class}->{$imp}
       = $stats->{$Total}->{$imp} - $stats->{$Unassessed_Class}->{$imp} ;
  }
  print "Done calculating statistics.<br/>\n";
}


######################################################################
sub calc_global_stats_by_reading_from_disk {

  # Calculate the global stats by reading the information we saved on disk
  # at $Storage_dir when cyclcing through the projects earlier.
  # This consumes less memory, since we don't need to keep %repeats
  # in memory throughout the bot run, but we can create it only at the end.

  # It is very easy to make the global stats not being computed by saving to disk,
  # which makes things a bit inaccurate (see the description of $Storage dir on top).
  # An alternative way is to insert the lines
  #      $global_flag = 1; # Here, calc the stats for all the articles
  #      &calc_stats(\%new_arts, \%global_stats, $global_flag, \%repeats);
  # right when the bot calls calc_stats for each project in the main code loop.
  
  
  my ($projects, $project_category, $lists, $sep, $old_ids_file_name, $list_name);
  my ($old_ids_on_disk, $global_stats, $global_flag, $repeats, %repeats);
  
  ($projects, $lists, $global_stats)= @_;

  $sep = ' ;; '; # this local sep thing all over the place will have to go!!!

  foreach $project_category (@$projects) {

    print "Now adding $project_category to global stats.\n";
    $list_name = $lists->{$project_category};

    $old_ids_on_disk = {}; # Empty this hash before using it.
  
    $old_ids_file_name = &list_name_to_file_name ($list_name);
    &read_old_ids_from_disk ($old_ids_on_disk, $old_ids_file_name, $sep);

    # The previous routine had to uncompress $old_ids_on_disk. Compress back.
    &compress_file_maybe($old_ids_file_name);

    $global_flag = 1; # Here, calc the stats for all the articles
    &calc_stats($old_ids_on_disk, $global_stats, $global_flag, \%repeats);
  }
}

######################################################################
# Category:Mathematics is always guaranteed to have subcategories and articles.
# If none are found, we have a problem.
# This is is disabled on other language Wikipedias as not so essential.
sub check_for_errors_reading_cats {

  my ($category, @cats, @articles);
  $category = $Category . ":Mathematics";
  print "Doing some <b>debugging</b> first ... "
      . "Die if can't detect subcategories or articles due to changed API... <br/>\n";
  &fetch_articles_cats($category, \@cats, \@articles); 
  if ( !@cats || !@articles){
    print "Error! Can't detect subcatgories or articles!<br/>\n"; 
    exit (0); 
  }	
}

######################################################################
sub print_stats{

  my ($project_category, $map_qual_imp_to_cats, $stats) = @_;
  my ($project_sans_cat, $project_br, $text, $key, @articles, $cat, @categories);
  my ($qual, $qual_noclass, $imp, $imp_noclass, $link, @tmp, $num_rows);

  # This has is neeeded for the global totals. For the individual projects stats
  # make it just an empty hash.
  $map_qual_imp_to_cats = ()  if ($map_qual_imp_to_cats eq ""); 

  # insert a linebreak, to print nicer
  $project_sans_cat = &strip_cat ($project_category);
  $project_br = $project_sans_cat; $project_br =~ s/^(.*) (.*?)$/$1\<br\>$2/g;
  
  # start printing the table. Lots of ugly wikicode here.

  # initialize the table
  $text='{| class="wikitable" style="text-align: center;"
|-
! colspan="2" rowspan="2" | ' . $project_br . ' !! colspan="6" | ' . $Importance_word . '
|-
!';

  # initialize the columns
  foreach $imp ( (sort {$Importance{$a} <=> $Importance{$b} } keys %Importance), $Total){

    # ignore blank columns in the table
    next if ( ( !exists $stats->{$Total}->{$imp} ) || $stats->{$Total}->{$imp} == 0 );

    # $imp_noclass is $imp after stripping the '-Class' suffix
    $imp_noclass = $imp; $imp_noclass =~ s/-\Q$Class\E$//ig;

    # link to appropriate importance category
    if ( exists $map_qual_imp_to_cats->{$imp} ){

      $link = "\{\{$imp\|category=$map_qual_imp_to_cats->{$imp}\|$imp_noclass\}\}";

    }elsif ($imp_noclass !~ /\Q$Total\E/){

      $link = "\{\{$imp\}\}";

    }else{

      $link = $Total; 

    }

    $text = $text . $link . ' !! ';
  }
  $text =~ s/\!\!\s*$/\n/g; # no !! after the last element, rather, go to a new line

  # Initialize the rows. If another quality class is added in %Quality, increment rowspan below
  $text = $text . '|-
! rowspan="temp_placeholder" | ' .  $Quality_word . '
|-
';

  # loop through the rows of the table
  $num_rows = 1; # start at 1 to include the info row 
  foreach $qual ( (sort { $Quality{$a} <=> $Quality{$b} } keys %Quality), $Total){

    # ignore blank rows in the table
    next if ( ( !exists $stats->{$qual}->{$Total} ) || ( $stats->{$qual}->{$Total} == 0 ) );

    $num_rows++;

    # $qual_noclass is $qual after stripping the '-Class' suffix
    $qual_noclass = $qual; $qual_noclass =~ s/-\Q$Class\E$//ig;

    # link to appropriate quality category
    if ( exists $map_qual_imp_to_cats->{$qual} ){

      $link = "\{\{$qual\|category=$map_qual_imp_to_cats->{$qual}\|$qual_noclass\}\}";

    }elsif ($qual_noclass !~ /\Q$Total\E/){

      $link = "\{\{$qual\}\}";

    }else{

      $link = $Total; 

    }
    $text = $text . '! ' . $link . "\n\|";

    # fill in the cells in the current row
    foreach $imp ( (sort {$Importance{$a} <=> $Importance{$b} } keys %Importance), $Total){

      # ignore blank columns in the table
      next if ( ( !exists $stats->{$Total}->{$imp} ) || $stats->{$Total}->{$imp} == 0 );
     
      # if the current cell number exists and is greater than zero
      if (exists $stats->{$qual}->{$imp} && $stats->{$qual}->{$imp} > 0 ){
        
        if ($imp eq $Total || $qual eq $Total){
          
          # if in the last column, or last row, so containing a total, then
          # insert the number in the cell in bold, looks nicer like that
          $text = $text . " '''" . $stats->{$qual}->{$imp} . "''' ";
          
        }else{
          
          # the non-Total cells don't need to be bold
          $text = $text . " " . $stats->{$qual}->{$imp} . " ";

        }
        
      }else{
        # empty cell
        $text = $text . " ";
      }

      # separation between cells
      $text = $text . '||';
    }
    $text =~ s/\|\|\s*$//g; # strip the last cell, which will be empty
    $text = $text . "\n" . '|-' . "\n"; # start new row
  }
  
  $text = $text . '|}';              # close the table

  # put the correct number of rows 
  $text =~ s/rowspan=\"temp_placeholder\"/rowspan="$num_rows"/;

  return $text;
}

######################################################################
# The function below, extra_categorizations will not be called outside English Wikipedia
# It will be a pain to translate it to other languages. It is not that important either.
# It puts [[Category:GA-Class Aztec articles]] into [[Category:GA-Class articles]], etc.
# Save this action to disk.
sub extra_categorizations {

  my (@projects, @articles, $text, $project_category, $line, $cats_file, $file);
  my (%map, @imp_cats, @cats, $cat, $type, $edit_summary, $trunc_cat);

  $cats_file="Categorized_already.txt";
  open(FILE, "<$cats_file"); 
  binmode FILE, ":utf8";
  $text = <FILE>; 
  close(FILE);
  
  foreach $line ( split ("\n", $text) ){
    next unless ($line =~ /^(.*?)$Separator(.*?)$/);
    $map{$1}=$2;
  }
  
  &fetch_articles_cats($Root_category, \@projects, \@articles); 

  # Go through all projects, search the categories in there,
  # and merge with existing information
  my $count;
  foreach $project_category (@projects) {
    $count++;
    print   "--------------- Categorizing $project_category <br/>\n";
    print   "--------------- " . $count . "/" . scalar @projects . "<br/>\n";
    printf  "--------------- Elapsed %2.2f hours <br/>\n",  
                                        (time() - $Init_time) / 3600;

    if ($Lang eq 'en'){
      next if ($project_category =~ /\Q$Category\E:Articles (\Q$By_quality\E|\Q$By_importance\E)/); # meta cat
    }

    # e.g., Category:Physics articles by quality
    next unless ($project_category =~ /articles (\Q$By_quality\E|\Q$By_importance\E)/);
    $type=$1;
    
    &fetch_articles_cats($project_category, \@cats, \@articles); 
    foreach $cat (@cats){
      
      next if (exists $map{$cat}); # did this before
      
      if ($type =~ /quality/ && $cat =~ /\Q$Category\E:(FA|FL|A|GA|B|Start|Stub|List)-Class/i){
	$map{$cat} = $Category . ":$1-Class articles";
      }elsif ($type =~ /quality/ && $cat =~ /\Q$Category\E:(Unassessed)/i){
	$map{$cat}= $Category . ":$1-Class articles";
      }elsif ($type =~ /importance/ && $cat =~ /\Q$Category\E:(Top|High|Mid|Low|No|Unknown)-importance/i){
	$map{$cat}= $Category . ":$1-importance articles";
	$map{$cat}=~ s/\Q$Category\E:No-importance/$Category:Unknown-importance/g;
      }else{
	next;
      }

      $file=$cat . ".wiki";
      $text=wikipedia_fetch2($file, $Attempts, $Sleep_fetch);

      if ($text =~ /\Q$map{$cat}\E/i){ # did this category before 
         print "uf8", "\nCategorized $cat before<br/>\n";
         next; 
      }else{
        print "\nWill now categorize $cat<br/>\n";
      }
      $trunc_cat=$cat; $trunc_cat =~ s/^.*? //g;
      $text =~ s/\s*$//g; $text = $text . "\n\[\[$map{$cat}\|$trunc_cat\]\]";
      $edit_summary="Add to \[\[$map{$cat}\]\]";
 
      # Note that we sleep longer before sumbissions here, there is nowhere to rush.
      &wikipedia_submit2($file, $edit_summary, $text);
    }
  }

  open(FILE, ">$cats_file");
  binmode FILE, ":utf8";
  foreach $line (sort {$a cmp $b} keys %map){ print FILE "$line$Separator$map{$line}\n";  }
  close(FILE);
}

######################################################################
sub submit_global_stats{

  my ($stats_file, $global_stats, $date, $All_projects, $text);

  ($stats_file, $global_stats, $date, $All_projects) = @_;

  $text=wikipedia_fetch2($stats_file, $Attempts, $Sleep_fetch);
  $text =~ s/^(.*?)($|\Q$Bot_tag\E)/$Bot_tag/s;
  $text = &print_stats($All_projects, "", $global_stats) . $text;
  &wikipedia_submit2($stats_file, "All stats for $date", $text);
}


######################################################################
# this will only run on the English Wikipedia!
sub put_biography_project_last {

  my (%hash_of_projects, $projects, $project, $counter);
  $projects = shift;

  $counter=0; 
  foreach $project (@$projects){
    $hash_of_projects{$project} = $counter++;
  }
  
  # put other biography projects last too
  foreach $project (@$projects){
    $hash_of_projects{$project} = $counter++ if ($project =~ /biography/i);
  }

  $hash_of_projects{$Category . ":Biography articles by quality"}=$counter++; # make this be last;

  # put back into @$projects, with that biography category last
  @$projects = ();
  foreach $project (sort {$hash_of_projects{$a} <=> $hash_of_projects{$b} } keys %hash_of_projects){
    print "Will do " . $project . "<br/>\n";
    push (@$projects, $project);
  }
}

######################################################################
# identify the parent Wikproject of the current project category
sub get_wikiproject {

  my ($category, $text, $error, $wikiproject, $wikiproject_alt);
  
  $category=shift;
  print "Get name for " . $category . "\n";

  ($text, $error) = &get_html ( $Wiki_http . '/wiki/' .  &html_encode_string($category) );
  
  if ($text =~ /(\Q$Wikipedia\E:\Q$WikiProject\E[^\"]*?)[\#\"]/) {

    # if people bothered to specify the wikiproject in the category, use it
    $wikiproject = $1; $wikiproject = &html_decode_string($wikiproject);
    
  }else {
    
    # guess the wikiproject based on $cateogry
    $wikiproject=$category;

    $wikiproject =~ s/\Q$Category\E:(.*?) [^\s]+ \Q$By_quality\E$/$1/g;
    $wikiproject =~ s/^\Q$WikiProject\E\s*//g; # so that at the end line we don't end up with a possible duplicate
    $wikiproject="\Q$Wikipedia\E:\Q$WikiProject\E $wikiproject";
  }

  if ($Lang ne 'en'){
    return $wikiproject;
  }
  
  # if $Lang is 'en', try some other dirty tricks to find the wikiproject
  # First check if the wikiproject was guessed right
  $text=wikipedia_fetch2($wikiproject . ".wiki", $Attempts, $Sleep_fetch);

  # if the wikiproject was not guessed right, maybe the plural is wrong (frequent occurence)
  if ($text =~ /^\s*$/){
    $wikiproject_alt = $wikiproject . "s";
    $text=wikipedia_fetch2($wikiproject_alt . ".wiki", $Attempts, $Sleep_fetch);
    $wikiproject = $wikiproject_alt if ($text !~ /^\s*$/); # guessed right now
  }

  # perhaps the "-related" keyword is in
  if ($text =~ /^\s*$/ && $wikiproject =~ /(-| )related/){
    # if the wikiproject is still wrong, perhaps the related keyword is causing problems	 
    $wikiproject_alt = $wikiproject; $wikiproject_alt =~ s/(-| )related//g;
    $text=wikipedia_fetch2($wikiproject_alt . ".wiki", $Attempts, $Sleep_fetch);
    $wikiproject = $wikiproject_alt if ($text !~ /^\s*$/); # guessed right now
  }

  # Sometimes things like "Armenian" --> "Armenia" are necessary
  if ($text =~ /^\s*$/ && $wikiproject =~ /n$/){
    $wikiproject_alt = $wikiproject; $wikiproject_alt =~ s/n$//g;
    $text=wikipedia_fetch2($wikiproject_alt . ".wiki", $Attempts, $Sleep_fetch);
    $wikiproject = $wikiproject_alt if ($text !~ /^\s*$/); # guessed right now
  }

  print "Wikiproject is $wikiproject<br/><br/>\n\n";
  return $wikiproject;
}

######################################################################
sub cmp_arts {
  my ($art1, $art2);
  $art1=shift; $art2=shift; 

  # sort by quality 
  if (! exists $Quality{$art1->{'quality'}}){
    print "Quality not defined at $art1->{'name'} \'$art1->{'quality'}\'\n";
    return 0;
  }
  if (! exists $Quality{$art2->{'quality'}}){
    print "Quality not defined at $art2->{'name'} \'$art2->{'quality'}\'\n";
    return 0;
  }

  # better quality articles come first
  return 1 if ($Quality{$art1->{'quality'}} > $Quality{$art2->{'quality'}}); 
  return -1 if ($Quality{$art1->{'quality'}} < $Quality{$art2->{'quality'}}); 

  # sort by importance now
  if (! exists $Importance{$art1->{'importance'}}){
    print "Importance not defined at $art1->{'name'} \'$art1->{'importance'}\'\n";
    return 0;
  }
  if (! exists $Importance{$art2->{'importance'}}){
    print "Importance not defined at $art2->{'name'} \'$art2->{'importance'}\'\n";
    return 0;
  }
      
  return 1 if ($Importance{$art1->{'importance'}} > $Importance{$art2->{'importance'}}); 
  return -1 if ($Importance{$art1->{'importance'}} < $Importance{$art2->{'importance'}}); 

  # store alphabetically articles of the same quality
  return 1 if ($art1->{'name'} gt $art2->{'name'});
  return -1 if ($art1->{'name'} lt $art2->{'name'});

  return 0;		      # the entries must be equal I guess
}

######################################################################
sub print_table_header {

  my ($wikiproject, $category, $wikiproject_talk, $abbrev);

  $category=shift;
  $wikiproject=shift; 
  
  $abbrev=$wikiproject; $abbrev =~ s/\Q$Wikipedia\E:\Q$WikiProject\E/$WP/g;
  $wikiproject_talk = $wikiproject; $wikiproject_talk =~ s/\Q$Wikipedia\E:/$Wikipedia . ' ' . lc ($Talk) . ':'/eg;
  #  $wikiproject_talk = $wikiproject_talk . '#Version 1.0 Editorial Team cooperation';

  return "<noinclude>== [[$wikiproject]] ==</noinclude>\n"
	. "\{\{assessment header\|$wikiproject_talk|$abbrev\}\}\n";
}

######################################################################
sub print_index_header {

  my ($wikiproject, $category, $wikiproject_talk, $abbrev);

  $category=shift;
  $wikiproject=shift; 

  $abbrev=$wikiproject; $abbrev =~ s/\Q$Wikipedia\E:\Q$WikiProject\E/$WP/g;
  $wikiproject_talk = $wikiproject; $wikiproject_talk =~ s/\Q$Wikipedia\E:/$Wikipedia . ' ' . lc ($Talk) . ':'/eg;
#  $wikiproject_talk = $wikiproject_talk . '#Version 1.0 Editorial Team cooperation';

  return "<noinclude>== [[$wikiproject]] ==</noinclude>\n"
     . "\{\{assessment index header\|$wikiproject_talk|$abbrev\}\}\n";
}

######################################################################
sub print_table_footer {
  my ($cat, $date);
  $date=shift; $cat = shift; 
  
  return '{{assessment footer|seealso=' . $See_also . ': [[:'
     . $cat . '|assessed article categories]]. |lastdate=' . $date . '}}' . "\n";
  
}

######################################################################
sub print_index_footer {
  my ($cat, $date);
  $date=shift; $cat = shift; 
  
  return '{{assessment index footer|seealso=' . $See_also . ': [[:'
     . $cat . '|assessed article categories]]. |lastdate=' . $date . '}}' . "\n";
  
}

######################################################################
sub print_main_front_matter{

  my $index_nowiki = $Index_file; $index_nowiki =~ s/\.wiki//g;
  
  return '<noinclude>{{process header
 | title    = {{SUBPAGENAME}}
 | section  = assessment table
 | previous = \'\'\'&uarr;\'\'\' [['  . $index_nowiki . '|' . $Index . ']]
 | next     = [[{{FULLPAGENAME}} ' . lc($Log) . '|' . lc($Log)
    . ']], [[{{FULLPAGENAME}} ' . lc($Statistics) . '|' . lc($Statistics). ']] &rarr;
 | shortcut =
 | notes    =
}}</noinclude>'
  . "\n"
  . $Bot_tag
  . '<!--End front matter. Any text below this line will be overwitten by the bot. Please do not remove or modify this comment in any way. -->
';
}

######################################################################
sub print_navigation_bar {
  my ($base_page, $cur_subpage, $total_subpages, $prev_link, $next_link, $prev_num, $next_num);
  $base_page=shift;  $cur_subpage=shift; $total_subpages=shift;

  $prev_num=$cur_subpage-1; $next_num=$cur_subpage+1;
  
  if ($cur_subpage > 1 && $cur_subpage < $total_subpages){
    $prev_link="\&larr; \[\[$base_page\/" . $prev_num . "\|" . "(prev)" . "\]\]";
    $next_link="\[\[$base_page\/" . $next_num . "\|" . "(next)" . "\]\]  \&rarr;";

  }elsif ($cur_subpage == 1){
    $prev_link="\&larr; (prev)";
    $next_link="\[\[$base_page\/" . $next_num . "\|" . "(next)" . "\]\] \&rarr;";

  }else{
    $prev_link="\&larr; \[\[$base_page\/" . $prev_num . "\|" . "(prev)" . "\]\]";
    $next_link="(next) \&rarr;";
  }

  return '
<noinclude>
{{process header
  | title    = ' . "\&uarr;" . '[[' . $base_page  . '|(up)]] 
  | section  = 
  | previous = '   . $prev_link . '
  | next     = '   . $next_link . '
  | shortcut =
  | notes    =
}}</noinclude>
';  

}

######################################################################
sub print_object_data {

  my ($art, $text, $name, $imp);
  $art = shift;

  # add the link to the latest version in history, if available
  if ( $art->{'hist_link'} && $art->{'hist_link'} !~ /^\s*$/ ){
    $name = '[[' . $art->{'name'} . ']] [' . $art->{'hist_link'} . ' ]';
  }else{
    $name = '[[' . $art->{'name'} . ']]'; 
  }

  $imp=$art->{'importance'};
  $imp = "" if ($imp eq $No_Class); # no need to print the default importance
  $imp ='{{' . $imp . '}}' if ( $imp =~ /\w/); # add braces if nonemepty
     
  $text = '{{assessment' 
            . ' | page='       . $name
	    . ' | importance=' . $imp
	    . ' | date='       . $art->{'date'}  
	    . ' | class={{'    . $art->{'quality'} . '}}'
	    . ' | version='    . $art->{'version'}  
	    . ' | comments='   . $art->{'comments'} . ' }}' . "\n";
  
  return $text;
}

######################################################################
sub print_current_category {
  my $category = shift;
  return '<noinclude>[[' . $category . ']]</noinclude>' . "\n";
}

######################################################################
sub current_date {

  my ($year, $date);
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = gmtime();
  $year = 1900 + $yearOffset;
  
  $date = "$Months[$month] $dayOfMonth, $year";

  return $date;
}

######################################################################
sub most_recent_history_links_query {

  my ($articles, $latest_old_ids, $link, $article, $article_enc, $max_no, $count,  $iter);

  $articles = shift;  $latest_old_ids = shift;

  # in each query find the most recent history link of max_no articles at once, to speed things up
  $max_no = 100;

  $count=0; 
  $link = [];
  foreach $article ( sort {$a cmp $b} keys %$latest_old_ids){
    
    $count++;
    
    # encode to html, but with plus signs instead of underscores
    $article_enc = $article; 
 
    # do a bunch of queries at once
    push @$link, $article_enc;
    
    # but no more than $max_no
    if ( $count >= $max_no ){
      # run the query
      &fetch_revids($link, $latest_old_ids);
      
      # reset
      $count=0; 
      $link = [];
    }
  }
  
  # run it one last time for the leftover articles, if any
  &fetch_revids($link, $latest_old_ids) unless ( scalar @$link == 0);
  
  # use the history id to create a link to the most recent article 
  # history link
  foreach $article ( keys %$latest_old_ids ){    
    if (!exists $latest_old_ids->{$article} || $latest_old_ids->{$article} !~ /^\d+$/){
      print "Error in retrieving the latest history link of '$article'! <br/>"
    } else { 
       print  "Got '" . $latest_old_ids->{$article} . "' as revision id for '$article'.<br/>\n";
    }
    
    # compete the URL
    $articles->{$article}->{'hist_link'} = &old_id_to_hist_link ($latest_old_ids->{$article}, $article);
  }
}

######################################################################
# this subroutine and the one below read and write old_ids from disk. It is more reliable to have
# that info stored on disk in addition to Wikipedia

sub read_old_ids_from_disk {

  my ($old_ids_on_disk, $old_ids_file_name, $rev_file, $line, @lines);
  my ($sep, $article, $qual, $imp, $date, $old_id, $time_stamp, $command);
  
  ($old_ids_on_disk, $old_ids_file_name, $sep) = @_;

  &uncompress_file_maybe($old_ids_file_name);

  # read from disk
  if (-e "$old_ids_file_name" ){
    open(REV_READ_FILE, "<$old_ids_file_name");
    binmode REV_READ_FILE, ":utf8";
    @lines = split ("\n", <REV_READ_FILE>);
    close(REV_READ_FILE);
  }
  
  # get the data into the $old_ids_on_disk hash
  foreach $line (@lines){

    # parse the line and read the data
    next unless ($line =~ /^(.*?)$sep(.*?)$sep(.*?)$sep(.*?)$sep(.*?)$sep(.*?)$/);
    $article = $1; $qual = $2; $imp = $3; $date = $4; $old_id = $5; $time_stamp = $6;

    $date =~ s/[\[\]]//g; # rm links from dates

    $old_ids_on_disk->{$article}->{'quality'}=$qual;
    $old_ids_on_disk->{$article}->{'importance'}=$imp;
    $old_ids_on_disk->{$article}->{'date'}=$date;
    $old_ids_on_disk->{$article}->{'old_id'}=$old_id;
    $old_ids_on_disk->{$article}->{'time_stamp'}=$time_stamp;
  }
}


######################################################################
sub write_old_ids_on_disk {

  my ($new_arts, $old_ids_on_disk, $list_name, $old_ids_file_name, $sep);
  my ($current_time_stamp, $article, $seconds, $link, $command);

  ($new_arts, $old_ids_on_disk, $old_ids_file_name, $sep) = @_;

  $current_time_stamp = time();

  # update $old_ids_on_disk with information from $new_arts
  foreach $article (keys %$new_arts){

    $old_ids_on_disk->{$article}->{'quality'} = $new_arts->{$article}->{'quality'};
    $old_ids_on_disk->{$article}->{'importance'} = $new_arts->{$article}->{'importance'};
    $old_ids_on_disk->{$article}->{'date'} = $new_arts->{$article}->{'date'};

    # the old id is obtained from the history link by removing everything but the id
    # http://en.wikipedia.org/w/index.php?title=Ambon_Island&oldid=69789582 becomes 69789582
    $link = $new_arts->{$article}->{'hist_link'};
    if ( $link =~ /oldid=(\d+)/ ){
      $old_ids_on_disk->{$article}->{'old_id'} = $1; 
    }else{
      $old_ids_on_disk->{$article}->{'old_id'} = "";
    }
    
    $old_ids_on_disk->{$article}->{'time_stamp'} = $current_time_stamp;
  }

  # Attempt to create $Storage_dir where the bot will write the old_ids. Complain if fail.
  mkdir $Storage_dir unless (-e $Storage_dir);
  if (! -e $Storage_dir){
    print "Directory $Storage_dir needed by the bot does not exist!!! Exiting.\n";
    exit(0);
  }
  
  # Write to disk the updated old ids
  # do not write those old_ids with a time stamp older than $Number_of_days
  $seconds = 60*60*24*$Number_of_days;

  open(REV_WRITE_FILE, ">$old_ids_file_name");
  binmode REV_WRITE_FILE, ":utf8";

  print REV_WRITE_FILE "# Data in the order article, quality, importance, date, old_id, "
     . "time stamp in seconds, with '$sep' as separator\n";
  
  foreach $article (sort {$a cmp $b} keys %$old_ids_on_disk){

    # Do not write the old_ids with a time stamp older than $Number_of_days.
    # Those are no longer currently in the list, and if they are not there
    # for $Number_of_days, then it is time to ditch them. 
    if ($old_ids_on_disk->{$article}->{'time_stamp'} < $current_time_stamp - $seconds){
      print "Note: Bypassing '$article' as its timestamp is too old!<br/>\n";
      next;
    }
    
    print REV_WRITE_FILE $article
       . $sep . $old_ids_on_disk->{$article}->{'quality'}
       . $sep . $old_ids_on_disk->{$article}->{'importance'}
       . $sep . $old_ids_on_disk->{$article}->{'date'}
       . $sep . $old_ids_on_disk->{$article}->{'old_id'} 
       . $sep . $old_ids_on_disk->{$article}->{'time_stamp'}
       . "\n";
  }
  close(REV_WRITE_FILE);

  &compress_file_maybe($old_ids_file_name);
}

  
######################################################################
# On en.wikipedia I use bzip2 to zip files. 
# This won't work for scripts ran on Windows
sub uncompress_file_maybe {

  my ($old_ids_file_name, $command);
  
  $old_ids_file_name = shift;
  
  if ($Lang eq 'en'){
    if ( -r "$old_ids_file_name.bz2") { 
      $command = "bunzip2 -fv \"$old_ids_file_name.bz2\"";

      print "Will run $command in one second.<br/>" . "\n";    
      sleep 1; # let the filesever have time to think
      print "\tRunning...<br/>\n";
      print `$command` . "<br/>\n";
      print "Sleep 1 sec after running.<br/>\n"; sleep 1; 
    } else {
      print "File $old_ids_file_name.bz2 not readable, not trying to uncompress.<br/>\n";
    }
  }
}

######################################################################
# Opposite of the above. This and the above may need merging into one function
# to avoid code repetition. 
sub compress_file_maybe {
  
  my ($old_ids_file_name, $command);
  
  $old_ids_file_name = shift;
  
  if ($Lang eq 'en'){

    $command = "bzip2 -fv \"$old_ids_file_name\"";

    # let the filesever have time to think
    print "Will run $command in one second.<br/>" . "\n";    
    sleep 1; 
    print "\tRunning...<br/>\n";
    print `$command` . " <br/>\n";
    print "Sleep 1 sec after running.<br/>\n"; 
    sleep 1; 
  }
}

######################################################################
sub old_id_to_hist_link {

  my ($old_id, $article) = @_;

  if ($old_id =~ /^\d+$/){
    return $Wiki_http  . '/w/index.php?title=' . &html_encode_string ($article) . '&oldid=' . $old_id;
  }else{
   return ""; 
  }

}

######################################################################
# given a link to a history version of a Wikipedia article
# of the form http://en.wikipedia.org/w/index.php?oldid=86978700
# get the article name (as the heading 1 title)
sub hist_link_to_article_name {

  my ($hist_link, $article_name, $text, $error, $count);

  $hist_link = shift;

  if ( !$hist_link || $hist_link !~ /^\s*http.*?oldid=\d+/){
    print "Error! The following history link is invalid: '$hist_link'\n";
    return "";
  }

  # Do several attempts, for robustness
  $article_name = "";
  for ($count = 0; $count < 1000; $count++) {

    $fetchedNames++;  # count requests

    print "Get name for article ($fetchedNames)...\n";
    print "\t link $hist_link\n";

    ($text, $error) = &get_html ($hist_link);
    if ($text =~ /\<h1.*?\>(.*?)\</i){
      $article_name = $1;
      print "\t name is $article_name<br/>\n";
      last;

    }else{
      print "Error! Could not get article name for $hist_link in attempt $count!!!<br/>\n";
      sleep 10;
    }

  }

  if ($article_name =~ /^\s*$/){
     print "Failed! Bailing out<br/>\n";
     exit (0);
  } 

  return $article_name;
}

######################################################################
sub mark_project_as_done {

  my ($current_project, $done_projects_file) = @_;
  my (%project_stamps, $text, $line, $project, $project_stamp);

  &read_done_projects($done_projects_file, \%project_stamps);

  # Mark the current project with the current time
  $project_stamps{$current_project} = time();

  # Write back to disk, with oldest coming first
  open(FILE, ">$done_projects_file");
  binmode FILE, ":utf8";

  foreach $project (sort { $project_stamps{$a} <=> $project_stamps{$b} } keys %project_stamps){

    $project_stamp = $project_stamps{$project};

    # Also print the human-readable gmtime()
    print FILE $project . $Separator . $project_stamp . $Separator . gmtime($project_stamp) . "\n";
  }
  close(FILE);

}

######################################################################
sub decide_order_of_running_projects {
  
  my ($projects, $done_projects_file) = @_;
  my (%project_stamps, $project, $ten_days, $cur_time, %cur_project_stamps, $count);

  &read_done_projects($done_projects_file, \%project_stamps);

  # Mark projects that were never done as very old, so that they are done first
  $cur_time = time();
  $ten_days = 10*24*60*60;
  $count = 0;
  foreach $project (@$projects){
    
    $project_stamps{$project} = $cur_time - $ten_days + $count
       unless (exists $project_stamps{$project});

    $count++; # try to keep current order as much as possible
  }

  # Associate with each of @$projects its datestamp
  # We won't use %project_stamps directly as that one may have projects which are no
  # longer in @$projects
  foreach $project (@$projects){
    $cur_project_stamps{$project} = $project_stamps{$project};
  }
  
  # put the projects in the order of oldest first (old meaning 'was not run for a while')
  @$projects = ();
  foreach $project (sort { $cur_project_stamps{$a} <=> $cur_project_stamps{$b} }
                    keys %cur_project_stamps ){

    push (@$projects, $project);
  }
}

######################################################################
sub read_done_projects {

  my ($done_projects_file, $project_stamps) = @_;
  my ($text, $line, $project, $project_stamp);
  
  open(FILE, "<$done_projects_file"); 
  binmode FILE, ":utf8";

  $text = <FILE>; close(FILE);
  foreach $line (split ("\n", $text) ){
    next unless ($line =~ /^(.*?)$Separator(.*?)$Separator/);

    $project = $1; $project_stamp = $2;
    $project_stamps->{$project} = $project_stamp;
  }

}

######################################################################
sub strip_cat {
  my $project_category = shift;
  my $project_sans_cat = $project_category; $project_sans_cat =~ s/^\Q$Category\E:(.*?) \Q$By_quality\E/$1/g;
  return $project_sans_cat;
}

######################################################################
sub arttalk {
  my $article = shift;

  return '[[' . $article->{'name'} . ']] ([[' . $Talk . ':' . $article->{'name'} . '|' . lc ($Talk) . ']]) '
     . $article->{'quality'} . ' (' . $article->{'importance'} . ')';
}
   

######################################################################
# the structure holding an article and its attributes. This code must be the last thing in this file.
package article_assesment;

sub new {

  my($class) = shift;

  bless {

	 # name, date, version, etc., better not get translated from English,
	 # as they are invisible to the user and there
	 # are a huge amount of these variables
	 
	 'name'  => '',
	 'date' => '',
	 'quality' => $Unassessed_Class,
	 'importance' => $No_Class,
	 'comments' => '',
	 'hist_link' => '',
	 'version' => '',
	 
	}, $class;
}

1;

