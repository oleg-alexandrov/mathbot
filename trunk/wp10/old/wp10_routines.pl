#!/usr/bin/perl -w
use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Encode;

use lib $ENV{HOME} . '/public_html/cgi-bin/wp/modules'; # path to perl modules
require 'bin/wikipedia_fetch_submit.pl'; 
require 'bin/wikipedia_login.pl';
require 'bin/fetch_articles_cats_old.pl';
require 'bin/html_encode_decode.pl';
require 'bin/get_html.pl';
require 'bin/language_definitions.pl';

undef $/;		      # undefines the separator. Can read one whole file in one scalar.

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
# that's why they are not in the module "bin/language_definitions.pl" which is only for general keywords

# all the categories the bot will search will be subcategories of the the category below
my $Root_category= $Category . ':' . $Wikipedia . ' 1.0 assessments'; 

# all bot pages will be subpages of the page below
my $Editorial_team = $Wikipedia . ':Version 1.0 Editorial Team';

my $Index = 'Index';

# The bot will write an index of all generated lists to $Index_file
my $Index_file= $Editorial_team . '/' . $Index . '.wiki';

# Where the big log for today will be written
my $Todays_logname = $Editorial_team . '/Assessment_log.wiki';

# the name of the bot
my $Bot_name = 'WP 1.0 bot';

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

my %Quality=('FA-Class'=>1, 'A-Class'=>2, 'GA-Class'=>3, 'B-Class'=>4,
	    'Start-Class'=>5, 'Stub-Class'=>6, $Assessed_Class=>7, $Unassessed_Class=>8);
my %Importance=('Top-Class'=>1, 'High-Class'=>2, 'Mid-Class'=>3,
	       'Low-Class'=>4, $No_Class=>5);

my  @Months=("January", "February", "March", "April", "May", "June",
	     "July", "August",  "September", "October", "November", "December");


sub main_wp10_routine {
  
  my (@subjects, @articles, $text, $file, $attempts, $subject_category, $edit_summary);
  my (%old_arts, %new_arts, $art, %wikiprojects, $art_name, $date, $dir, %stats, %logs, %lists, @breakpoints);
  my ($todays_log, $todays_logs, $front_matter, %repeats, %version_hash);
  my ($run_one_project_only, %map_qual_imp_to_cats, $stats_file, $sleep_fetch, $sleep_submit);
  my (%project_stats, %global_stats);
  
  # go to the working directory
  $dir=$0; $dir =~ s/\/[^\/]*$/\//g; chdir $dir;

#  print "<font color=red>Bot down for maintanance for half a day. Come back later. </font>\n";
#  exit(0);
  
  &wikipedia_login($Bot_name);  $sleep_fetch = 1; $sleep_submit = 5; $attempts=100;
  $run_one_project_only=""; if (@_) { $run_one_project_only = shift}; # see if to run just one project or all of them

  # intialize some variables
  $date=&current_date();
  $todays_logs="";

  # base-most stuff
  &fetch_quality_categories(\@subjects);
  &update_index(\@subjects, \%lists, \%logs, \%stats, \%wikiprojects, $date);

  if ($Lang eq 'en'){
    # need this because the biography project takes much, much more time than others
    &put_biography_articles_last (\@subjects);
  }

  # go through a few categories containing version information (optional)
  &read_version (\%version_hash);

  # go through all subjects, search the categories in there, and merge with existing information
  foreach $subject_category (@subjects) {

    # if told to run just one project, ignore the others
    next if ($run_one_project_only && $subject_category !~ /\Q$run_one_project_only\E/i);

    # log in for each project (this should not be necessary but sometimes the bot oddly logs out)
    &wikipedia_login($Bot_name);

    # a hack, which is not that necessary
    if ($Lang eq 'en'){
      &check_for_errors_reading_cats();
    }

    # read existing lists into %old_arts
    $file = $lists{$subject_category};
    ($text, $front_matter)=&fetch_list_subpages($file, \@breakpoints);
    &extract_assessments ($subject_category, $text, \%old_arts); 

    # Collect new articles from categories, in %new_arts.
    &collect_new_from_categories ($subject_category, $date, \%new_arts, \%map_qual_imp_to_cats); 

    # Do some counting. Counting must happen before merging below,
    # as there unassessed biography articles will be removed.
    $file=$stats{$subject_category};
    &count_articles_by_quality_importance(\%new_arts, \%project_stats, \%global_stats, \%repeats);
    $text = &print_table_of_quality_importance_data($subject_category, \%map_qual_imp_to_cats, \%project_stats)
       . &print_current_category($subject_category);

    &wikipedia_submit($file, "$Statistics for $date", $text, $attempts, $sleep_submit); 

    # the heart of the code, compare %old_arts and %new_arts, merge some info from old into new, and generate a log
    $file = $lists{$subject_category};
    $todays_log = &compare_merge_and_log_diffs($date, $file, $subject_category, \%old_arts, \%new_arts,
					       \%version_hash);
    &split_into_subpages_maybe_and_submit ($file, $subject_category, $front_matter, $wikiprojects{$subject_category},
					   $date, \@breakpoints, \%new_arts);

    # process and submit the log
    $file=$logs{$subject_category};
    ($todays_log, $text)=&process_log($file, $todays_log, $subject_category, $lists{$subject_category});
    $todays_logs = $todays_logs . $todays_log;
    &wikipedia_submit($file, "$Log for $date", $text, $attempts, $sleep_submit);

  }

  # don't compute the global logs and totals if the script was called just for one project
  return if ($run_one_project_only);

  # global log
  &wikipedia_submit($Todays_logname, "All for $date.", $todays_logs, 20, $sleep_submit);

  # global stats
  $stats_file = $Editorial_team . "/$Statistics.wiki";
  &submit_global_stats ($stats_file, \%global_stats, $date, $All_projects);

  # Make Category:FA-Class physics articles a subcat in Category:FA-Class articles if not there yet, and so on
  # Only in the English Wikipedia (this function is not that necessary and will be hard to adapt to non-English)
  if ($Lang eq 'en'){
    &extra_categorizations();
  }
}

sub fetch_quality_categories{

  my ($subjects, $cat, @tmp_cats, @tmp_articles);
  
  $subjects = shift;

  # fetch all the subcategories of $Root_category
  &fetch_articles_cats($Root_category, \@tmp_cats, \@tmp_articles);

  # put in @$subjects only the categories by quality
  @$subjects=(); 
  foreach $cat (sort {$a cmp $b}  @tmp_cats){
    next unless ($cat =~ /^(.*?) \Q$By_quality\E/);

    if ($Lang eq 'en'){
      next if ($cat =~ /\Q$Category\E:Articles \Q$By_quality\E/); # silly meta category
    }
    
    push (@$subjects, $cat);
  }
}

# Create a hash of hashes containing the files the bot will write to, and some other information.
# Keep that hash of hashes on Wikipedia as an index of subjects.
sub update_index{
 
  my ($category, $text, $file, $line, $list, $stat, $log, $short_list, $preamble, $bottom);
  my ($attempts, $sleep, $wikiproject, $count, %sort_order);
  my ($subjects, $lists, $logs, $stats, $wikiprojects, $date)=@_;

  # fetch existing index, read the wikiprojects from there (need that as names of wikiprojects can't be generated)
  $attempts=800; $sleep=2;

  # save preamble for the future
  $text = &wikipedia_fetch($Index_file, $attempts, $sleep);
  if ($text =~ /^(.*?$Bot_tag.*?\n)(.*?)($Bot_tag.*?)$/s){
    $preamble=$1; $text=$2; $bottom=$3;
  } else{
   $preamble = $Bot_tag; $bottom = $Bot_tag; 
  }

  foreach $line (split ("\n", $text) ){
    next unless ($line =~ /\[\[:(\Q$Category\E:.*?)\|.*?\[\[(\Q$Wikipedia\E:.*?)\|/);
    $wikiprojects->{$1}=$2;
  }

  # generate names for the files the bot will write to
  foreach $category (@$subjects){

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

  # put that data in a index of subjects and submit to Wikipedia.
  $text = "";
  foreach $category (sort {$sort_order{$a} cmp $sort_order{$b}} keys %sort_order){
    
    $list        = $lists->{$category};         $list =~ s/\.wiki//g; $list =~ s/_/ /g;
    $stat        = $stats->{$category};         $stat =~ s/\.wiki//g; $stat =~ s/_/ /g;
    $log         = $logs->{$category};          $log  =~ s/\.wiki//g; $log  =~ s/_/ /g;
    $wikiproject = $wikiprojects->{$category};
       
    $short_list = $list; $short_list =~ s/^.*\///g; 
    $text = $text . "\| \[\[$list\|$short_list\]\] \|\| "
       . "\(\[\[$stat\|" . lc($Statistics) . "\]\], \[\[$log\|" . lc($Log) . "\]\], "
	  . "\[\[:$category\|" . lc($Category) . "\]\], \[\[$wikiproject\|" . lc($WikiProject) . "\]\]\)\n\|\-\n";
  }

  $count=scalar @$subjects;

  $text = $preamble 
	. "Currently, there are $count participating projects.\n\n" 
        . "\{\| class=\"wikitable\"\n"
        . $text . "\|\}\n"
	. $bottom;

  &wikipedia_submit($Index_file, "Update index", $text, $attempts, $sleep);
}

sub read_version{

  print "<font color=red>I have to read <b>all</b> version 0.5 and 1.0 articles before proceeding with your request. Be patient. </font><br><br>\n";

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

  print "<font color=red>Done reading all version articles. Will proceed to your request.</font><br><br>\n";

}

# fetch given list. If it has subpages, fetch those too. Put into one big $text variable.
sub fetch_list_subpages{
  my ($file, $breakpoints, $text, $attempts, $sleep, $front_matter, $base_page, @subpages, $subpage, $subpage_text, $line);

  $file=shift; $breakpoints=shift; 

  @$breakpoints=();

  $sleep = 1; $attempts = 1000;
  $text = &wikipedia_fetch($file, $attempts, $sleep);
  
  if ($text =~ /^(.*?$Bot_tag.*?\n)/s){
    $front_matter=$1;
  }else{
    $front_matter  =""; # will fill it in later
  }

  $base_page=$file; $base_page =~ s/\.wiki//g;
  @subpages = ($text =~ /\[\[(\Q$base_page\E\/\d+)[\|\]]/g); #must use \Q and \E since $base_page can have special chars
  foreach $subpage (@subpages){
    
    $subpage = $subpage . ".wiki";
    $subpage_text = &wikipedia_fetch($subpage, $attempts, $sleep);
    $text = $text . "\n" . $subpage_text;
    
    if ($subpage_text =~ /^.*\{\{assessment\s*\|\s*page\s*=\s*\[\[(.*?)\]\]/s){
      push (@$breakpoints, $1); # will need the breakpoints when updating the subpages.
    }
  }

  return ($text, $front_matter);
}

# given the $text read from the list and it subpages, parse it and put the info in a hash
sub extract_assessments{
  
  my ($subject_category, $arts, $line, $art, $file, $text, $sleep, $attempts, $talkpage);
  $subject_category=shift; $text = shift; $arts = shift; 
  
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

# read the quality, importance, and comments categories into %$new_arts. Later that will be merged with the info already in the lists
sub collect_new_from_categories {
  
  my (@cats, @dummy, @articles, $article, $wikiproject, $new_arts, $art, $cat, @tmp, $counter);
  my ($subject_category, $importance_category, $date, $qual, $imp, $comments_category, $map_qual_imp_to_cats);

  $subject_category=shift; $date = shift; $new_arts=shift; $map_qual_imp_to_cats = shift;

  # blank two hashes before using them
  %$new_arts = (); 
  %$map_qual_imp_to_cats = (); 
  
  # $subject_category (e.g., "Chemistry articicles by quality") contains subcategories of each quality.
  # Read them and the articles categorized in them.  
  &fetch_articles_cats($subject_category, \@cats, \@articles); 

  # go through each of the FA-Class, A-Class, etc. categories and read their articles
  foreach $cat (@cats) {

    next unless ($cat =~ /\Q$Category\E:(\w+)[\- ]/);
    $qual=$1 . '-' . $Class; # e.g., FA-Class

    # ignore categories which do not correspond to any quality rating
    next unless (exists $Quality{$qual});

    # will need this map when counting how many articles of each type we have
    $map_qual_imp_to_cats->{$qual} = $cat;

    # collect the articles
    &fetch_articles_cats($cat, \@dummy, \@articles); 
    foreach $article (@articles) {
      next unless ($article =~ /^\Q$Talk\E:(.*?)$/i);
      $article = $1;

      # store all the data in an an object
      $new_arts->{$article}=article_assesment->new();

      $new_arts->{$article}->{'name'}=$article;
      $new_arts->{$article}->{'date'}=$date;
      $new_arts->{$article}->{'quality'}=$qual;
    }
  }

  # look in $importance_category, e.g., "Chemistry articles by importance", read its subcategories,
  # for example, "Top chemistry articles", etc.
  $importance_category=$subject_category; $importance_category =~ s/\Q$By_quality\E/$By_importance/g;
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

    # no point in fetching the contents of the unassessed importance categories. That's the default.
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
  
  # fill in the comment field, for articles which are in a category meant to show that there is a comments subpage
  $comments_category=$subject_category; $comments_category =~ s/\Q$By_quality\E/$With_comments/g;
  &fetch_articles_cats($comments_category, \@cats, \@articles); 
  
  foreach $article (@articles) {
    next unless ($article =~ /^\Q$Talk\E:(.*?)$/);
    $article = $1;
    
    next unless exists ($new_arts->{$article}); # guards against strange undefined things
    
    $new_arts->{$article}->{'comments'}= '{{' . $Talk . ':' . $article . '/' . $Comments . '}}' 
       . ' ([' . $Wiki_http . '/w/index.php?title=' . $Talk . ':'
	  . &html_encode($article) . '/' . $Comments. '&action=edit ' . $Edit_comment . '])';
  }
}

# the heart of the code
sub compare_merge_and_log_diffs {

  my ($date, $list_name, $subject_category, $old_arts, $new_arts, $version_hash) =@_;
  my ($log_text, $line, $art, $article, $latest_old_ids, $sep, $old_ids_on_disk, $old_ids_file_name, $text, $sleep, $attempts, $new_name, $dir);

  $sleep = 2; $attempts = 10;
  
  # the big loop to collect the data and the logs
  $log_text="===$date===\n";

  # read old_ids from disk. That info also exists in the Wikipedia lists themselves, but if the bot misbehaved
  # or if the server had problems, or if there was vandalism, all in the last few days, it may have been lost. 
  $sep = ' ;; ';
  $old_ids_on_disk = {}; # empty hash for now

  # create the old_ids file name. 
  $dir = "/tmp/wp10/"; # will store here the file
  mkdir $dir unless (-e $dir);
  $old_ids_file_name = $list_name; 
  $old_ids_file_name =~ s/^.*\///g;
  $old_ids_file_name = &html_encode ($old_ids_file_name); # this may convert slashes (/) to stuff like %22.
  $old_ids_file_name = $dir . $old_ids_file_name;
  $old_ids_file_name =~ s/\.wiki$//g; 
  $old_ids_file_name = $old_ids_file_name . "_old_ids";

  &read_old_ids_from_disk ($old_ids_on_disk, $old_ids_file_name, $sep);
  
  # identify entries which were removed from categories (entries in $old_arts which are not in $new_arts)
  foreach $article ( sort { &cmp_arts($old_arts->{$a}, $old_arts->{$b}) } keys %$old_arts) {
    if (! exists $new_arts->{$article}) {

      # see if perhaps the article got moved, in that case, transfer the info and note this in the log
      $new_name = &hist_link_to_article_name ($old_arts->{$article}->{'hist_link'});

      if ($new_name !~ /^\s*$/ && ( !exists $old_arts->{$new_name} ) && ( exists $new_arts->{$new_name}) ){

	# so, it appears indeed that the article got moved

	# Pretend that $new_name exited before, so that
	# later the info of $old_arts->{$article} may be copied to $new_arts->{$new_name}
	$old_arts->{$new_name} = $old_arts->{$article};

	# replace the title in the hist_link (this has no effect on the validity of the hist_link,
	# it looks better to humans though)
	if ($old_arts->{$new_name}->{'hist_link'} =~ /^(.*?\/w\/index\.php\?title=).*?(\&oldid=.*?)$/i) {
	  $old_arts->{$new_name}->{'hist_link'} =  $1 .  &html_encode ($new_name) . $2;
	}

	#note the move in the log
	$line = "\* '''" . &arttalk ($old_arts->{$article})
	   . " renamed to \[\[" . $new_name . "\]\]'''\n";
	$log_text = $log_text . $line;

      }else{

	# so it was not a move, but a plain removal
	$line = "\* '''" . &arttalk ($old_arts->{$article}) . " removed.'''\n";
	$log_text = $log_text . $line; 
      }
    }
  }
  
  # identify entries which were added, copy some info from old to new, and log all changes
  foreach $article ( sort { &cmp_arts($new_arts->{$a}, $new_arts->{$b}) } keys %$new_arts) {

    # a dirty trick needed only on the English Wikipedia
    if ($Lang eq 'en'){

      # this is making the code a bit more complicated, but is necessary. Count (done already), but do not list
      # unassessed biography articles, as they are just too many (200,000).

      if ($subject_category eq "Category:Biography articles by quality"
	  && $new_arts->{$article}->{'quality'} eq $Unassessed_Class){
	delete $new_arts->{$article};
	next;
      }
    }
    
    # add version information (0.5, 0.5 nom, 1.0, or 1.0 nom)
    $new_arts->{$article}->{'version'} = $version_hash->{$article} if (exists $version_hash->{$article});

    # Found a new article. deal with its old_id, and record its appearance in the log
    if (! exists $old_arts->{$article}) {

      # if the old_id of the current article exists on disk, it means that the current article is not truly new,
      # it was in the list in the last few days and then it vanished for some reason (bot or server problems)
      # so recover its hist_link and date from its old_id stored on disk
      # assuming that its quality did not change in between
      
      if ( ( exists $old_ids_on_disk->{$article}->{'old_id'} )
	   && ($old_ids_on_disk->{$article}->{'quality'} eq $new_arts->{$article}->{'quality'} ) ){

	# the hist_link is obtained from old_id by completing the URL
	$new_arts->{$article}->{'hist_link'} =
	   &old_id_to_hist_link ($old_ids_on_disk->{$article}->{'old_id'}, $article);
	
	# and copy the date too
	$new_arts->{$article}->{'date'} = $old_ids_on_disk->{$article}->{'date'};
	
      }else{
	# If the new article is truly new, we need to do a query to get its hist_link. Do it later
	# for a chunck of articles at once, it is faster that way. So, add it in the pipeline $latest_old_ids
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
      print "Assesment improved for \[\[$article\]\].<br>\n";
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

  # fill in the most recent history link for articles which are new or changed the assessment for the better
  &most_recent_history_links_query ($new_arts, $latest_old_ids);

  # and write to disk the old_ids, that info may be used if articles together
  # with the old_ids vanish from Wikipedia lists
  # in the next few days due to bot or server problems
  &write_old_ids_on_disk($new_arts, $old_ids_on_disk, $old_ids_file_name, $sep);

  return $log_text;
}

sub split_into_subpages_maybe_and_submit {
  my ($attempts, $global_count, @count, $subpage_no, $subpage_file, @lines, $line, $subpage_frontmatter, @subpages);
  my ($max_pagesize, $min_pagesize, $name, $mx, $mn, $base_page, $i, $iplus, $text, $sleep_submit);
  my ($file, $subject_category, $front_matter, $wikiproject, $date, $breakpoints, $new_arts)=@_;

  $sleep_submit = 5; $attempts=500;
  $max_pagesize=500; $min_pagesize=400;
  $base_page=$file; $base_page =~ s/\.wiki//g;
  $front_matter=&print_main_front_matter () if (!$front_matter || $front_matter =~ /^\s*$/);
  
  # lots of things to initialize
  $global_count=0; $subpage_no=0; @count=(0); @subpages=(""); 
  @$breakpoints=(@$breakpoints, "", ""); # don't complain about not beining initialized
  
  # see if to split into subpages at all, and if current breakpoints still make the pages small
  foreach $name ( sort { &cmp_arts($new_arts->{$a}, $new_arts->{$b}) } keys %$new_arts) {
    $line=&print_object_data ($new_arts->{$name}); # and append this entry

    next unless ($line =~ /\{\{assessment\s*\|\s*page\s*=\s*\[\[.+?\]\]/);
    $subpages[$subpage_no]=$subpages[$subpage_no] . $line; $global_count++; $count[$subpage_no]++; # increment all

    if ($breakpoints->[$subpage_no] eq $name){ # reached a breakpoint, create a new subpage
      $subpage_no++; push(@subpages, ""); push(@count, 0);
    }
  }

  # if decided not to split into subpages, just submit the text and return 
  if ($global_count <= $max_pagesize){ #don't split into subpages
    print "Only $global_count articles. Won't split into subpages!\n";
    $text=join ("", @subpages);
    $text = $front_matter
       . &print_table_header($subject_category, $wikiproject)
	  . $text
	     . &print_table_footer($date, $subject_category)
		. &print_current_category ($subject_category);

    &wikipedia_login($Bot_name);  
    &wikipedia_submit ($file, "Update for $date", $text, $attempts, $sleep_submit);   # submit to wikipedia
    return;
  }

  # see what is the smallest number of entries in a subpage (not counting the last one which may be small)
  $mn=$min_pagesize;
  for ($i=0 ; $i <=$subpage_no-2 ; $i++){
    $mn = $count[$i] if ($mn > $count[$i]);
  }
  
  # see if it is possible to add the last subpage to the one before it (the last subpage may be small)
  if ($subpage_no >= 1 && $count[$subpage_no-1]+$count[$subpage_no] <= $max_pagesize){
    $subpages[$subpage_no-1] = $subpages[$subpage_no-1] . $subpages[$subpage_no]; $subpages[$subpage_no]="";
    $count[$subpage_no-1]    = $count[$subpage_no-1]+$count[$subpage_no];         $count[$subpage_no]=0;    
    $subpage_no--;
  }

  # see what is the largest number of entries in a subpage (counting the last one)
  $mx=0;
  for ($i=0 ; $i <=$subpage_no ; $i++){
    $mx = $count[$i] if ($mx < $count[$i]);
  }

  if ($mn < $min_pagesize - 100 || $mx > $max_pagesize){
    if ($mn < $min_pagesize - 100){
      print "There are subpages with under $mn articles. Will resplit!\n";
    }elsif ($mx > $max_pagesize){
      print "There are subpages with more than $mx articles. Will split!\n";
    }
    
    # have to resplit into subpages, as some are either too big or too small
    $subpage_no=0; @count=(0); @subpages=("");
    foreach $name ( sort { &cmp_arts($new_arts->{$a}, $new_arts->{$b}) } keys %$new_arts) {

      $line=&print_object_data ($new_arts->{$name}); # and append this entry
      $subpages[$subpage_no]=$subpages[$subpage_no] . $line; $count[$subpage_no]++; # increment all
      
      if ($count[$subpage_no] >= $min_pagesize){ # make a new subpage
	$subpage_no++; push(@subpages, ""); push(@count, 0);
      }
    }
    $subpage_no-- if ($subpages[$subpage_no] =~ /^\s*$/);     # don't let the last subpage be empty
  }

  # Generate the index, and print header and footer to subpages. Submit
  $text = $front_matter .  &print_index_header($subject_category, $wikiproject);
  for ($i=0 ; $i <= $subpage_no; $i++){
    $iplus=$i+1;
    $text = $text . "\* \[\[$base_page\/" . $iplus . "\]\] \($count[$i] articles\)\n";

    # print a subpage. Note in line 4 the date field is empty, to not update a page if only the date changed
    my $empty_date="";
    $subpages[$i] = &print_navigation_bar($base_page, $iplus, $subpage_no+1)
                  . &print_table_header($subject_category, $wikiproject)
                  . $subpages[$i]     
                  . &print_table_footer($empty_date, $subject_category) 
                  . &print_navigation_bar($base_page, $iplus, $subpage_no+1);

    $subpage_file = $base_page . "\/" . $iplus . ".wiki";
    &wikipedia_login($Bot_name);
    &wikipedia_submit ($subpage_file, "Update for $date", $subpages[$i], $attempts, $sleep_submit);

  }
  $text = $text . &print_index_footer($date, $subject_category) . &print_current_category ($subject_category);
  
  # submit the index of subpages
  &wikipedia_login($Bot_name);
  &wikipedia_submit($file, "Update for $date", $text, $attempts, $sleep_submit);

}

sub process_log {
  my ($log, $list, $short_list, @logs, $todays_log, %log_hash, $entry, $heading, $body, $one_day_log);
  my (%order, $count, $subject_category, $attempts, $sleep_fetch, $file);
  
  $file = shift; $todays_log = shift; $subject_category = shift; $list=shift;
  $attempts=100; $sleep_fetch=1;

  # fetch the log from server, strip data before first section, and prepend to it today's log
  $log=&wikipedia_fetch($file, $attempts, $sleep_fetch);
  $log =~ s/^.*?(==)/$1/sg;
  $log = $todays_log . $log;

  # put the logs in a hash, in order
  @logs=split ("\n===", $log);
  $count=0;
  foreach $entry ( @logs ){
    next unless ($entry =~ /\s*\=*(\[\[.*?)\=+\s*(.*?)\s*$/s);

    $heading=$1; $body=$2;
    $order{$heading}=$count++;

    # wipe the $No_changes_message message for now (will add it later again if necessary -- this avoids duplicates)
    $body =~ s/\Q$No_changes_message\E\s*//g;

    # if there are two logs for one day, merge them
    if (exists $log_hash{$heading}){
      $log_hash{$heading} = $log_hash{$heading} . "\n" . $body; # merge
    }else{
      $log_hash{$heading} = $body; 
    }
  }

  # put back into a piece of text to return, keep only log for the last month or so
  $count=0; $log=""; 
  foreach $heading (sort {$order{$a} <=> $order{$b}} keys %log_hash){
    $count++; last if ($count > 32);

    $body = $log_hash{$heading};
    $body =~ s/^\s*(.*?)\s*$/$1/sg; $body =~ s/\n\s*/\n/g; # trim extra space
    $body = $No_changes_message if ($body =~ /^\s*$/); # if empty, no change
    $one_day_log ="===$heading===\n$body\n";
    
    # store the log for the first day in this varible for future use
    $todays_log="$one_day_log" if ($count == 1);

    $log = $log . $one_day_log; 
  }
  
  # truncate the log if too big
  $log = &truncate_log($log, 250000); # truncate log to 250K

  # categorize the logs, and put a message on top
  $log  =  '{{Log}}' . "\n" . &print_current_category($subject_category) . $log;

  # process the log for today, will append this later to the daily global log
  $list =~ s/\.wiki//g; $short_list = $list; $short_list =~ s/^.*\///g;
  $todays_log =~ s/^\s*(=+)(.*?=+)/$1\[\[$list\|$short_list\]\] log for $2/g;
  $todays_log = $todays_log . "\n";

  $todays_log = &truncate_log($todays_log, 100000); # truncate today's log to 100K

  return ($todays_log, $log);
}

sub truncate_log {
  my ($log, $max_length) = @_;

  if (length ($log) > $max_length ) {
    $log = substr ($log, 0, $max_length);
    $log =~ s/^(.*)\n[^\n]*?$/$1/sg;  # strip last broken line
    $log = $log . "\n" . "<b><font color=red>Log truncated as it is too huge!</font></b>\n";
  }

  return $log;
}
sub count_articles_by_quality_importance {
  my ($article, $imp);
  my ($articles, $project_stats, $global_stats, $repeats)=@_;

  %$project_stats = (); # blank this
  foreach $article (keys %$articles){

    $project_stats->{$articles->{$article}->{'quality'}}->{$articles->{$article}->{'importance'}}++;
    $project_stats->{$Total}->{$articles->{$article}->{'importance'}}++;
    $project_stats->{$articles->{$article}->{'quality'}}->{$Total}++;
    $project_stats->{$Total}->{$Total}++;
    
    # when doing the global counting, make sure don't count each article more than once. 
    next if (exists $repeats->{$article});
    $repeats->{$article}=1; 

    $global_stats->{$articles->{$article}->{'quality'}}->{$articles->{$article}->{'importance'}}++;
    $global_stats->{$Total}->{$articles->{$article}->{'importance'}}++;
    $global_stats->{$articles->{$article}->{'quality'}}->{$Total}++;
    $global_stats->{$Total}->{$Total}++;
  }

  # subtract from the totals the unassessed articles to get the assessed articles
  foreach $imp ( (sort {$Importance{$a} <=> $Importance{$b} } keys %Importance), $Total){

    # first make sure that subtraction is well-defined
    $project_stats->{$Total}->{$imp} = 0 unless (exists $project_stats->{$Total}->{$imp});
    $project_stats->{$Unassessed_Class}->{$imp} = 0 unless (exists $project_stats->{$Unassessed_Class}->{$imp});
    
    $project_stats->{$Assessed_Class}->{$imp}
       = $project_stats->{$Total}->{$imp} - $project_stats->{$Unassessed_Class}->{$imp} ;
    
    $global_stats->{$Total}->{$imp} = 0 unless (exists $global_stats->{$Total}->{$imp});
    $global_stats->{$Unassessed_Class}->{$imp} = 0 unless (exists $global_stats->{$Unassessed_Class}->{$imp});

    $global_stats->{$Assessed_Class}->{$imp}
       = $global_stats->{$Total}->{$imp} - $global_stats->{$Unassessed_Class}->{$imp} ;
  }
}


# Category:Mathematics is always guaranteed to have subcategories and articls. If none are found, we have a problem
# This is is disabled on other language Wikipedias as not so essential
sub check_for_errors_reading_cats {
  my ($category, @cats, @articles);
  $category = $Category . ":Mathematics";
  print "Doing some <b>debugging</b> first ... die if can't detect subcategories or articles due to changed API... <br>\n";
  &fetch_articles_cats($category, \@cats, \@articles); 
  if ( !@cats || !@articles){
    print "Error! Can't detect subcatgories or articles!\n"; 
    exit (0); 
  }	
}

sub print_table_of_quality_importance_data{

  my ($subject_category, $map_qual_imp_to_cats, $project_stats) = @_;
  my ($subject_sans_cat, $subject_br, $text, $key, @articles, $cat, @categories);
  my ($qual, $qual_noclass, $imp, $imp_noclass, $link, @tmp);

  $map_qual_imp_to_cats = ()  if ($map_qual_imp_to_cats eq ""); # needed for the global totals

  $subject_sans_cat = &strip_cat ($subject_category);
  $subject_br = $subject_sans_cat; $subject_br =~ s/^(.*) (.*?)$/$1\<br\>$2/g; # insert a linebreak, to print nicer
  
  # start printing the table. Lots of ugly wikicode here.

  # initialize the table
  $text='{| class="wikitable" style="text-align: center;"
|-
! colspan="2" rowspan="2" | ' . $subject_br . ' !! colspan="6" | ' . $Importance_word . '
|-
!';

  # initialize the columns
  foreach $imp ( (sort {$Importance{$a} <=> $Importance{$b} } keys %Importance), $Total){

    # ignore blank columns in the table
    next if ( ( !exists $project_stats->{$Total}->{$imp} ) || $project_stats->{$Total}->{$imp} == 0 );

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

  # initialize the rows
  $text = $text . '|-
! rowspan="10" | ' .  $Quality_word . '
|-
';

  # loop through the rows of the table
  foreach $qual ( (sort { $Quality{$a} <=> $Quality{$b} } keys %Quality), $Total){

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
      next if ( ( !exists $project_stats->{$Total}->{$imp} ) || $project_stats->{$Total}->{$imp} == 0 );
      
      if (exists $project_stats->{$qual}->{$imp}){

	if ($imp eq $Total || $qual eq $Total){

	  # insert the number in the cell in bold, looks nicer like that
	  $text = $text . " '''" . $project_stats->{$qual}->{$imp} . "''' ";
	  
	}else{

	  # the non-Total cells don't need to be bold
	  $text = $text . " " . $project_stats->{$qual}->{$imp} . " ";

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

  $text = $text . '|}' . "\n";              # close the table
  $text =~ s/(\Q$Total\E)/\'\'\'$1\'\'\'/g; # boldify the string "Total" in cells
  return $text;
}

######## The function below, extra_categorizations will not be called outside English Wikipedia ##########
# It will be a pain to translate it to other languages. It is not that important either.
# It put things like [[Category:GA-Class Aztec articles]] into [[Category:GA-Class articles]].
# Save this action to disk.
sub extra_categorizations {

  my (@subjects, @articles, $text, $sleep, $attempts, $subject_category, $line, $cats_file, $file);
  my (%map, @imp_cats, @cats, $cat, $sep, $type, $edit_summary, $trunc_cat);

  $sep='------'; $attempts=100; $sleep=2;
  $cats_file="Categorized_already.txt";
  open(FILE, "<$cats_file"); $text = <FILE>; close(FILE);
  foreach $line ( split ("\n", $text) ){
    next unless ($line =~ /^(.*?)$sep(.*?)$/);
    $map{$1}=$2;
  }
  
  &fetch_articles_cats($Root_category, \@subjects, \@articles); 

  # go through all subjects, search the categories in there, and merge with existing information
  foreach $subject_category (@subjects) {

    if ($Lang eq 'en'){
      next if ($subject_category =~ /\Q$Category\E:Articles (\Q$By_quality\E|\Q$By_importance\E)/); # meta cat
    }

    # e.g., Category:Physics articles by quality
    next unless ($subject_category =~ /articles (\Q$By_quality\E|\Q$By_importance\E)/);
    $type=$1;
    
    &fetch_articles_cats($subject_category, \@cats, \@articles); 
    foreach $cat (@cats){
      
      next if (exists $map{$cat}); # did this before
      if ($type eq "quality" && $cat =~ /\Q$Category\E:(FA|A|GA|B|Start|Stub)-Class/i){
	$map{$cat} = $Category . ":$1-Class articles";
      }elsif ($type eq "quality" && $cat =~ /\Q$Category\E:(Unassessed)/i){
	$map{$cat}= $Category . ":$1-Class articles";
      }elsif ($type eq "importance" && $cat =~ /\Q$Category\E:(Top|High|Mid|Low|No|Unknown)-importance/){
	$map{$cat}= $Category . ":$1-importance articles";
	$map{$cat}=~ s/\Q$Category\E:No-importance/$Category:Unknown-importance/g;
      }else{
	next;
      }

      $file=$cat . ".wiki";
      $text=&wikipedia_fetch($file, $attempts, $sleep);
      next if ($text =~ /$map{$cat}/i); # did this category before 

      $trunc_cat=$cat; $trunc_cat =~ s/^.*? //g;
      $text = $text . "\n\[\[$map{$cat}\|$trunc_cat\]\]";
      $edit_summary="Add to \[\[$map{$cat}\]\]";
      &wikipedia_submit($file, $edit_summary, $text, $attempts, $sleep);
    }
  }

  open(FILE, ">$cats_file");
  foreach $line (sort {$a cmp $b} keys %map){ print FILE "$line$sep$map{$line}\n";  }
  close(FILE);
}

sub submit_global_stats{
  my ($stats_file, $global_stats, $date, $All_projects, $attempts, $sleep_fetch, $sleep_submit, $text);

  ($stats_file, $global_stats, $date, $All_projects) = @_;
  $sleep_fetch = 1; $sleep_submit = 5; $attempts = 100;

  $text=&wikipedia_fetch($stats_file, $attempts, $sleep_fetch);
  $text =~ s/^(.*?)($|\Q$Bot_tag\E)/$Bot_tag/s;
  $text = &print_table_of_quality_importance_data($All_projects, "", $global_stats) . $text;
  &wikipedia_submit($stats_file, "All stats for $date", $text, $attempts, $sleep_submit);
}


# this will only run on the English Wikipedia!
sub put_biography_articles_last {
  my (%hash_of_subjects, $subjects, $subject, $counter);
  $subjects = shift;

  $counter=0; 
  foreach $subject (@$subjects){
    $hash_of_subjects{$subject} = $counter++;
  }
  
  $hash_of_subjects{$Category . ":Biography articles by quality"}=$counter++; # make this be last;

  # put back into @$subjects, with that biography category last
  @$subjects = ();
  foreach $subject (sort {$hash_of_subjects{$a} <=> $hash_of_subjects{$b} } keys %hash_of_subjects){
    push (@$subjects, $subject);
  }
}

# identify the parent Wikproject of the current subject category
sub get_wikiproject {
  my ($category, $text, $error, $wikiproject, $wikiproject_alt, $attempts, $sleep);
  
  $category=shift;
  ($text, $error) = &get_html ( $Wiki_http . '/wiki/' .  &html_encode($category) );
  
  if ($text =~ /(\Q$Wikipedia\E:\Q$WikiProject\E[^\"]*?)\"/) {

    # if people bothered to specify the wikiproject in the category, use it
    $wikiproject = $1; $wikiproject = &html_decode($wikiproject);
    
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
  $attempts=10; $sleep=2;
  $text=&wikipedia_fetch($wikiproject . ".wiki", $attempts, $sleep);

  # if the wikiproject was not guessed right, maybe the plural is wrong (frequent occurence)
  if ($text =~ /^\s*$/){
    $wikiproject_alt = $wikiproject . "s";
    $text=&wikipedia_fetch($wikiproject_alt . ".wiki", $attempts, $sleep);
    $wikiproject = $wikiproject_alt if ($text !~ /^\s*$/); # guessed right now
  }

  # perhaps the "-related" keyword is in
  if ($text =~ /^\s*$/ && $wikiproject =~ /(-| )related/){
    # if the wikiproject is still wrong, perhaps the related keyword is causing problems	 
    $wikiproject_alt = $wikiproject; $wikiproject_alt =~ s/(-| )related//g;
    $text=&wikipedia_fetch($wikiproject_alt . ".wiki", $attempts, $sleep);
    $wikiproject = $wikiproject_alt if ($text !~ /^\s*$/); # guessed right now
  }

  # Sometimes things like "Armenian" --> "Armenia" are necessary
  if ($text =~ /^\s*$/ && $wikiproject =~ /n$/){
    $wikiproject_alt = $wikiproject; $wikiproject_alt =~ s/n$//g;
    $text=&wikipedia_fetch($wikiproject_alt . ".wiki", $attempts, $sleep);
    $wikiproject = $wikiproject_alt if ($text !~ /^\s*$/); # guessed right now
  }

  print "Wikiproject is $wikiproject<br><br>\n\n";
  return $wikiproject;
}

sub cmp_arts {
  my ($art1, $art2);
  $art1=shift; $art2=shift; 

  # sort by quality 
  if (! exists $Quality{$art1->{'quality'}}){
    print "Quality not defined at \'$art1->{'quality'}\'\n";
    return 0;
  }
  if (! exists $Quality{$art2->{'quality'}}){
    print "Quality not defined at \'$art2->{'quality'}\'\n";
    return 0;
  }

  # better quality articles come first
  return 1 if ($Quality{$art1->{'quality'}} > $Quality{$art2->{'quality'}}); 
  return -1 if ($Quality{$art1->{'quality'}} < $Quality{$art2->{'quality'}}); 

  # sort by importance now
  if (! exists $Importance{$art1->{'importance'}}){
    print "Importance not defined at \'$art1->{'importance'}\'\n";
    return 0;
  }
  if (! exists $Importance{$art2->{'importance'}}){
    print "Importance not defined at \'$art2->{'importance'}\'\n";
    return 0;
  }
      
  return 1 if ($Importance{$art1->{'importance'}} > $Importance{$art2->{'importance'}}); 
  return -1 if ($Importance{$art1->{'importance'}} < $Importance{$art2->{'importance'}}); 

  # store alphabetically articles of the same quality
  return 1 if ($art1->{'name'} gt $art2->{'name'});
  return -1 if ($art1->{'name'} lt $art2->{'name'});

  return 0;		      # the entries must be equal I guess
}

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

sub print_table_footer {
  my ($cat, $date);
  $date=shift; $cat = shift; 
  
  return '{{assessment footer|seealso=' . $See_also . ': [[:'
     . $cat . '|assessed article categories]]. |lastdate=' . $date . '}}' . "\n";
  
}

sub print_index_footer {
  my ($cat, $date);
  $date=shift; $cat = shift; 
  
  return '{{assessment index footer|seealso=' . $See_also . ': [[:'
     . $cat . '|assessed article categories]]. |lastdate=' . $date . '}}' . "\n";
  
}

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

sub print_current_category {
  my $category = shift;
  return '<noinclude>[[' . $category . ']]</noinclude>' . "\n";
}

sub current_date {

  my ($year);
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = gmtime();
  $year = 1900 + $yearOffset;
  return "$Months[$month] $dayOfMonth, $year";
}

sub most_recent_history_links_query {
  
  my ($articles, $latest_old_ids, $query_link, $link, $article, $article_enc, $max_no, $count,  $iter);

  $articles = shift;  $latest_old_ids = shift;

  $max_no = 5; # in each query find the most recent history link of max_no articles at once, to speed things up
  $query_link = $Wiki_http . '/w/query.php?format=txt&what=revisions&rvlimit=1&titles=';

  $count=0; $link = $query_link;
  foreach $article ( sort {$a cmp $b} keys %$latest_old_ids){
    
    $count++;
    
    # encode to html, but with plus signs instead of underscores
    $article_enc = $article; $article_enc = &html_encode ($article_enc); $article_enc =~ s/_/\+/g;
    
    # do a bunch of queries at once
    $link = $link . $article_enc . '|';
    
    # but no more than $max_no
    if ($count >= $max_no){
      
      $link =~ s/\|$//g; # strip last pipe
      
      # run the query
      &run_history_query ($link, $latest_old_ids);
      
      # reset
      $count=0; $link = $query_link; 
    }
  }
  
  # run it one last time for the leftover articles, if any
  $link =~ s/\|$//g; # strip last pipe
  &run_history_query ($link, $latest_old_ids) unless ($count == 0);
  
  # use the history id to create a link to the most recent article history link
  foreach $article ( keys %$latest_old_ids ){
    
    if (!exists $latest_old_ids->{$article} || $latest_old_ids->{$article} !~ /^\d+$/){
      print "---------Error in retrieving the latest history link of $article! "
	 .  "I got '" . $latest_old_ids->{$article} . "' as history link!<br>\n";
    }
    
    # compete the URL
    $articles->{$article}->{'hist_link'} = &old_id_to_hist_link ($latest_old_ids->{$article}, $article);
  }
}

# do a query of the form
# http://en.wikipedia.org//w/query.php?format=txt&what=revisions&rvlimit=1&titles=Main_Page|Mathematics
# and extract from there the lastest history ids of the titles in the link above
sub run_history_query {

  my ($link, $text, $error, $latest_old_ids, $article, $id, $entry, @entries, $count);

  $link = shift; $latest_old_ids = shift;
  
  print "Fetching $link<br>\n";
  ($text, $error) = &get_html($link);
  print "Sleep 1<br>\n"; sleep 1;

  @entries= split ("(?=\\[title\\])", $text);
  foreach $entry (@entries){
    next unless ($entry =~ /\[title\]\s*=\>\s*(.*?)\n.*?\[revid\]\s*=\>\s*(\d+)\n/is);
    
    $article = $1;
    $id = $2;
    $article =~ s/\s*$//g;

    # Unicode encoding seems to be necessary
    $article = encode('utf8', $article); 
    
    print "$article --> $id<br>\n";
    $latest_old_ids->{$article} = $id;

  }
}

# this subroutine and the one below read and write old_ids from disk. It is more reliable to have
# that info stored on disk in addition to Wikipedia

sub read_old_ids_from_disk {

  my ($old_ids_on_disk, $old_ids_file_name, $rev_file, $line, @lines, $sep, $article, $qual, $date, $old_id);
  my ($time_stamp, $command);
  
  ($old_ids_on_disk, $old_ids_file_name, $sep) = @_;

  # On en.wikipedia I use bzip2 to zip files. This won't work for scripts ran on Windows
  if ($Lang eq 'en'){
    if (-e "$old_ids_file_name.bz2" ){
      $command = "bunzip2 -fv \"$old_ids_file_name.bz2\"";
      print "$command" . "\n";
      print `$command` . "\n";
      print "Sleep 2\n"; sleep 2; 
    }
  }
  
  # read from disk
  if (-e "$old_ids_file_name" ){
    open(REV_READ_FILE, "<$old_ids_file_name"); @lines = split ("\n", <REV_READ_FILE>); close(REV_READ_FILE);
  }
  
  # get the data into the $old_ids_on_disk hash
  foreach $line (@lines){

    # parse the line and read the data
    next unless ($line =~ /^(.*?)$sep(.*?)$sep(.*?)$sep(.*?)$sep(.*?)$/);
    $article = $1; $qual = $2; $date = $3; $old_id = $4; $time_stamp = $5;

    $old_ids_on_disk->{$article}->{'quality'}=$qual;
    $old_ids_on_disk->{$article}->{'date'}=$date;
    $old_ids_on_disk->{$article}->{'old_id'}=$old_id;
    $old_ids_on_disk->{$article}->{'time_stamp'}=$time_stamp;
  }
}


sub write_old_ids_on_disk {

  my ($new_arts, $old_ids_on_disk, $list_name, $old_ids_file_name, $sep, $current_time_stamp, $article);
  my ($number_of_days, $seconds, $link, $command);

  ($new_arts, $old_ids_on_disk, $old_ids_file_name, $sep) = @_;

  $current_time_stamp = time();

  # update $old_ids_on_disk with information from $new_arts
  foreach $article (keys %$new_arts){

    $old_ids_on_disk->{$article}->{'quality'} = $new_arts->{$article}->{'quality'};
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

  # write to disk the updated old ids
  # do not write those old_ids with a time stamp older than $number_of_days
  $number_of_days = 10; 
  $seconds = 60*60*24*$number_of_days;

  open(REV_WRITE_FILE, ">$old_ids_file_name");
  print REV_WRITE_FILE "# Data in the order article, quality, date, old_id, time stamp in seconds, with '$sep' as separator\n";
  
  foreach $article (sort {$a cmp $b} keys %$old_ids_on_disk){

    # do not write the old_ids with a time stamp older than $number_of_days
    ## !!!!!!!!!!!!!!!!! Test the feature below!!!!!!!!!!!!
    next if ($old_ids_on_disk->{$article}->{'time_stamp'} < $current_time_stamp - $seconds);
    
    print REV_WRITE_FILE $article
       . $sep . $old_ids_on_disk->{$article}->{'quality'}
       . $sep . $old_ids_on_disk->{$article}->{'date'}
       . $sep . $old_ids_on_disk->{$article}->{'old_id'} 
       . $sep . $old_ids_on_disk->{$article}->{'time_stamp'}
       . "\n";
  }
  close(REV_WRITE_FILE);
  print "sleep 2\n"; sleep 2; # let the filesever have time to think
  
  # compress, to save space, but this won't work on Windows
  if ($Lang eq 'en'){
    $command = "bzip2 -fv \"$old_ids_file_name\"";
    print "$command" . "\n";
    print `$command` . "\n";
    sleep 2;
  }
}

sub old_id_to_hist_link {

  my ($old_id, $article) = @_;

  if ($old_id =~ /^\d+$/){
    return $Wiki_http  . '/w/index.php?title=' . &html_encode ($article) . '&oldid=' . $old_id;
  }else{
   return ""; 
  }

}

# given a link to a history version of a Wikipedia article
# of the form http://en.wikipedia.org/w/index.php?oldid=86978700
# get the article name (as the heading 1 title)

sub hist_link_to_article_name {

  my ($hist_link, $article_name, $text, $error);

  $hist_link = shift;

  if ( !$hist_link || $hist_link !~ /^\s*http.*?oldid=\d+/){
    print "Error! The following history link is invalid: $hist_link\n";
    return "";
  }

  ($text, $error) = &get_html ($hist_link);
  if ($text =~ /\<h1.*?\>(.*?)\</i){
    $article_name = $1;
  }else{
    print "Error! Could not get article name for $hist_link !!!<br>\n";
    exit(0);
  }

# Unicode encoding seems to be necessary
  $article_name = encode('utf8', $article_name); 

  return $article_name;
}

sub strip_cat {
  my $subject_category = shift;
  my $subject_sans_cat = $subject_category; $subject_sans_cat =~ s/^\Q$Category\E:(.*?) \Q$By_quality\E/$1/g;
  return $subject_sans_cat;
}

sub arttalk {
  my $article = shift;

  return '[[' . $article->{'name'} . ']] ([[' . $Talk . ':' . $article->{'name'} . '|' . lc ($Talk) . ']]) '
     . $article->{'quality'} . ' (' . $article->{'importance'} . ')';
}
   
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

