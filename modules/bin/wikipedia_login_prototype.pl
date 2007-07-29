# routine to log in to Wikipedia
use Carp qw(croak carp confess);
use WWW::Mediawiki::Client;   # low level routings for downloading and uploading text.
require  'bin/language_definitions.pl';

sub wikipedia_login {

  use constant WIKIPEDIA_DEFAULTS_login =>
   'space_substitute' => '+',
   'action_path' => 'w/wiki.phtml?action=submit&title=',
   'edit_path' => 'w/wiki.phtml?action=edit&title=',
   'login_path' => 'w/wiki.phtml?action=submit&title=Special:Userlogin',
   ;

  # if this function was called as wikipedia_login('Bot_name'), that argument becomes
  # the bot name. Otherwise, use 'DefaultBot' as the bot name.
  my $bot_name;
  if (@_){
    $bot_name = shift;
  }else{
   $bot_name = 'DefaultBot'; # default user
  }

  # Define some keywords. Users of this bot on languages other than English need to check the
  # 'bin/language_definitions.pl' package to make sure their language is covered.
  my %Dictionary = &language_definitions();
  my $Lang = $Dictionary{'Lang'};
  
  my $wiki_http='http://' . $Lang . '.wikipedia.org';
  my $opt_u=$bot_name;
  my $opt_p="DefaultPassword";
  my $command='login';
  my $method= "do_$command";
  
  # create the init array, and maybe pre-populate it
  my @init = WIKIPEDIA_DEFAULTS_login; 

  print "Logging in as $opt_u to $wiki_http ... <br><br>\n";

  my $counter=0;
  my $error;
  do {
    $counter++;

    eval {

      # instanciate a WWW::Mediawiki::Client obj
      my $wmc = WWW::Mediawiki::Client->new(@init);
      
      $wmc->site_url($wiki_http) if $wiki_http;
      $wmc->username($opt_u) if $opt_u;
      $wmc->password($opt_p) if $opt_p;
      
      # run command
      $wmc->$method(@_);
      
      # these encode sensitive information
      chmod (0600, '.mediawiki', '.mediawiki_cookies.dat');
      
    };
    
    if ($counter >= 2) {
      $error = $@;
      print "Error: $error\n";
      print "Current attempt: $counter<br><br>\n";

      if ($error =~ /corrupted config file/){
	print "Failed to log in. Deleting corrupted config file.\n";
	unlink ('.mediawiki');
      }

      print "Sleep 2<br><br>\n";
      sleep 2;
    }

    if ($counter > 100){
      print "Tried $counter times, bailing out\n";
      exit(0);
    }
    
  } until (!$@);
}
1;
