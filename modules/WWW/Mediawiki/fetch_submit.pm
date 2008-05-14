use utf8;
use open ':utf8'; # input/output in unicode

sub fetch_file {
  local undef $/; # undefines the separator. Can read one whole file in one scalar.

  my ($text, @lines, $file, @init, $method, $wmc, $bailout, $sleep);
 
  $file=shift;
  
  if ( @_  >= 1 ){
    $bailout=shift;
  }else{
   $bailout=100;
  }

  if ( @_  >= 1 ){ $sleep=shift; }   else{ $sleep=2; }
  
  # rm the file and get new copy, so that we make sure we
  # will modify a really fresh version
  
  `rm -fv \"$file\"`;
  
  # update the files to be modified (copied from the mvs
  # package)

  @init=();

  my $counter=1;
  do {
    eval {

      print "Fetching $file. Attempt: $counter. <br>\n"; $counter++;

      $method= "do_update";
      $wmc = WWW::Mediawiki::Client->new(@init);
      $wmc->$method($file);
      
      open (MEDIAWIKI_FILE_HANDLE, "<:utf8", "$file") || print "$file does not exist";
      $text = <MEDIAWIKI_FILE_HANDLE>;
      close(MEDIAWIKI_FILE_HANDLE);
    };

    print "Sleeping for $sleep seconds<br><br>\n";
    `sleep $sleep`;
    
    if ($counter > $bailout){
      print "Tried $counter times, now really, bailing out\n";
      return "";
    }

    print "Error message is: $@\n" if ($@);;

  } until (!$@);
  
       
  return $text; 
  
}   

sub submit_file {

  local undef $/; # undefines the separator. Can read one whole file in one scalar.

  use constant MY_WIKIPEDIA_DEFAULTS =>
   'space_substitute' => '+',
   'action_path' => 'w/wiki.phtml?action=submit&title=',
   'edit_path' => 'w/wiki.phtml?action=edit&title=',
   'login_path' => 'w/wiki.phtml?action=submit&title=Special:Userlogin',
   ;

  my $file=shift;
  my $opt_m=shift;
  my $command='commit';
  my $method= "do_$command";
  
  my $bailout;
  if ( @_  >= 1 ){
    $bailout=shift;
  }else{
    $bailout=100;
  }

  my $sleep; 
  if ( @_  >= 1 ){ $sleep=shift; }   else{ $sleep=2; }
  
  my $counter=1;
  do {
    eval {
      print "Submitting $file. Attempt: $counter. <br>\n"; $counter++;

      # create the init array, and maybe pre-populate it
      my @init = MY_WIKIPEDIA_DEFAULTS;
      
      # instanciate a WWW::Mediawiki::Client obj
      my $wmc = WWW::Mediawiki::Client->new(@init);
      
      $wmc->commit_message($opt_m);
      $wmc->$method($file);
      
      print "Sleeping for $sleep seconds<br><br>\n";
      `sleep $sleep`;
    };

    if ($counter > 100){
      print "Tried $counter times, bailing out\n";
      return "";
    }

  } until (!$@);

}


1;
