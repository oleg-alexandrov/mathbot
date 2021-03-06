# More robust routines for logging in, fetching Wikipedia text, and submitting
# than available with Perlwikipedia.

use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Carp qw(croak carp confess);
use MediaWiki::Bot;
#use Perlwikipedia; #Note that the 'p' is capitalized, due to Perl style
require  'bin/language_definitions.pl';
binmode STDOUT, ':utf8'; # to not complain about printing wide characters

sub wikipedia_login {
  print "Login at " . qx(date) . "\n";

  my $bot_name = shift || 'Mathbot'; # User Mathbot is no bot name is given

  my $Lang = 'en';
  if ($bot_name eq 'MathbotBeta'){
    $Lang = 'beta';
  }

  my %Dictionary = &language_definitions($Lang); # see the language_definitions.pl module

  my $pass = get_login_info($bot_name, $Dictionary{'Credentials'});

  my $wiki_http = $Dictionary{'Domain'};
  
  # Initiate agent
  #my $editor=Perlwikipedia->new($bot_name);
  my $editor=MediaWiki::Bot->new($bot_name); 

  # turn debugging on, to see what is going on
  $editor->{debug} = 1;

  # Set the language
  $editor->set_wiki($wiki_http,'w');
  print "<br><br>\n";

  # Create the cookies file if it does not exist. In either case, make sure it is read-only.
  my $cookies = ".perlwikipedia-$bot_name-cookies";
  if (! -e $cookies ){
    open(FILE, ">$cookies"); print FILE "#LWP-Cookies-1.0\n"; close(FILE);
  }
  chmod (0600, $cookies);

  # Do several attempts to log in
  my $counter=0;
  do {
    $counter++;
    
    eval {
      print "Logging in as $bot_name to $wiki_http ... <br><br>\n";
      my $res = $editor->login($bot_name, $pass);
      print "<br><br>\n";
      croak "Can't log in in as $bot_name! Result was \'$res\'. <br>\n"
	 unless ( defined ($res) && $res =~ /^0$/ );
    };
    print "Error is: $@\n" if ($@);
    
    if ($counter > 1) {
      print "Sleep 2<br><br>\n";
      sleep 2;
    }

    if ($counter > 100 && $@){
      print "Tried logging in $counter times, exiting.<br>\n";
      exit(0);
    }
    
  } until (!$@);
  
  return $editor;
}

sub wikipedia_fetch {

  my $editor   = shift; 
  my $article  = shift;
  my $attempts = shift || 100;  # try that many times to get an article
  my $sleep    = shift || 5;    # how much to rest after each attempt (to not strain the server)
  
  $article =~ s/\.wiki$//g;  # backward compatibility

  # a temporary fix for a bug
  #$article =~ s/\&/%26/g;

  my $text;
  my $counter=1;
  
  # exception handling
  do {
    eval {
      
      if ($counter == 1){
	print "Fetching $article. <br>\n";
      }else{
	print "Fetching $article. Attempt: $counter. <br>\n";
      }

      # Get text from the server, and check for errors.
      $editor->{errstr} = "";
      $text = $editor->get_text($article);
      if ($text =~ /^2$/ ){
	# Currently non-existent pages are marked with a "2"
        $text = "";
      }
      croak $editor->{errstr} . "\n" unless ($editor->{errstr} =~ /^\s*$/);

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
  
  $text =~ s/\s*$//g;
  my $server_text;

  # Check if the text to submit is the same as on server, in that case don't do anything.
  $server_text = $editor->get_text($article);
  #$server_text = Encode::encode('utf8', $server_text);
  $server_text =~ s/\s*$//g;
  
  if ( $text eq $server_text ){
    print "Won't submit $article to the server, as nothing changed<br>\n";
    print "sleep 1<br><br>\n";
    sleep 1;
    return;
  }

  # Exception handling
  my $counter=1;
  do {
    eval {

      if ($counter == 1){
	print "Submitting $article. <br>\n"; 
      }else{
	print "Submitting $article. Attempt: $counter. <br>\n";
      }

      # Submit. Overwrite whatever happened in between. May fail in case of edit conflict.
      $editor->edit($article, $text, $edit_summary);

      print "Sleep $sleep<br><br>\n\n";
      sleep $sleep;
      
      # fetch back what was just submitted, compare with what was supposed to be submitted. 
      $server_text = $editor->get_text($article);
      #$server_text = Encode::encode('utf8', $server_text);
      $server_text =~ s/\s*$//g;
      croak "What is on the server is not what was just submitted!\n" if ($text ne $server_text);
    };

    if ($counter > $attempts && $@){
      print "Tried $counter times, bailing out.\n";
      return 0; # failed
    }
    $counter++;

    print "Error message is: $@\n" if ($@);
  } until (!$@);

}

# this function and the one below are for backwards compatibility with older scripts
sub fetch_file_nosave {
  return &wikipedia_fetch (@_);
}

sub submit_file_nosave {
  return &wikipedia_submit (@_);
}

sub get_login_info{

  my $bot_name = shift;
  my $file     = shift;

  if (! -e $file ){ 
    print "Error: $file is missing\n";
    exit(1);
  }

  # Make sure nobody else can read the file
  chmod (0600, $file);

  open(FILE, "<$file");
  my @lines = <FILE>;
  close(FILE);

  my $text = join("\n", @lines);
  my $pass = "";  
  if ($text =~ /user\s+$bot_name\s+pass\s+(\w+)/is){
    $pass = $1;
  }else{
    print "Could not find the password for user $bot_name\n";
    exit(1);
 }

  return $pass;
}

# Mark the end of the module
1;
