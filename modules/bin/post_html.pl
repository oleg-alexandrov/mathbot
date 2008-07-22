use LWP::Simple;
use LWP::UserAgent;
use XML::Simple;

# get html source code in a robust manner
sub post_html {

  my ($editor, $link, $args, $error);

  $editor = shift;
  $link = shift;
  $args = shift;
  
  for ($counter=0 ; $counter <= 100  ; $counter++){

    $res = $editor->{mech}->post($link, $args);

    if ($res->is_success ){

      $text = $res->decoded_content;
      #print "<!-- Sucess! -->\n";
      last;
      
    }else{
      
      print "Post to $link failed in attempt $counter!\n";
      $error=1;
      
    }

    if ($counter > 0){
      print "Sleeping for 10 seconds\n";
      sleep 10;
    }
    
  }

  if (defined $error && $error == 1){
    print "Failed to post $link! Exiting...\n";
    exit(0);
  }
  
  return ($text, $error);
}

1;
