# More robust routines for logging in, fetching Wikipedia text, and submitting
# than available with Perlwikipedia.

use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Encode;

# Use Pywikibot as the Perl module for that is out of date.
$ENV{'PYTHONPATH'} = '/data/project/shared/pywikibot/stable:/data/project/shared/pywikibot/stable/scripts';
$ENV{'PYWIKIBOT_DIR'} = '/data/project/mathbot';

binmode STDOUT, ':utf8'; # to not complain about printing wide characters

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
sub gen_file_name {
  return time() . "_" . rand() . "_tmp";
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
      
      if ($counter == 1){
	print "Fetching $article. <br>\n";
      }else{
	print "Fetching $article. Attempt: $counter. <br>\n";
      }
    
      my $file = gen_file_name();
      my $job  = $file . "_job";
      my $task = "fetch";
      my $edit_summary = "";

      gen_pywikibot_job($job, $article, $file, $task, $edit_summary);
      run_pywikibot($job);
      
      $text = read_file($file);
 
      # Wipe the temporary files
      unlink($file); 
      unlink($job);    
   };

    print "Sleep $sleep<br><br>\n\n";
    sleep $sleep;
    
    if ($counter > $attempts && $@){
      print "Tried $counter times and failed, bailing out\n";
      return "";
    }
    $counter++;
    
    print "Error message is: $@\n" if ($@);
  } until (!$@);
       
  return $text; 
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
    eval {
      
      if ($counter == 1){
	print "Submitting $article. <br>\n";
      }else{
	print "Submitting $article. Attempt: $counter. <br>\n";
      }
    
      my $file = gen_file_name();
      my $job  = $file . "_job";
      my $task = "submit";

      # Save the text on disk  
      open(FILE, ">", $file);
      binmode(FILE, ":utf8");
      print FILE $text;
      close(FILE);

      gen_pywikibot_job($job, $article, $file, $task, $edit_summary);
      run_pywikibot($job);
      
      # Wipe the temporary files
      unlink($file); 
      unlink($job);    
   };

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
  $cat =~ s/^Category://ig;

  # Outputs
  my $cats = shift;     @$cats = ();
  my $articles = shift; @$articles=();

  my $file = gen_file_name();
  my $job  = $file . "_job";
  my $task = "list_cat";

  # Gen the job
  open(FILE, ">", $job);
  binmode(FILE, ":utf8");
  print FILE "task: $task\n";
  print FILE "category name: $cat\n";
  print FILE "file name: $file\n";
  close(FILE);
  
  run_pywikibot($job);

  my %json = parse_json($file);
    
  my $cats_ptr = $json{"subcategories"};
  my $articles_ptr = $json{"articles"};

  # This is awkward, but not sure if there is a better way of copying
  # an array to a location at the given input pointer.
  @$cats = @$cats_ptr;
  @$articles = @$articles_ptr;

  # Wipe the temporary files
  unlink($file); 
  unlink($job);    
}

# Mark the end of the module
1;
