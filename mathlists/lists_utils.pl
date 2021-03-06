use open 'utf8';

require 'read_from_write_to_disk.pl';
require 'bin/html_encode_decode_string.pl';
require 'bin/identify_redlinks.pl';
require 'bin/get_html.pl';

# given two hashes, return an array of elements in the first hash which are not in the second, and the other way aroun
sub see_diffs {

  my ($old_hash, $new_hash, $old_only, $new_only)=@_;
  my ($entry);

  @$old_only=();
  foreach $entry ( sort {$a cmp $b} keys %$old_hash){
    next if (exists $new_hash->{$entry});
    push (@$old_only, $entry);
  }

  @$new_only=();
  foreach $entry ( sort {$a cmp $b} keys %$new_hash){
    next if (exists $old_hash->{$entry});
    push (@$new_only, $entry);
  }
}

sub randomize_array {

  my (@array, @randomized_array);
  @array=@_;
  
  srand;
  @randomized_array = ();
  print "randomizing....\n";
  while (@array) {
    push(@randomized_array, splice(@array, rand @array, 1));
  }

  return @randomized_array;
}

sub split_into_sections {

  my ($articles, $iterator, $counter, $head, $head_old);
  $articles=shift; # pointer to hash containing the articles

  $counter=10000;   # count how many entries we have in the current section
  $head=""; # current section heading
  foreach $iterator (sort { $a cmp $b } keys %$articles) {

    $counter++; # keep on counting

    $head_old=$head; # prev heading
    $head = $iterator; $head =~ s/ .*?$//g; $head = "$head  "; # pad just in case, and put underscores
    $head = substr ($head, 0, 3); $head =~ s/^(.)(.*?)$/uc($1) . lc($2)/eg; # keep only three chars, start with cap
    $head =~ s/[^\w ]/ /g; # replace non-word non-space with space

    # do not even consider putting a new heading unless we are at a natural boundary and have > 50 entries
    next if ($head eq $head_old || $counter < 30 );

    $articles->{$iterator} = "\n== $head ==\n\n" . "$articles->{$iterator}"; # slap a section heading
    $counter=0; # restart counting
  }
}

sub read_categories_from_list{
  
  my ($separator, $count, $line, $list_of_categories, @lines);
  my @arrays=splice(@_, 0, 3);  # contains pointers to three arrays, for mathematics, mathematicians and other categories
  $list_of_categories=shift;

  # Separate the three kinds of categories contained in the list using $separator
  $separator='<!-- separator -->';  

  open(FILE, "<$list_of_categories"); @lines = split ("\n", <FILE>); close(FILE);
  $count=0;
  foreach $line (@lines){
    $count++ if ($line =~ /$separator/); # move to the next array of categories
    last if ($count >=3);
    next unless ($line =~ /^\[\[:(Category:.*?)(\||\]\])/i);
    push (@{$arrays[$count]}, $1);
  }
}

sub put_redirects_on_blacklist {
  my ($Editor, $blacklist, $articles_from_cats_file, $articles_from_cats)=@_;
  my ($article, $file, @lines, %today_from_cats_hash, @yesterday_from_cats, $text);
  my ($sleep, $attempts);

  # Necessary to fetch data from Wikipedia and submit. Don't make too many attempts.
  $sleep = 5; $attempts=10; 
  
  # put articles which are in categories today in a hash
  foreach $article (@$articles_from_cats){ $today_from_cats_hash{$article}=1;  }

  # put articles which were in a category yesterday in an array
  open(FILE, "<$articles_from_cats_file");
  @yesterday_from_cats = split("\n", <FILE>);
  close(FILE);

  # Data was written to disk encoded in html (see later in this function).
  # Here decode it back.
  foreach $article (@yesterday_from_cats){
    $article = &html_decode_string ($article);  
  }

  # Sort yesterday's articles in categories
  @yesterday_from_cats = sort {$a cmp $b} @yesterday_from_cats;
  
  # Now the subtle part, articles which were in categories yesterday
  # but which are not there today, could be redirects. If if they so,
  # remove them.
  foreach $article (@yesterday_from_cats){

    next if ($article =~ /^\s*$/);
    next if (exists $today_from_cats_hash{$article});

    # Try to investigate why an article would suddenly vanish from math categories
    $file = $article . '.wiki';
    $text=wikipedia_fetch($Editor, $file, $attempts, $sleep);

    if ($text =~ /^\s*$/){
#      $blacklist->{$article} = '(redlink or blank article)';
    }elsif ($text =~ /^\s*\#redirect\s*\[\[(.*?)(\]\]|\||\#)/i){
      $blacklist->{$article} = "(is a redirect to \[\[$1\]\])";
#    }elsif ($text =~ /\{\{disambig\}\}/i){
#      $blacklist->{$article} = '(is a disambiguation page)';
    }

    # Store a copy of the aricle on disk, since it was downloaded anyway
    &write_to_disk($article, $text); 
  }

  # Sort before writing to disk
  @$articles_from_cats = sort {$a cmp $b} @$articles_from_cats;
     
  # lastly, what is today's articles will become yesterday's articles tomorrow   
  open (FILE, '>', $articles_from_cats_file);
  foreach $article (@$articles_from_cats){
    # Write html-encoded to disk, since it is hard to get it right reading/writing
    # Unicode data on disk.
    print FILE &html_encode_string ($article) . "\n";
  }
  close(FILE);
}

sub put_redlinks_on_blacklist{ 
  my ($prefix, $text, $red, @reds, $article, $link, $letter, $letters, $blacklist, $error);
  my (@tmp_reds, @tmp_blues);
  
  $prefix=shift; $letters=shift; $blacklist=shift;

  # extract the redlinks
  foreach $letter (@$letters) {

    $article = $prefix . ' (' . $letter . ')';
    &identify_redlinks ($article, \@tmp_reds, \@tmp_blues);
    @reds = (@reds, @tmp_reds);
  }

  foreach $red (@reds){
    
    # Important, this line must be in! Many articles have red talk pages!
    next if ($red =~ /talk:/i);

    print "[[$red]] got blacklisted!\n";
    $blacklist->{$red}='(article deleted/does not exist)' unless exists ($blacklist->{$red});
  }
}

sub process_log_of_todays_changes  {
  my ($line, $text, $todays_log, $date);
  my (%all_yesterday_articles, @old_only, @new_only, $comment);
  my ($all_today_articles, $blacklist, $all_math_arts_file)=@_;
  
  # first, read $all_math_arts_file, which has the list from yesterday. Put into hash.
  open (FILE, "<$all_math_arts_file"); $text=<FILE>; close(FILE);
  foreach $line (split ("\n", $text)){
    next if ($line =~ /^\s*$/); # ignore empty lines
    $all_yesterday_articles{$line}=1;
  }

  #second, see which entries from yesterday are not in today's list, and the other way round
  &see_diffs (\%all_yesterday_articles, $all_today_articles, \@old_only, \@new_only);

  # Create today's log
  $date=&current_date();
  $todays_log = "== $date ==\n\n";

  # removed articles. Add an explanation if there is any
  foreach $line (@old_only){
    $comment=""; $comment = $blacklist->{$line} if (exists $blacklist->{$line});
    $todays_log = $todays_log . ":Removed \[\[$line\]\] $comment\n";
  }

  # added articles
  foreach $line (@new_only){
    $todays_log = $todays_log . ":Added   \[\[$line\]\]\n";
  }

  # very important, write today's articles to file, to use it for comparison with tomorrow's articles
  open(FILE, ">$all_math_arts_file");
  foreach $line (sort {$a cmp $b} keys %$all_today_articles){
    print FILE "$line\n";
  }
  close(FILE);

  return $todays_log;
}

sub current_date {

  my ($year);
  my  @Months=("January", "February", "March", "April", "May", "June",
               "July", "August",  "September", "October", "November", "December");
  
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
  
  $year = 1900 + $yearOffset;

  return "$Months[$month] $dayOfMonth, $year";
}


1;
