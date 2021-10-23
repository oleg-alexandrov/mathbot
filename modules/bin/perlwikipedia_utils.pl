# More robust routines for logging in, fetching Wikipedia text, and submitting
# than available with Perlwikipedia.

use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Encode;

# Use Pywikibot as the Perl module for that is out of date.
$ENV{'PYTHONPATH'} = '/data/project/shared/pywikibot/stable:/data/project/shared/pywikibot/stable/scripts';
$ENV{'PYWIKIBOT_DIR'} = '/data/project/mathbot';

binmode STDOUT, ':utf8'; # to not complain about printing wide characters

# Create a temporary file name
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

sub wikipedia_fetch {

  my $editor   = shift; 
  my $article  = shift;
  my $attempts = shift || 100;  # try that many times to get an article
  my $sleep    = shift || 5;    # how much to rest after each attempt (to not strain the server)
  
  $article =~ s/\.wiki$//g;  # backward compatibility
  $article =~ s/ /_/g; # do not use spaces

  # a temporary fix for a bug
  #$article =~ s/\&/%26/g;

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

      # Tell Pywikibot to do this job. All Unicode is hidden in the job file.     
      my $ans = qx(/usr/bin/python3 /data/project/mathbot/public_html/wp/modules/bin/pywikibot_task.py $job);
      my $return_code = $?;
      
      if ($return_code != 0) {
        print "Pywikibot failed at task '$task' with text: $ans\n";
        exit(1);
      }
      
      # Read the text fetchd and saved on disk by Pywikibot
      open my $fh, '<', $file or die "error opening $file: $!";
      $text = do { local $/; <$fh> };
      $text = Encode::decode('utf8', $text);
 
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

      gen_pywikibot_job($job, $article, $file, $task, $edit_summary);
  
      # Save the text on disk  
      open(FILE, ">", $file);
      binmode(FILE, ":utf8");
      print FILE $text;
      close(FILE);

      # Tell Pywikibot to do this job. All Unicode is hidden in the job file.     
      my $ans = qx(/usr/bin/python3 /data/project/mathbot/public_html/wp/modules/bin/pywikibot_task.py $job);
      my $return_code = $?;
      
      if ($return_code != 0) {
        print "Pywikibot failed at task '$task' with text: $ans\n";
        exit(1);
      }
      
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

# Mark the end of the module
1;
