# More robust routines for logging in, fetching Wikipedia text, and submitting
# than available with Perlwikipedia.

use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Encode;
use Time::HiRes;

# Use Pywikibot as the Perl module for that is out of date.
$ENV{'PYTHONPATH'} = '/shared/pywikibot/core:/shared/pywikibot/core/externals/httplib2:/shared/pywikibot/core/scripts';
$ENV{'PYWIKIBOT_DIR'} = '/data/project/mathbot';

$ENV{'PYTHONIOENCODING'} = 'utf8'; # to make Python print unicode on screen
   
binmode STDOUT, ':utf8'; # For Perl to not complain about printing wide characters

# Read file in Unicode format
sub read_file {
  my $file = shift;

  open my $fh, "<:encoding(UTF-8)", $file or die "Error opening $file: $!";
  my $text = do { local $/; <$fh> };

  return $text;
}

# Prase a file in json-like format
sub parse_json {

  my $file = shift;
  my $text = read_file($file);
  my @lines = split("\n", $text);

  my %entries;
  my $key = "";
  my $val = "";
  foreach my $line (@lines){

    if ($line =~ /^\s*$/){
      next;
    }
    
    if ($line =~ /^\s+(.*?)$/){
      
      $val = $1;
      
      if ($val =~ /^\s*$/){
        next;
      }

      if ($key eq ""){
        print "Error: Found a value before there was a key.\n";
        exit(1);
      }

      if (!exists $entries{$key}){
        print "Error: Key does not exist.\n";
        exit(1);
      }

      my $ptr = $entries{$key}; # pointer to array
      push(@$ptr, $val);

    } else {
      
      if ($line =~ /^([^\s].*?):$/) {

        $key = $1;
        
        if (exists $entries{$key}){
          print "Key $key found before.\n";
          exit(1);
        }
        
        my @vals = ();
        $entries{$key} = \@vals; # pointer to array
        
      } else {
        print "Unexpected text: $line\n";
        exit(1);
      }
    }
  }

  return %entries;
}

# Create a unique temporary file name
sub gen_temp_local_file_name {

  my ($seconds, $microseconds) = Time::HiRes::gettimeofday;
  
  return $seconds . "_" . $microseconds . "_" . rand() . "_tmp";
}

# Linux does not like to be passed Unicode or binary strings on the command line
# or as file names. Hence, create a unique filename made up of ascii characters
# where we will write some text, potentially in Unicode, telling Pywikibot what 
#to do.
sub gen_pywikibot_job {

  my $job_name      = shift;
  my $article_name  = shift;
  my $file_name     = shift;
  my $task          = shift;
  my $edit_summary  = shift;

  open(FILE, ">", $job_name);
  binmode(FILE, ":utf8");
  print FILE "article name: $article_name\n";
  print FILE "file name: $file_name\n";
  print FILE "task: $task\n";
  print FILE "edit summary: $edit_summary\n";
  close(FILE);
}

sub run_pywikibot {
  my $job = shift;
  
  my $ans = qx(/usr/bin/python3 /data/project/mathbot/public_html/wp/modules/bin/pywikibot_task.py $job);
  my $return_code = $?;
      
  if ($return_code != 0) {
    print "Pywikibot failed with text: $ans\n";
    exit(1);
  }

  return $ans;
}

sub wikipedia_fetch {

  my $editor   = shift; 
  my $article  = shift;
  my $attempts = shift || 100;  # try that many times to get an article
  my $sleep    = shift || 5;    # how much to rest after each attempt (to not strain the server)
  
  $article =~ s/\.wiki$//g;  # backward compatibility
  $article =~ s/ /_/g; # do not use spaces

  my $text;
  my $counter = 1;
  
  # exception handling
  do {
    eval {
    
      my $file = gen_temp_local_file_name();
      my $job  = $file . "_job";
      my $task = "fetch";
      my $edit_summary = "";
      
      if ($counter == 1){
	print "Fetching $article. <br>\n";
      }else{
	print "Fetching $article. Attempt: $counter. <br>\n";
      }

      gen_pywikibot_job($job, $article, $file, $task, $edit_summary);
      run_pywikibot($job);
      
      $text = read_file($file);
    };
       
    # Wipe the temporary files. Do this after catching any exceptions,
    # as otherwise files fail to get wiped.
    unlink($file); 
    unlink($job);    

    # Don't sleep here, pywikibot will take care of that 
    #print "Sleep $sleep<br><br>\n\n";
    #sleep $sleep;
    
    if ($counter > $attempts && $@){
      print "Tried $counter times and failed, bailing out\n";
      return "";
    }
    $counter++;
    
    print "Error message is: $@\n" if ($@);
  } until (!$@);
       
  return $text; 
}   

# Fetch a lot of articles at teh same time. Return an array with their text.
sub wikipedia_fetch_many {

  my $article_names  = shift;
  my $article_text   = shift;

  # Initialize the output
  @$article_text = ();
  
  foreach my $article (@$article_names){
    $article =~ s/\.wiki$//g;  # backward compatibility
  }

  my $file = gen_temp_local_file_name();
  my $job  = $file . "_job";
  my $task = "fetch_many";

  # Manufacture a file name for each article we will write
  my @article_files;
  my $count = 10000;
  foreach my $article (@$article_names){
    
    my $article_file = gen_temp_local_file_name() . "_" . $count;
    push(@article_files, $article_file);
    
    $count++;
  }
  
  # Gen the job. Note that it has a multi-line component.
  open(FILE, ">", $job);
  binmode(FILE, ":utf8");
  print FILE "task: $task\n";
  print FILE "article_names:\n"; # multiline
  foreach my $article (@$article_names){
    print FILE "  $article\n";
  }
  print FILE "article_files:\n"; # multiline
  foreach my $article_file (@article_files){
    print FILE "  $article_file\n";
  }
  close(FILE);

  #print "Job file is $job\n";

  eval { # catch any exception
    my $ans = run_pywikibot($job);
  }; 
  #print "answer is $ans\n";
  
  foreach my $article_file (@article_files){
    eval {
      my $text = read_file($article_file);
      push(@$article_text, $text);
    };
    
    # Wipe the temporary files
    unlink($file);
  }
  
  # wipe the job
  unlink($job);    
  
}   

sub wikipedia_submit {

  my $editor        = shift; 
  my $article       = shift;
  my $edit_summary  = shift;
  my $text          = shift;
  my $attempts      = shift || 100;  # try that many times to get an article
  my $sleep         = shift || 5;    # how much to rest after each attempt (to not strain the server)
 
  $article =~ s/\.wiki$//g;  # backward compatibility

  # a temporary fix for a bug
  #$article =~ s/\&/%26/g;

  # Wipe trailing whitespace  
  $text =~ s/\s*$//g;

  print "Article name is $article\n";
 
  my $counter = 1;
  
  # exception handling
  do {
    
    my $file = gen_temp_local_file_name();
    my $job  = $file . "_job";
    my $task = "submit";
    
    eval {
      
      if ($counter == 1){
	print "Submitting $article. <br>\n";
      }else{
	print "Submitting $article. Attempt: $counter. <br>\n";
      }
      
      # Save the text on disk  
      open(FILE, ">", $file);
      binmode(FILE, ":utf8");
      print FILE $text;
      close(FILE);

      gen_pywikibot_job($job, $article, $file, $task, $edit_summary);
      run_pywikibot($job);
    };
       
    # Wipe the temporary files, after catching any exceptions
    unlink($file); 
    unlink($job);    

    print "Sleep $sleep<br><br>\n\n";
    sleep $sleep;
    
    if ($counter > $attempts && $@){
      print "Tried $counter times and failed, bailing out\n";
      return "";
    }
    $counter++;
    
    print "Error message is: $@\n" if ($@);
  } until (!$@);
       
  return;
}

sub fetch_articles_and_cats {

  # Input
  my $cat = shift;

  # Outputs
  my $cats = shift;     @$cats = ();
  my $articles = shift; @$articles=();

  my $file = gen_temp_local_file_name();
  my $job  = $file . "_job";
  my $task = "list_cat";

  # Gen the job
  open(FILE, ">", $job);
  binmode(FILE, ":utf8");
  print FILE "task: $task\n";
  print FILE "category name: $cat\n";
  print FILE "file name: $file\n";
  close(FILE);

  eval {
    run_pywikibot($job);
  };
  
  my %json = parse_json($file);
    
  my $articles_ptr = $json{"articles"};
  my $cats_ptr = $json{"subcategories"};

  # This is awkward, but not sure if there is a better way of copying
  # an array to a location at the given input pointer.
  @$articles = @$articles_ptr;
  @$cats = @$cats_ptr;

  # Wipe the temporary files
  unlink($file); 
  unlink($job);    
}

sub fetch_articles_in_cats {

  # Inputs
  my $cats = shift;

  # Outputs
  my $new_articles = shift; @$new_articles = ();
  my $new_cats = shift;     @$new_cats = ();

  # Gen the job
  my $file     = gen_temp_local_file_name();
  my $job      = $file . "_job";
  my $progress = $file . "_progress";
  
  my $task = "list_cats";

  # Gen the job. Note that it has a multi-line component.
  open(FILE, ">", $job);
  binmode(FILE, ":utf8");
  print FILE "task: $task\n";
  print FILE "categories:\n"; # multiline
  foreach my $cat (@$cats){
    print FILE "  $cat\n";
  }
  print FILE "file name: $file\n";
  print FILE "progress file: $progress\n";
  close(FILE);

  print "Job file is $job\n";
  print "Track progress in $progress. Not implemented yet.\n";

  eval {
    my $ans = run_pywikibot($job);
    # print "Got the answer $ans\n";
  };
     
  my %json = parse_json($file);
  
  my $articles_ptr = $json{"articles"};
  my $cats_ptr = $json{"subcategories"};
  
  # This is awkward, but not sure if there is a better way of copying
  # an array to a location at the given input pointer.
  @$new_articles = @$articles_ptr;
  @$new_cats = @$cats_ptr;

  # Wipe the temporary files
  unlink($file); 
  unlink($job);    
  
}

# Mark the end of the module
1;
