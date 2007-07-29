# routines to fetch text from Wikipedia and upload text back.
use Carp qw(croak carp confess);
use WWW::Mediawiki::Client;   # low level routings for fetching and uploading text.

use constant WIKIPEDIA_DEFAULTS_constant =>
   'space_substitute' => '+',
   'action_path' => 'w/wiki.phtml?action=submit&title=',
   'edit_path' => 'w/wiki.phtml?action=edit&title=',
   'login_path' => 'w/wiki.phtml?action=submit&title=Special:Userlogin',
   ;


sub wikipedia_fetch {
  local undef $/; # undefines the separator. Can read one whole file in one scalar.
  my ($text, $file, @init, $wmc, $bailout, $counter, $sleep);
 
  $file=shift;
  $file =~ s/ \& / \%26 /g; # a temporary hack, encode the ampersand
  
  if ( @_  >= 1 ){ $bailout=shift; } else{ $bailout=100; }
  if ( @_  >= 1 ){ $sleep=shift; }   else{ $sleep=2; }
  
  @init = WIKIPEDIA_DEFAULTS_constant;
  $counter=1;
  
  # exception handling
  do {
    eval {
      if ($counter == 1){ print "Fetching $file. <br>\n"; }else{ print "Fetching $file. Attempt: $counter. <br>\n"; }

      $wmc = WWW::Mediawiki::Client->new(@init);
      croak "No server URL specified." unless $wmc->{site_url};
      print { $wmc->{debug_fh} } "Updating: $file\n";
      $wmc->_check_path($file);
      $text = $wmc->_get_server_page($file); 
    };

    print "Sleep $sleep<br><br>\n\n";
    sleep $sleep;
    
    if ($counter > $bailout && $@){
      print "Tried $counter times and failed, bailing out\n";
      return "";
    }
    $counter++;
    
    print "Error message is: $@\n" if ($@);
  } until (!$@);
       
  return $text; 
}   

sub wikipedia_submit {
  local undef $/; # undefines the separator. Can read one whole file in one scalar.

  my ($text, @message, $file, $method, $wmc, $bailout, $counter, $sleep, $server_text);
  $file=shift; $message=shift; $text=shift;
  if ( @_  >= 1 ){ $bailout=shift; } else{ $bailout=100; }
  if ( @_  >= 1 ){ $sleep=shift; }   else{ $sleep=2; }
  $counter=1;
  
  do {
    eval {
      if ($counter == 1){ print "Submitting $file. <br>\n"; }else{ print "Submitting $file. Attempt: $counter. <br>\n"; }

      # create the init array, and maybe pre-populate it
      my @init = WIKIPEDIA_DEFAULTS_constant;
      
      # instanciate a WWW::Mediawiki::Client obj
      my $wmc = WWW::Mediawiki::Client->new(@init);
      
      $wmc->commit_message($message);
      croak "No commit message specified" unless $wmc->{commit_message};
      croak "No server URL specified." unless $wmc->{site_url};
      print { $wmc->{info_fh} } "";

      
      # check if the text to submit is the same as on server, in that case don't do anything
      $server_text = $wmc->_get_server_page($file); # fetching current version from server.
      $server_text =~ s/\s*$//g;
      $text =~ s/\s*$//g;
      if ($text eq $server_text){
	print "Won't submit $file to the server, as nothing changed<br>\n";
	print "sleep 1<br><br>\n"; sleep 1;
	return 1;
      }

      # Submit. Overwrite whatever happened in between. May fail in case of edit conflict. 
      $wmc->_upload($file, $text);   
      print "Sleep $sleep<br><br>\n\n"; sleep $sleep;

      # fetch back what was just submitted, compare with what was supposed to be submitted. 
      $server_text = $wmc->_get_server_page($file); $server_text =~ s/\s*$//g;
      $text =~ s/\s*$//g;
      
      croak "What is on the server is not what was just submitted!\n" if ($text ne $server_text);
    };

    if ($counter > $bailout && $@){
      print "Error is: $@\n";
      print "Tried $counter times, bailing out\n";
      return 0; # failed
    }
    $counter++;

    print "Error message is: $@\n" if ($@);
  } until (!$@);

  return 1; # succeeded
}

sub submit_file_advanced {
  local undef $/; # undefines the separator. Can read one whole file in one scalar.
  
  my ($text, @message, $file, $method, $wmc, $bailout, $counter, $sleep, $oldtext);
  $file=shift;   $message=shift;   $text=shift;   $oldtext=shift;
  
  $bailout=100; if ( @_  >= 1 ){ $bailout=shift; } 
  $sleep=2; if ( @_  >= 1 ){ $sleep=shift; } 
  $counter=1;
  
  do {
    eval {
      print "Submitting $file. Attempt: $counter. <br>\n"; 

      # create the init array, and maybe pre-populate it
      my @init = WIKIPEDIA_DEFAULTS_constant;
      # instanciate a WWW::Mediawiki::Client obj
      my $wmc = WWW::Mediawiki::Client->new(@init);
      
      $wmc->commit_message($message);
      croak "No commit message specified" unless $wmc->{commit_message};
      croak "No server URL specified." unless $wmc->{site_url};
      print { $wmc->{info_fh} } "commiting $file\n";

      my $lv = $text;                                                       # new text
      my $sv = $wmc->_get_server_page($file);                               # server text
      my $rv=$oldtext;       #my $rv = $wmc->_get_reference_page($file);    # old text
      chomp ($lv, $sv, $rv);
      if ($sv eq $lv){ 	print "Nothing to submit!\n"; return 1; }

      my $nv = $wmc->_merge($file, $rv, $sv, $lv);
      my $status = $wmc->_get_update_status($rv, $sv, $lv, $nv);
      print { $wmc->{info_fh} } "$status $file\n" if $status;

      if ($wmc->_conflicts_found_in($nv)){
        print "Unresolved conflicts!\n"; 
	croak "$file appears to have unresolved conflicts\n";        
      }else{
	print  $wmc->_upload($file, $nv)  . "that was the reply of upload\n";
      } 
      
      if ($sleep >0) { print "Sleeping for $sleep seconds<br><br>\n"; sleep $sleep; }
    };
    
    if ($counter > $bailout && $@){
      print "Error is $@\n" . "Tried $counter times, bailing out\n";
      return 0; # failed
    }
    $counter++;
    
    print "Error message is $@\n" if ($@);
  } until (!$@);
   
  return 1; # succeeded (well, just because we got here is no guarantee)
}

# this function and the one below are for backwards compatibility with older scripts
sub fetch_file_nosave {
  return &wikipedia_fetch (@_);
}

sub submit_file_nosave {
  return &wikipedia_submit (@_);
}

1;
