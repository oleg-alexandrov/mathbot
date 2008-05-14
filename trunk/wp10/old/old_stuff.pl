#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
undef $/; # undefines the separator. Can read one whole file in one scalar.

# The two routines below back up on disk all lists submitted to Wikipedia for the last 5 days.
# So in case the bot goes mad, it can be reverted.
# The code is more complicated because I have to scp all the data to a drive on my machine
# from the machine on which the code is running.
# These two routines would need some work to be ported to Windows. 

sub prepare_for_backup {

  my ($cur_date_dir, $old_date_dir, $dir_path, $scp, $addr, $ssh, $host, @date_dirs, $command, $date_dir, $wp_dir, $backup_data, $lists, $category);
  my ($list_dir);
  
  $backup_data = shift;
  $lists = shift;
  
  $cur_date_dir = &date_with_numbers (0);
  $old_date_dir = &date_with_numbers (-5);

  $host = 'aoleg@blythe.math.ucla.edu';
  $dir_path = '/m1/aoleg/wp/backup_wp10';
  $wp_dir = 'Wikipedia:Version_1.0_Editorial_Team';
  
  $ssh = 'ssh ' . $host . " ";

  # Start by removing any old directories
  $command = $ssh . "ls $dir_path";
  print "$command<br>\n";
  @date_dirs = split ("\n", `$command`);

  foreach $date_dir (@date_dirs){

    # below we will do a big delete. Make sure as hell we delete the right thing!
    if ($dir_path !~ /\/m1\/aoleg\/wp\/backup_wp10/ ){
      print "Wrong directory $dir_path!!! Exiting!<br>\n";
      exit(0);
    }

    next unless ($date_dir =~ /^\d\d\d\d-\d\d-\d\d$/);    # delete only directories of this form
    next unless ($date_dir lt $old_date_dir);             # delete only directories older than $old_date_dir    
    next if ($wp_dir =~ / /);                             # must not have any spaces in here  

    # delete the subdirectories in 2006-11-26/Wikipedia:Version_1.0_Editorial_Team/ together with the files in those subdirectories
    foreach $category (sort {$a cmp $b} keys %$lists){

      $list_dir = $lists->{$category}; $list_dir =~ s/\.wiki$//g;
      $list_dir =~ s/ /_/g; $list_dir = &html_encode($list_dir); # encode for safety
      $list_dir =~ s/\%2f/\//g; # but not the slash

      $command = $ssh . "rm -fv $dir_path\/$date_dir\/$list_dir\/*.wiki";    print "$command<br>\n"; print `$command` . "<br>\n";
      $command = $ssh . "rmdir  $dir_path\/$date_dir\/$list_dir";            print "$command<br>\n"; print `$command` . "<br>\n";
      print "Sleep 1<br>\n"; sleep 1;
    }
    
    # delete 2006-11-26/Wikipedia:Version_1.0_Editorial_Team/, then its parent 2006-11-26
    $command = $ssh . "rm   -fv $dir_path\/$date_dir\/$wp_dir\/*.wiki";      print "$command<br>\n"; print `$command` . "<br>\n";
    $command = $ssh . "rmdir -v $dir_path\/$date_dir\/$wp_dir";              print "$command<br>\n"; print `$command` . "<br>\n";
    $command = $ssh . "rmdir -v $dir_path\/$date_dir";                       print "$command<br>\n"; print `$command` . "<br>\n";
    
  }
  
  # Having cleaned up old stuff, make a directory for today's date, and a subdirectory for $wp_dir, and subdirectories in that for every list
  $command = $ssh . "mkdir $dir_path\/$cur_date_dir\/";                      print "$command<br>\n"; print `$command` . "<br>\n";
  $command = $ssh . "mkdir $dir_path\/$cur_date_dir\/$wp_dir";               print "$command<br>\n"; print `$command` . "<br>\n";

  foreach $category (sort {$a cmp $b} keys %$lists){
    $list_dir = $lists->{$category}; $list_dir =~ s/\.wiki$//g;
    $list_dir =~ s/ /_/g; $list_dir = &html_encode($list_dir); # encode for safety
    $list_dir =~ s/\%2f/\//g; # but not the slash

    $command = $ssh . "mkdir $dir_path\/$cur_date_dir\/$list_dir";   print "$command<br>\n"; print `$command` . "<br>\n";
    print "Sleep 1<br>\n"; sleep 1;
  }
  
  # save some info which we will need in the future
  $backup_data->{'cur_date_dir'} = $cur_date_dir;
  $backup_data->{'host'} = $host;
  $backup_data->{'dir_path'} = $dir_path;
  return;
}

sub backup_this_file{
     
  my ($file, $text, $backup_data, $cur_date_dir, $host, $dir_path, $tmp_file, $command);
  
  $file = shift;  $text = shift;  $backup_data = shift;

  # encode to html to get rid of unsafe stuff
  $file =~ s/ /_/g; $file = &html_encode($file);
  $file =~ s/\%2f/\//g; # but not the slash

  $cur_date_dir = $backup_data->{'cur_date_dir'};
  $host = $backup_data->{'host'};
  $dir_path = $backup_data->{'dir_path'};

  $tmp_file = '/tmp/wikifile';
  open(TMP_FILE, ">$tmp_file"); print TMP_FILE $text; close(TMP_FILE);
  
  $command ="scp $tmp_file $host:$dir_path\/$cur_date_dir\/$file";
  print "$command<br>\n"; print `$command` . "<br>\n";
     
}

sub date_with_numbers {  # returns a date in the format 2006-12-25

  my $days_in_future = shift;
  
  my ($year);
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings)
     = gmtime( time() + $days_in_future*24*60*60 );

  $year = 1900 + $yearOffset;
  $month = $month + 1; $month = '0' . $month if ($month < 10);
  $dayOfMonth = '0' . $dayOfMonth if ($dayOfMonth < 10);
  
  return "$year-$month-$dayOfMonth";
  
}

sub print_table_of_quality_importance_data{

  my $subject_category = shift; my $count_hash = shift;  my $two_D=shift;
  my ($subject_sans_cat, $text, $key, $key_noclass, %map, @articles, $category, @categories);

  $subject_sans_cat = &strip_cat ($subject_category);
  
  # A lot of fuss below all for the sake of making some links in the statistics.
  # Now find a map from classes to categories.
  &fetch_articles_cats($subject_category, \@categories, \@articles);
  foreach $category (@categories){
    next unless ($category =~ /\Q$Category\E:(.*?-Class|Unassessed)/i);
    $key=$1; $key =~ s/class/Class/g; # upcase
    $category =~ s/^\Q$Category\E://ig; # strip the cat

    $map{$key}=$category; 
  }

  $text="\{\| class=\"wikitable\"\n\|\+ \'\'\'$subject_sans_cat\'\'\'\n\|-\n";

  $text = $text . "\! colspan=\"2\" \| Quality\n\|-\n";
  foreach $key (sort {$quality{$a} <=> $quality{$b}} keys %quality ){
    next unless (exists $count_hash->{$key});
  
    if ($subject_sans_cat eq "All projects") { # this is for the big table totalling all the stats
       
       $text = $text . "\|\{\{$key\}\} \|\| $count_hash->{$key}\n\|-\n";

    } else { # this is for a specific subject. Then use $key (which is a template) with an argument, to create the link
       
       $key_noclass = $key; $key_noclass =~ s/-Class//ig; 
       if (exists $map{$key}){
         $text = $text . "\|\{\{$key\|category=$map{$key}\|$key_noclass\}\} \|\| $count_hash->{$key}\n\|-\n";
       }else{
         $text = $text . "\|\{\{$key\}\} \|\| $count_hash->{$key}\n\|-\n";
       }
     }
  }

  $text = $text . "\! colspan=\"2\" | Importance\n\|-\n";
  foreach $key (sort {$importance{$a} <=> $importance{$b}} keys %importance ){
    next unless (exists $count_hash->{$key});
    
    # Either all importance rows have zero, then add them all, or add in only the importance rows with nonzeros
    next if ($key =~ /\Q$No_Class\E/i || ($count_hash->{'All-importance'} > 0 && $count_hash->{$key} == 0 ));
    $text = $text . "\|\{\{$key\}\} \|\| $count_hash->{$key}\n\|-\n";
  }

  $text = $text . "\! colspan=\"2\" \| Total: $count_hash->{'All-quality'}\n";
  $text = $text . "\|\}\n\n";

  return $text;
}


# old way of fetching the most recent history link of an article, and the debugger for it
sub most_recent_hist_version {
  my ($article, $text, $error, $link, $title);

  $article = shift;

  $title = &html_encode($article);
  $link = $Wiki_http . '/w/index.php?title=' . $title . '&action=history';
  print "Getting $link<br>\n";
  ($text, $error) = &get_html ($link);

  if ($text =~ /(\/w\/index\.php\?title=\Q$title\E\&amp;oldid=\d+)/i){

    $link = $Wiki_http . $1;
    $link =~ s/\&amp;/\&/g;
  }else{
    print "Error! Could not find the history link for $article!!!\n";
   $link = ""; 
  }

  print "Sleep 1<br>\n"; sleep 1;
  return $link;
}

sub most_recent_history_links {
  
  my ($articles, $latest_old_ids,  $link, $article, $article_enc, $max_no, $count, $continue, $iter, $max_iter);
  my (%debug, $hist_link);
  
  $articles = shift;  $latest_old_ids = shift;

  # below are pure hacks, for testing purposes, will remove all that
  # ugly code soon
  my $debug_count = 0;
  my $problem_issue = 1;
  while ($problem_issue == 1){

    $problem_issue = 0;
    
    foreach $article ( sort {$a cmp $b} keys %$latest_old_ids){
      $hist_link = &most_recent_hist_version($article);
      $articles->{$article}->{'hist_link'}= $hist_link;
      
      # for debugging
      $debug{$article} = $hist_link;
    }
    
    # compare the above with most_recent_history_links which is supposed to be equivalent but faster
    # this is done for debugging purposes
    &most_recent_history_links_query ($articles, $latest_old_ids);
    my ($id1, $id2);
    foreach $article ( sort {$a cmp $b} keys %$latest_old_ids){
      
      $id1 = $articles->{$article}->{'hist_link'};
      $id2 = $debug{$article};
      if ($id1 =~ /oldid=(\d+)/){
	$id1 = $1;
      }
      if ($id2 =~ /oldid=(\d+)/){
	$id2 = $1;
      }
      
      if ($id1 eq $id2){
	print "------------------------------------The two codes give the same history link for \[\[$article\]\].\n";
      }else{
	print "------------------------------Error! The two codes give different results for \[\[$article\]\]!!!\n";
	print "Old code gives:\n" . $id1
	   . "\nBut new code gives:\n" . $id2 . "\n";

	$problem_issue = 1;
	if ($debug_count < 1000){
	  $debug_count++;
	}else{
	  exit(0);
	}
      }
    }
  }
}

